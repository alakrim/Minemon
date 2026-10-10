class_name ChunkSnapshot
extends RefCounted
## Immutable copy of a chunk plus the border slices of its 4 neighbours.
## Built on the main thread and read on worker threads. Neighbour directions:
## north = z-1, south = z+1, east = x+1, west = x-1. A null neighbour counts as air.

const _SLICE_SIZE: int = Chunk.SIZE * Chunk.HEIGHT

var _blocks: PackedByteArray
var _north: PackedByteArray
var _south: PackedByteArray
var _east: PackedByteArray
var _west: PackedByteArray


func _init(c: Chunk, north: Chunk, south: Chunk, east: Chunk, west: Chunk) -> void:
	_blocks = c.raw_blocks().duplicate()
	_north = _slice_north(north)
	_south = _slice_south(south)
	_east = _slice_east(east)
	_west = _slice_west(west)


## Returns the block at p. Valid for x and z in -1..16 (the border ring).
func get_block(p: Vector3i) -> int:
	if p.y < 0 or p.y >= Chunk.HEIGHT:
		return 0
	var inside_x: bool = p.x >= 0 and p.x < Chunk.SIZE
	var inside_z: bool = p.z >= 0 and p.z < Chunk.SIZE
	if inside_x and inside_z:
		return _blocks[Chunk.index_of(p.x, p.y, p.z)]
	return _border_block(p, inside_x, inside_z)


func _border_block(p: Vector3i, inside_x: bool, inside_z: bool) -> int:
	if inside_x and p.z == -1:
		return _north[p.x + p.y * Chunk.SIZE]
	if inside_x and p.z == Chunk.SIZE:
		return _south[p.x + p.y * Chunk.SIZE]
	if inside_z and p.x == Chunk.SIZE:
		return _east[p.z + p.y * Chunk.SIZE]
	if inside_z and p.x == -1:
		return _west[p.z + p.y * Chunk.SIZE]
	return 0


static func _slice_north(n: Chunk) -> PackedByteArray:
	# The north neighbour's z = 15 row, indexed x + y*16.
	return _slice(n, func(a: int, y: int) -> Vector3i: return Vector3i(a, y, Chunk.SIZE - 1))


static func _slice_south(s: Chunk) -> PackedByteArray:
	# The south neighbour's z = 0 row, indexed x + y*16.
	return _slice(s, func(a: int, y: int) -> Vector3i: return Vector3i(a, y, 0))


static func _slice_east(e: Chunk) -> PackedByteArray:
	# The east neighbour's x = 0 column, indexed z + y*16.
	return _slice(e, func(a: int, y: int) -> Vector3i: return Vector3i(0, y, a))


static func _slice_west(w: Chunk) -> PackedByteArray:
	# The west neighbour's x = 15 column, indexed z + y*16.
	return _slice(w, func(a: int, y: int) -> Vector3i: return Vector3i(Chunk.SIZE - 1, y, a))


static func _slice(c: Chunk, to_block: Callable) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(_SLICE_SIZE)
	if c == null:
		return out
	for y: int in Chunk.HEIGHT:
		for a: int in Chunk.SIZE:
			var p: Vector3i = to_block.call(a, y)
			out[a + y * Chunk.SIZE] = c.get_block(p)
	return out
