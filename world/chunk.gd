class_name Chunk
extends RefCounted
## A column of 16 x 128 x 16 blocks. Block 0 is air. Index = x + z*16 + y*256.

const SIZE: int = 16
const HEIGHT: int = 128
const VOLUME: int = SIZE * SIZE * HEIGHT

var pos: Vector2i
var _blocks: PackedByteArray = PackedByteArray()


func _init(p_pos: Vector2i) -> void:
	pos = p_pos
	_blocks.resize(VOLUME)


static func index_of(x: int, y: int, z: int) -> int:
	return x + z * SIZE + y * SIZE * SIZE


static func in_bounds(p: Vector3i) -> bool:
	return p.x >= 0 and p.x < SIZE and p.y >= 0 and p.y < HEIGHT and p.z >= 0 and p.z < SIZE


func get_block(p: Vector3i) -> int:
	if not in_bounds(p):
		return 0
	return _blocks[index_of(p.x, p.y, p.z)]


func set_block(p: Vector3i, id: int) -> void:
	if not in_bounds(p):
		return
	_blocks[index_of(p.x, p.y, p.z)] = clampi(id, 0, 255)


## Read-only view of the raw block bytes. Callers must duplicate before keeping it.
func raw_blocks() -> PackedByteArray:
	return _blocks
