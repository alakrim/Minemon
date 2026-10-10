extends GutTest
## Streamer tests in a headless scene: loaded columns, collision radius and flush.


func test_view_radius_one_loads_nine_columns_with_collision() -> void:
	var streamer := WorldStreamer.new()
	streamer.seed = 1
	streamer.view_radius = 1
	add_child_autofree(streamer)
	streamer.set_focus(Vector3.ZERO)
	streamer.flush()
	assert_eq(streamer.loaded_count(), 9)
	assert_true(streamer.has_collision_at(Vector3.ZERO))


func test_collision_only_within_collision_radius() -> void:
	var streamer := WorldStreamer.new()
	streamer.seed = 1
	streamer.view_radius = 2
	streamer.collision_radius = 1
	add_child_autofree(streamer)
	streamer.set_focus(Vector3.ZERO)
	streamer.flush()
	assert_eq(streamer.loaded_count(), 25)
	assert_true(
		streamer.has_collision_at(Vector3(8.0, 0.0, 8.0)), "column (0,0) must have collision"
	)
	assert_false(
		streamer.has_collision_at(Vector3(40.0, 0.0, 0.0)),
		"column (2,0) is outside collision_radius 1"
	)
