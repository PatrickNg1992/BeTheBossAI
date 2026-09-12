extends McpTestSuite

## Tests for the Menu scene: main-scene wiring, localized buttons and
## navigation targets, plus the pending-Notification autoload contract.

const MENU_SCENE_PATH := "res://src/menu/menu.tscn"
const SINGLE_PLAYER_SCENE_PATH := "res://src/menu/single_player_scene.tscn"
const MULTIPLAYER_SCENE_PATH := "res://src/multiplayer_scene.tscn"


func suite_name() -> String:
	return "menu"


func _tree() -> SceneTree:
	return Engine.get_main_loop()


func _instantiate(scene_path: String) -> Node:
	var packed := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()


func _mount_and_release(scene_path: String, body: Callable) -> void:
	var node := _instantiate(scene_path)
	if node == null:
		assert_true(false, "%s failed to load" % scene_path)
		return
	_tree().root.add_child(node)
	body.call(node)
	_tree().root.remove_child(node)
	node.queue_free()


func test_main_scene_is_menu() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_scene, MENU_SCENE_PATH, "Main scene should be the Menu")


func test_play_button_label_is_localized() -> void:
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		assert_eq(menu.play_button.text, Loc.t("menu_play"), "Play label is not localized")
	)


func test_multiplayer_label_is_localized() -> void:
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		assert_eq(menu.multiplayer_button.text, Loc.t("menu_multiplayer"), "Multiplayer label is not localized")
	)


func test_multiplayer_button_navigates_to_stub() -> void:
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		menu.multiplayer_button.emit_signal("pressed")
		assert_true(menu.chosen_target != null, "Multiplayer press must pick a target")
		assert_eq(menu.chosen_target.resource_path, MULTIPLAYER_SCENE_PATH,
			"Multiplayer must navigate to the multiplayer scene stub")
	)


func test_play_button_targets_single_player_scene() -> void:
	var menu := _instantiate(MENU_SCENE_PATH)
	if menu == null:
		assert_true(false, "Menu scene failed to load")
		return
	assert_eq(menu.play_target.resource_path, SINGLE_PLAYER_SCENE_PATH,
		"Play must target the Single-Player Scene")
	menu.queue_free()


func test_pending_notification_shows_and_clears() -> void:
	PendingNotification.set_pending("kicked")
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		assert_true(menu.notification_dialog != null, "Pending notification should open a popup")
		if menu.notification_dialog != null:
			assert_eq(menu.notification_dialog.dialog_text, Loc.t("kicked"),
				"Popup shows the pending localization key")
	)


func test_pending_notification_is_cleared_after_showing() -> void:
	PendingNotification.set_pending("kicked")
	_mount_and_release(MENU_SCENE_PATH, func(_menu):
		assert_eq(PendingNotification.take_pending(), "", "Pending slot must be cleared after showing")
	)


func test_empty_pending_slot_shows_no_popup() -> void:
	PendingNotification.set_pending("")
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		assert_true(menu.notification_dialog == null, "No popup expected when nothing pending")
	)
