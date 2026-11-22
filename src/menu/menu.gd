class_name Menu
extends Control

## The game's first page: title placeholder plus Play / Multiplayer buttons.
## Button labels come from the multiLang holder. The pending-Notification
## autoload is consumed once on entry.

const LANGUAGE_CODES: Array[String] = ["en", "zh", "zh_tw", "ja"]
const LANGUAGE_LABEL_KEYS: Array[String] = [
	"lang_name_en",
	"lang_name_zh",
	"lang_name_zh_tw",
	"lang_name_ja",
]

@export var play_target: PackedScene = preload("res://src/menu/single_player_scene.tscn")
@export var multiplayer_target: PackedScene = preload("res://src/multiplayer_scene.tscn")

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var multiplayer_button: Button = $Center/VBox/MultiplayerButton
@onready var language_button: OptionButton = $Center/VBox/LanguageButton

## Last target picked by a button press — observable seam for tests.
var chosen_target: PackedScene = null
## The pending-Notification popup, when one was pending on entry.
var notification_dialog: AcceptDialog = null


func _ready() -> void:
	_populate_language_options()
	_update_text()
	Loc.language_changed.connect(_update_text)
	_show_pending_notification()


func _populate_language_options() -> void:
	if language_button == null:
		return
	language_button.clear()
	for i in range(LANGUAGE_CODES.size()):
		language_button.add_item(Loc.t(LANGUAGE_LABEL_KEYS[i]), i)
	_sync_selected_language()


func _sync_selected_language() -> void:
	if language_button == null:
		return
	var cur := Loc.language.to_lower()
	var idx := LANGUAGE_CODES.find(cur)
	if idx < 0:
		match cur:
			"zh_cn", "zh_hans":
				idx = 1
			"zh_hk", "zh_hant", "tc":
				idx = 2
			"jp":
				idx = 3
			_:
				idx = 0
	if language_button.selected != idx:
		language_button.select(idx)


func _update_text() -> void:
	play_button.text = Loc.t("menu_play")
	multiplayer_button.text = Loc.t("menu_multiplayer")
	if language_button != null and language_button.item_count == LANGUAGE_LABEL_KEYS.size():
		for i in range(LANGUAGE_LABEL_KEYS.size()):
			language_button.set_item_text(i, Loc.t(LANGUAGE_LABEL_KEYS[i]))
		_sync_selected_language()


func _show_pending_notification() -> void:
	var key: String = PendingNotification.take_pending()
	if key.is_empty():
		return
	notification_dialog = AcceptDialog.new()
	notification_dialog.dialog_text = Loc.t(key)
	add_child(notification_dialog)
	notification_dialog.popup_centered()


func _on_play_button_pressed() -> void:
	chosen_target = play_target
	get_tree().change_scene_to_packed(play_target)


func _on_multiplayer_button_pressed() -> void:
	chosen_target = multiplayer_target
	get_tree().change_scene_to_packed(multiplayer_target)


func _on_language_button_item_selected(index: int) -> void:
	if index >= 0 and index < LANGUAGE_CODES.size():
		Loc.language = LANGUAGE_CODES[index]
