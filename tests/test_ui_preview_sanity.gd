extends McpTestSuite

## Throwaway scene-load sanity check (delete after UI review).

func suite_name() -> String:
	return "ui_preview_sanity"


func _tree() -> SceneTree:
	return Engine.get_main_loop()


func test_scenes_instantiate() -> void:
	for path in [
		"res://src/multiplayer_scene.tscn",
		"res://src/multiplayer/role_selector.tscn",
		"res://src/multiplayer/waiting_room.tscn",
	]:
		var packed := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		assert_true(packed != null, "%s failed to load" % path)
		if packed == null:
			continue
		var node := packed.instantiate()
		_tree().root.add_child(node)
		_tree().root.remove_child(node)
		node.queue_free()
