extends McpTestSuite

## Tests for the Single-Player Scene: an invisible loader that sets up an
## OfflineMultiplayerPeer and instantiates the Battlefield as its child.

const SINGLE_PLAYER_SCENE_PATH := "res://src/menu/single_player_scene.tscn"
const BATTLEFIELD_SCENE_PATH := "res://src/demo_bettlefield.tscn"


func suite_name() -> String:
	return "single-player"


func test_loader_sets_offline_peer_and_mounts_battlefield() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var packed := ResourceLoader.load(SINGLE_PLAYER_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		assert_true(false, "Single-Player Scene failed to load")
		return
	var loader := packed.instantiate()
	tree.root.add_child(loader)
	assert_true(loader.get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer,
		"Loader must set up an OfflineMultiplayerPeer")
	assert_eq(loader.get_child_count(), 1, "Loader must instantiate the Battlefield as its only child")
	if loader.get_child_count() == 1:
		var battlefield: Node = loader.get_child(0)
		assert_eq(battlefield.scene_file_path, BATTLEFIELD_SCENE_PATH,
			"The child must be the existing battlefield test scene")
	tree.root.remove_child(loader)
	loader.queue_free()
	tree.get_multiplayer().multiplayer_peer = null
