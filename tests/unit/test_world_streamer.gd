extends GutTest
## Streamer tests in a headless scene: loaded columns, collision radius, flush, shutdown and stale meshes.


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


func test_freeing_streamer_right_after_set_focus_is_safe() -> void:
	var streamer := WorldStreamer.new()
	streamer.seed = 1
	streamer.view_radius = 2
	add_child(streamer)
	streamer.set_focus(Vector3.ZERO)
	streamer.free()
	assert_no_new_orphans()


func test_queue_free_with_tasks_running_is_safe_across_frames() -> void:
	var streamer := WorldStreamer.new()
	streamer.seed = 1
	streamer.view_radius = 2
	add_child(streamer)
	streamer.set_focus(Vector3.ZERO)
	streamer.queue_free()
	for i: int in 5:
		await get_tree().process_frame
	assert_false(is_instance_valid(streamer), "streamer must be deleted")
	assert_no_new_orphans()


func test_stale_mesh_is_dropped_after_unload_and_reload() -> void:
	var streamer := WorldStreamer.new()
	streamer.seed = 1
	streamer.view_radius = 1
	add_child_autofree(streamer)
	streamer.set_focus(Vector3.ZERO)
	streamer.flush()
	var stale: int = streamer._serials[Vector2i.ZERO] - 1
	streamer._ready_meshes.append(
		{"pos": Vector2i.ZERO, "serial": stale, "data": ChunkMeshData.new()}
	)
	streamer.set_focus(Vector3(1000.0, 0.0, 0.0))
	var pending_for_origin: int = 0
	for item: Dictionary in streamer._ready_meshes:
		if item["pos"] == Vector2i.ZERO:
			pending_for_origin += 1
	assert_eq(pending_for_origin, 0, "unload must purge pending meshes of the unloaded column")
	streamer.set_focus(Vector3.ZERO)
	streamer.flush()
	var mesh: Mesh = streamer._nodes[Vector2i.ZERO].mesh
	assert_gt(mesh.get_surface_count(), 0, "the empty stale mesh must not replace the real one")
