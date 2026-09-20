class_name WaitingRoom
extends Control

## Waiting Room sub-scene (layout per .docmanual/multiplayer/waitingRoomUI.md):
## Room Configuration at the top (Host-editable until the room opens), the two
## clickable Players' Seats in the middle (Player A left, Player B right), the
## Spectator list on the right (up to 6 names), and Start Game / Close Room
## (Host) or Leave (non-Host) at the bottom. All display text comes from the
## multiLang holder.
##
## A dumb view: forwards input to the manager and renders what it is told.

var manager: MultiplayerManager = null

@onready var config_title: Label = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigTitle
@onready var host_name_label: Label = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/HostNameLabel
@onready var host_name_edit: LineEdit = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/HostNameEdit
@onready var capacity_label: Label = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/CapacityLabel
@onready var capacity_spin: SpinBox = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/CapacitySpin
@onready var port_label: Label = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/PortLabel
@onready var port_edit: LineEdit = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/PortEdit
@onready var confirm_button: Button = $Margin/Root/RoomConfig/ConfigMargin/ConfigBox/ConfigRow/ConfirmButton
@onready var seat_a_button: Button = $Margin/Root/Middle/Seats/SeatA
@onready var seat_a_title: Label = $Margin/Root/Middle/Seats/SeatA/SeatABox/SeatATitle
@onready var seat_a_name: Label = $Margin/Root/Middle/Seats/SeatA/SeatABox/SeatAName
@onready var seat_b_button: Button = $Margin/Root/Middle/Seats/SeatB
@onready var seat_b_title: Label = $Margin/Root/Middle/Seats/SeatB/SeatBBox/SeatBTitle
@onready var seat_b_name: Label = $Margin/Root/Middle/Seats/SeatB/SeatBBox/SeatBName
@onready var spec_title: Label = $Margin/Root/Middle/SpectatorPanel/SpecMargin/SpecBox/SpecTitle
@onready var spectator_list: ItemList = $Margin/Root/Middle/SpectatorPanel/SpecMargin/SpecBox/SpectatorList
@onready var start_game_button: Button = $Margin/Root/BottomBar/StartGameButton
@onready var close_room_button: Button = $Margin/Root/BottomBar/CloseRoomButton
@onready var leave_button: Button = $Margin/Root/BottomBar/LeaveButton


func _ready() -> void:
	_update_text()
	Loc.language_changed.connect(_update_text)


func _update_text() -> void:
	config_title.text = Loc.t("wr_config")
	host_name_label.text = Loc.t("wr_host_name")
	capacity_label.text = Loc.t("wr_capacity")
	port_label.text = Loc.t("wr_port")
	confirm_button.text = Loc.t("wr_confirm")
	seat_a_title.text = Loc.t("wr_seat_a")
	seat_b_title.text = Loc.t("wr_seat_b")
	spec_title.text = Loc.t("wr_spectators")
	start_game_button.text = Loc.t("wr_start")
	close_room_button.text = Loc.t("wr_close")
	leave_button.text = Loc.t("wr_leave")
