class_name Menu
extends Control

## The game's first page: title placeholder plus Play / Multiplayer buttons.
## Button labels come from the multiLang holder. The pending-Notification
## autoload is consumed once on entry.

@export var play_target: PackedScene = preload("res://src/menu/single_player_scene.tscn")
@export var multiplayer_target: PackedScene = preload("res://src/multiplayer_scene.tscn")

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var multiplayer_button: Button = $Center/VBox/MultiplayerButton

## Last target picked by a button press — observable seam for tests.
var chosen_target: PackedScene = null
## The pending-Notification popup, when one was pending on entry.
var notification_dialog: AcceptDialog = null


func _ready() -> void:
	_update_text()
	Loc.language_changed.connect(_update_text)
	_show_pending_notification()


func _update_text() -> void:
	play_button.text = Loc.t("menu_play")
	multiplayer_button.text = Loc.t("menu_multiplayer")


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
