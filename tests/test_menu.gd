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


func test_multilang_extracted_files_and_en_zh_zh_tw_ja_translations() -> void:
	var prev_lang: String = Loc.language
	var en_script := ResourceLoader.load("res://src/multiLang/lang_en.gd", "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var zh_script := ResourceLoader.load("res://src/multiLang/lang_zh.gd", "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var zh_tw_script := ResourceLoader.load("res://src/multiLang/lang_zh_tw.gd", "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var ja_script := ResourceLoader.load("res://src/multiLang/lang_ja.gd", "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	assert_true(en_script != null, "res://src/multiLang/lang_en.gd exists")
	assert_true(zh_script != null, "res://src/multiLang/lang_zh.gd exists")
	assert_true(zh_tw_script != null, "res://src/multiLang/lang_zh_tw.gd exists")
	assert_true(ja_script != null, "res://src/multiLang/lang_ja.gd exists")

	if en_script != null and zh_script != null and zh_tw_script != null and ja_script != null:
		var en_dict: Dictionary = en_script.get("TRANSLATIONS")
		var zh_dict: Dictionary = zh_script.get("TRANSLATIONS")
		var zh_tw_dict: Dictionary = zh_tw_script.get("TRANSLATIONS")
		var ja_dict: Dictionary = ja_script.get("TRANSLATIONS")
		assert_true(not en_dict.is_empty(), "English translation table is non-empty")
		var missing_zh := 0
		var missing_zh_tw := 0
		var missing_ja := 0
		for k in en_dict.keys():
			if not zh_dict.has(k) or str(zh_dict[k]).is_empty():
				missing_zh += 1
			if not zh_tw_dict.has(k) or str(zh_tw_dict[k]).is_empty():
				missing_zh_tw += 1
			if not ja_dict.has(k) or str(ja_dict[k]).is_empty():
				missing_ja += 1
		assert_eq(missing_zh, 0, "All English keys are present in Simplified Chinese (lang_zh.gd)")
		assert_eq(missing_zh_tw, 0, "All English keys are present in Traditional Chinese (lang_zh_tw.gd)")
		assert_eq(missing_ja, 0, "All English keys are present in Japanese (lang_ja.gd)")

	Loc.language = "en"
	assert_eq(Loc.t("uib_class_guard"), "Guard", "EN Guard label")
	assert_eq(Loc.t("menu_multiplayer"), "Multiplayer", "EN Multiplayer label")

	Loc.language = "zh"
	assert_eq(Loc.t("uib_class_guard"), "卫兵", "ZH Simplified Chinese Guard label")
	assert_eq(Loc.t("menu_multiplayer"), "多人对战", "ZH Simplified Chinese Multiplayer label")

	Loc.language = "zh_tw"
	assert_eq(Loc.t("uib_class_guard"), "衛兵", "ZH_TW Traditional Chinese Guard label")
	assert_eq(Loc.t("menu_multiplayer"), "多人對戰", "ZH_TW Traditional Chinese Multiplayer label")

	Loc.language = "ja"
	assert_true(Loc.t("uib_class_guard") != "Guard" and not Loc.t("uib_class_guard").is_empty(), "JA Japanese Guard label is localized")
	assert_true(Loc.t("menu_multiplayer") != "Multiplayer" and not Loc.t("menu_multiplayer").is_empty(), "JA Japanese Multiplayer label is localized")

	Loc.language = prev_lang


func test_language_dropdown_button_changes_language_and_updates_menu_labels() -> void:
	var prev_lang: String = Loc.language
	Loc.language = "en"
	_mount_and_release(MENU_SCENE_PATH, func(menu):
		assert_true(menu.language_button != null and menu.language_button is OptionButton,
			"Main Menu has a language dropdown OptionButton")
		if menu.language_button == null:
			return
		var opt: OptionButton = menu.language_button
		assert_eq(opt.item_count, 4, "Language dropdown offers 4 language options (en, zh, zh_tw, ja)")
		assert_eq(opt.selected, 0, "Language dropdown starts with English (index 0) selected")

		# Select Simplified Chinese (index 1 -> "zh")
		opt.select(1)
		opt.item_selected.emit(1)
		assert_eq(Loc.language, "zh", "Selecting index 1 switches Loc.language to 'zh'")
		assert_eq(menu.play_button.text, Loc.t("menu_play"), "Play button updates to Simplified Chinese")
		assert_eq(menu.multiplayer_button.text, "多人对战", "Multiplayer button updates to Simplified Chinese")

		# Select Traditional Chinese (index 2 -> "zh_tw")
		opt.select(2)
		opt.item_selected.emit(2)
		assert_eq(Loc.language, "zh_tw", "Selecting index 2 switches Loc.language to 'zh_tw'")
		assert_eq(menu.multiplayer_button.text, "多人對戰", "Multiplayer button updates to Traditional Chinese")

		# Select Japanese (index 3 -> "ja")
		opt.select(3)
		opt.item_selected.emit(3)
		assert_eq(Loc.language, "ja", "Selecting index 3 switches Loc.language to 'ja'")
		assert_eq(menu.multiplayer_button.text, "マルチプレイ", "Multiplayer button updates to Japanese")

		# Select English (index 0 -> "en")
		opt.select(0)
		opt.item_selected.emit(0)
		assert_eq(Loc.language, "en", "Selecting index 0 switches Loc.language back to 'en'")
		assert_eq(menu.multiplayer_button.text, "Multiplayer", "Multiplayer button updates back to English")
	)
	Loc.language = prev_lang
