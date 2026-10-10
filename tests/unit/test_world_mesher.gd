extends GutTest
## Unit tests for ChunkMesher: face counts, water sharing, border culling and snapshot copies.

const STONE: int = 3
const WATER: int = 5


func _registry() -> BlockRegistry:
	var reg := BlockRegistry.new()
	var errors: Array[String] = reg.load_from("res://data/blocks.json")
	assert_eq(errors.size(), 0, "blocks.json must load without errors")
	return reg


func _chunk_with(blocks: Array) -> Chunk:
	var c := Chunk.new(Vector2i.ZERO)
	for entry: Array in blocks:
		c.set_block(entry[0] as Vector3i, entry[1] as int)
	return c


func _mesh_alone(c: Chunk) -> ChunkMeshData:
	var snap := ChunkSnapshot.new(c, null, null, null, null)
	return ChunkMesher.build(snap, _registry())


func test_single_block_has_six_faces() -> void:
	var data: ChunkMeshData = _mesh_alone(_chunk_with([[Vector3i(5, 5, 5), STONE]]))
	assert_eq(data.face_count, 6)
	assert_eq(data.indices.size(), 36)
	assert_eq(data.vertices.size(), 24)


func test_two_adjacent_blocks_have_ten_faces() -> void:
	var data: ChunkMeshData = _mesh_alone(
		_chunk_with(
			[
				[Vector3i(5, 5, 5), STONE],
				[Vector3i(6, 5, 5), STONE],
			]
		)
	)
	assert_eq(data.face_count, 10)


func test_water_next_to_water_emits_no_shared_face() -> void:
	var data: ChunkMeshData = _mesh_alone(
		_chunk_with(
			[
				[Vector3i(5, 5, 5), WATER],
				[Vector3i(5, 5, 6), WATER],
			]
		)
	)
	# Each water block shows 5 faces; the face between them is not emitted.
	assert_eq(data.face_count, 10)


func test_snapshot_culls_faces_against_solid_neighbours() -> void:
	var centre := _chunk_with([[Vector3i(15, 5, 5), STONE]])
	var east := _chunk_with([[Vector3i(0, 5, 5), STONE]])
	var data: ChunkMeshData = ChunkMesher.build(
		ChunkSnapshot.new(centre, null, null, east, null), _registry()
	)
	assert_eq(data.face_count, 5, "the east face must be culled by the solid east neighbour")


func test_each_border_direction_culls_its_face() -> void:
	var reg := _registry()
	var centre := _chunk_with([[Vector3i(5, 5, 0), STONE]])
	var north := _chunk_with([[Vector3i(5, 5, 15), STONE]])
	var data: ChunkMeshData = ChunkMesher.build(
		ChunkSnapshot.new(centre, north, null, null, null), reg
	)
	assert_eq(data.face_count, 5, "north border face must be culled")

	centre = _chunk_with([[Vector3i(5, 5, 15), STONE]])
	var south := _chunk_with([[Vector3i(5, 5, 0), STONE]])
	data = ChunkMesher.build(ChunkSnapshot.new(centre, null, south, null, null), reg)
	assert_eq(data.face_count, 5, "south border face must be culled")

	centre = _chunk_with([[Vector3i(0, 5, 5), STONE]])
	var west := _chunk_with([[Vector3i(15, 5, 5), STONE]])
	data = ChunkMesher.build(ChunkSnapshot.new(centre, null, null, null, west), reg)
	assert_eq(data.face_count, 5, "west border face must be culled")


func test_snapshot_is_a_copy_of_the_chunk() -> void:
	var c := _chunk_with([[Vector3i(5, 5, 5), STONE]])
	var snap := ChunkSnapshot.new(c, null, null, null, null)
	c.set_block(Vector3i(5, 5, 5), 0)
	assert_eq(
		snap.get_block(Vector3i(5, 5, 5)), STONE, "snapshot must not change when the chunk changes"
	)


func test_block_at_top_of_column_has_six_faces() -> void:
	var data: ChunkMeshData = _mesh_alone(_chunk_with([[Vector3i(5, Chunk.HEIGHT - 1, 5), STONE]]))
	assert_eq(data.face_count, 6)


func _winding_dots(
	verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array
) -> Array[float]:
	var dots: Array[float] = []
	for t: int in range(0, indices.size(), 3):
		var v0: Vector3 = verts[indices[t]]
		var v1: Vector3 = verts[indices[t + 1]]
		var v2: Vector3 = verts[indices[t + 2]]
		var normal: Vector3 = normals[indices[t]]
		dots.append((v1 - v0).cross(v2 - v0).dot(normal))
	return dots


func test_triangles_wind_like_godot_box_mesh() -> void:
	var box: Array = BoxMesh.new().get_mesh_arrays()
	var box_indices: PackedInt32Array = box[Mesh.ARRAY_INDEX]
	assert_gt(box_indices.size(), 0, "BoxMesh must have indices to compare against")
	for dot: float in _winding_dots(box[Mesh.ARRAY_VERTEX], box[Mesh.ARRAY_NORMAL], box_indices):
		assert_lt(dot, 0.0, "BoxMesh reference triangle is not wound opposite to its normal")

	var data: ChunkMeshData = _mesh_alone(_chunk_with([[Vector3i(5, 5, 5), STONE]]))
	var dots: Array[float] = _winding_dots(data.vertices, data.normals, data.indices)
	assert_eq(dots.size(), 12, "one block is 6 faces, 2 triangles each")
	for dot: float in dots:
		assert_lt(dot, 0.0, "mesher triangle is wound the wrong way for Godot front faces")
