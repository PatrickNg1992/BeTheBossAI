extends McpTestSuite

## Tests for the Single-Player Scene: an invisible loader that sets up a
## local LoopbackTransport (is_host = true, local peer 1, Player A = 1,
## Player B = empty) and instantiates the Battlefield as its child, replacing
## OfflineMultiplayerPeer.

const SINGLE_PLAYER_SCENE_PATH := "res://src/menu/single_player_scene.tscn"
const BATTLEFIELD_SCENE_PATH := "res://src/demo_bettlefield.tscn"


func suite_name() -> String:
	return "single-player"


func test_loader_sets_loopback_transport_and_mounts_battlefield() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var packed := ResourceLoader.load(SINGLE_PLAYER_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		assert_true(false, "Single-Player Scene failed to load")
		return
	var loader := packed.instantiate()
	tree.root.add_child(loader)
	assert_true(loader.transport is LoopbackTransport,
		"Loader must create a LoopbackTransport instead of OfflineMultiplayerPeer")
	assert_false(loader.get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer,
		"Loader must not rely on OfflineMultiplayerPeer")
	assert_eq(loader.get_child_count(), 1, "Loader must instantiate the Battlefield as its only child")
	if loader.get_child_count() == 1:
		var battlefield: Node = loader.get_child(0)
		assert_eq(battlefield.scene_file_path, BATTLEFIELD_SCENE_PATH,
			"The child must be the existing battlefield test scene")
		assert_true(battlefield.transport is LoopbackTransport,
			"Battlefield must receive the local LoopbackTransport")
		assert_true(battlefield.is_host,
			"Single-Player Battlefield must run with is_host = true")
		assert_eq(battlefield.local_peer_id, 1,
			"Single-Player Battlefield must have local peer ID 1")
		assert_eq(battlefield.player_a_peer_id, 1,
			"Single-Player Battlefield must assign peer 1 to Player A")
		assert_eq(battlefield.player_b_peer_id, 0,
			"Single-Player Battlefield must leave Player B seat empty (0)")
	tree.root.remove_child(loader)
	loader.queue_free()
