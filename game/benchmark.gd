class_name Benchmark
extends Node
## Benchmark mode: flies a square path around the spawn for a fixed time, records every frame time,
## writes benchmark_<renderer>_<yyyyMMdd_HHmm>.txt (8 "key: value" lines) and quits.
## The file goes next to the executable when that folder is writable, otherwise to user://.

const DEFAULT_SECONDS: float = 60.0
const SECONDS_ARG: String = "--bench-seconds="
const SIDE: float = 160.0
const LOOK_AHEAD: float = 0.005
const LOOK_DROP: float = 8.0
const LOW_FRACTION: float = 0.01
const BYTES_PER_MB: float = 1048576.0

var _player: Player
var _camera: Camera3D
var _streamer: WorldStreamer
var _centre: Vector3
var _duration: float = DEFAULT_SECONDS
var _running: bool = false
var _warmed_up: bool = false
var _elapsed: float = 0.0
var _frame_ms: PackedFloat64Array = PackedFloat64Array()
var _max_static_mb: float = 0.0
var _peak_columns: int = 0


## Starts the run: the player is disabled and the camera flies a square path centred on `centre`
## at height `centre.y`.
func start(player: Player, camera: Camera3D, streamer: WorldStreamer, centre: Vector3) -> void:
	_player = player
	_camera = camera
	_streamer = streamer
	_centre = centre
	_duration = _read_seconds()
	_player.active = false
	_camera.make_current()
	_running = true


func _process(delta: float) -> void:
	if not _running:
		return
	# The first frame after start can carry scene loading time, so it is not timed.
	if _warmed_up:
		_elapsed += delta
		_frame_ms.append(delta * 1000.0)
	_warmed_up = true
	_move_camera()
	_streamer.set_focus(_camera.global_position)
	var static_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / BYTES_PER_MB
	_max_static_mb = maxf(_max_static_mb, static_mb)
	_peak_columns = maxi(_peak_columns, _streamer.loaded_count())
	if _elapsed >= _duration:
		_finish()


func _read_seconds() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SECONDS_ARG):
			var value: float = arg.trim_prefix(SECONDS_ARG).to_float()
			if value > 0.0:
				return value
	return DEFAULT_SECONDS


func _move_camera() -> void:
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var here: Vector3 = _path_point(t)
	var ahead: Vector3 = _path_point(t + LOOK_AHEAD)
	_camera.global_position = here
	_camera.look_at(ahead + Vector3.DOWN * LOOK_DROP)


## Point on the square path at fraction `t` of one lap (t = 1 is back at the start).
func _path_point(t: float) -> Vector3:
	var perimeter: float = SIDE * 4.0
	var s: float = fposmod(t * perimeter, perimeter)
	var edge: int = mini(int(s / SIDE), 3)
	var along: float = (s - float(edge) * SIDE) / SIDE
	var half: float = SIDE * 0.5
	var corners: Array[Vector2] = [
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
	]
	var xz: Vector2 = corners[edge].lerp(corners[(edge + 1) % 4], along)
	return Vector3(_centre.x + xz.x, _centre.y, _centre.z + xz.y)


func _finish() -> void:
	_running = false
	var sorted: PackedFloat64Array = _frame_ms.duplicate()
	sorted.sort()
	var count: int = sorted.size()
	var total_ms: float = 0.0
	for ms: float in sorted:
		total_ms += ms
	var avg_fps: float = _fps(count, total_ms)
	var low1_fps: float = 0.0
	var min_fps: float = 0.0
	if count > 0:
		# The slowest 1% of frames (at least one), as one fps figure.
		var low_count: int = maxi(1, ceili(count * LOW_FRACTION))
		var low_ms: float = 0.0
		for i: int in range(count - low_count, count):
			low_ms += sorted[i]
		low1_fps = _fps(low_count, low_ms)
		min_fps = _fps(1, sorted[count - 1])

	var renderer: String = RenderingServer.get_current_rendering_method()
	var gpu: String = RenderingServer.get_video_adapter_name()
	if gpu.is_empty():
		gpu = "unknown"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("avg_fps: %.1f" % avg_fps)
	lines.append("low1_fps: %.1f" % low1_fps)
	lines.append("min_fps: %.1f" % min_fps)
	lines.append("max_static_mb: %.1f" % _max_static_mb)
	lines.append("peak_columns: %d" % _peak_columns)
	lines.append("renderer: %s" % renderer)
	lines.append("gpu: %s" % gpu)
	lines.append("view_radius: %d" % Settings.view_radius)

	var stamp: Dictionary = Time.get_datetime_dict_from_system()
	var file_name: String = (
		"benchmark_%s_%04d%02d%02d_%02d%02d.txt"
		% [renderer, stamp["year"], stamp["month"], stamp["day"], stamp["hour"], stamp["minute"]]
	)
	var path: String = _write_result(file_name, "\n".join(lines) + "\n")
	print("Benchmark result written to %s" % path)
	get_tree().quit()


## frames divided by milliseconds, as frames per second. Zero when no time was recorded.
func _fps(frames: int, ms: float) -> float:
	if ms <= 0.0:
		return 0.0
	return float(frames) * 1000.0 / ms


## Writes the file beside the executable if possible, else to user://. Returns the path written.
func _write_result(file_name: String, text: String) -> String:
	var beside_exe: String = OS.get_executable_path().get_base_dir().path_join(file_name)
	var path: String = beside_exe
	var file: FileAccess = FileAccess.open(beside_exe, FileAccess.WRITE)
	if file == null:
		path = "user://" + file_name
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Benchmark could not write %s" % file_name)
		return ""
	file.store_string(text)
	file.close()
	return ProjectSettings.globalize_path(path)
