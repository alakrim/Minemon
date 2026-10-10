class_name ChunkMesher
extends RefCounted
## Turns a ChunkSnapshot into packed mesh arrays. Pure data: no scene-tree or Resource access,
## so it is safe on worker threads.

## Face order: +X, -X, +Y, -Y, +Z, -Z.
const FACE_DIRS: Array[Vector3i] = [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]
## Four corners per face, counter-clockwise seen from outside the block.
const FACE_CORNERS: Array[Vector3] = [
	Vector3(1, 0, 0),
	Vector3(1, 1, 0),
	Vector3(1, 1, 1),
	Vector3(1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(0, 1, 1),
	Vector3(0, 1, 0),
	Vector3(0, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, 1, 1),
	Vector3(1, 1, 1),
	Vector3(1, 1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
	Vector3(1, 0, 1),
	Vector3(1, 0, 1),
	Vector3(1, 1, 1),
	Vector3(0, 1, 1),
	Vector3(0, 0, 1),
	Vector3(0, 0, 0),
	Vector3(0, 1, 0),
	Vector3(1, 1, 0),
	Vector3(1, 0, 0),
]
## Face shade: top 1.0, sides 0.8, bottom 0.6.
const FACE_SHADE: Array[float] = [0.8, 0.8, 1.0, 0.6, 0.8, 0.8]


static func build(snap: ChunkSnapshot, blocks: BlockRegistry) -> ChunkMeshData:
	var out := ChunkMeshData.new()
	for y: int in Chunk.HEIGHT:
		for z: int in Chunk.SIZE:
			for x: int in Chunk.SIZE:
				_mesh_block(out, snap, blocks, Vector3i(x, y, z))
	return out


static func _mesh_block(
	out: ChunkMeshData, snap: ChunkSnapshot, blocks: BlockRegistry, p: Vector3i
) -> void:
	var id: int = snap.get_block(p)
	if id == 0:
		return
	for face: int in 6:
		var neighbour: int = snap.get_block(p + FACE_DIRS[face])
		if neighbour == id or not blocks.is_transparent(neighbour):
			continue
		_emit_face(out, p, face, blocks.color(id))


static func _emit_face(out: ChunkMeshData, p: Vector3i, face: int, block_color: Color) -> void:
	var shade: float = FACE_SHADE[face]
	var shaded := Color(block_color.r * shade, block_color.g * shade, block_color.b * shade, 1.0)
	var normal := Vector3(FACE_DIRS[face])
	var origin := Vector3(p)
	var base: int = out.vertices.size()
	for corner: int in 4:
		out.vertices.append(origin + FACE_CORNERS[face * 4 + corner])
		out.normals.append(normal)
		out.colors.append(shaded)
	out.indices.append(base)
	out.indices.append(base + 1)
	out.indices.append(base + 2)
	out.indices.append(base)
	out.indices.append(base + 2)
	out.indices.append(base + 3)
	out.face_count += 1
