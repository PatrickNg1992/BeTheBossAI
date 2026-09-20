class_name MultiplayerManager
extends Node

## Multiplayer Scene manager. The scene itself is invisible; the manager
## swaps the sub-scenes (Role Selector, Waiting Room, later the Battlefield)
## inside the Container, exactly one visible at a time, and owns all
## connection logic: role state, connect/disconnect, Waiting Room state
## replication (Host→Peers), Start gating, and Notifications.
##
## The manager talks only to the MpTransport seam; tests inject a
## FakeTransport. The Connection Mode selects the real implementation.

enum ConnectionMode { DEV }

## Menu path kept as a String and loaded at navigation time: preloading it
## here would create a preload cycle (menu.gd preloads the Multiplayer
## Scene) and resolve to a pathless PackedScene.
const MENU_SCENE_PATH := "res://src/menu/menu.tscn"
const DEFAULT_PORT := 8910

## In-room roles (Player A / Player B / Spectator). The Host is peer id 1.
const ROLE_A := "a"
const ROLE_B := "b"
const ROLE_SPECTATOR := "spectator"
const HOST_ID := 1

@onready var role_selector: RoleSelector = $Container/RoleSelector
@onready var waiting_room: WaitingRoom = $Container/WaitingRoom
@onready var _container: Node = $Container

## How Peers connect. v1: Dev mode only (direct IP + port); Steam is
## undecided and slots into _create_transport().
var connection_mode := ConnectionMode.DEV
## The transport in use. Null until hosting is confirmed / a join starts.
## Injected by tests; otherwise created from the Connection Mode.
var transport: MpTransport = null:
	set = _set_transport
var is_host := false
## Last navigation target picked by a button press — observable seam for
## tests (mirrors menu.gd's chosen_target pattern).
var chosen_target: PackedScene = null

## Room state (Host-authoritative; Peers hold the mirrored copy).
var peers: Dictionary = {}  # int peer_id -> {"name": String, "role": String}
var host_name := ""
var capacity := 2
var room_port := DEFAULT_PORT
var room_open := false


func _ready() -> void:
	role_selector.manager = self
	waiting_room.manager = self


# ----- Role Selector flow -----

func choose_host() -> void:
	is_host = true
	_show_sub_scene(waiting_room)


func choose_join() -> void:
	role_selector.show_join_form()


func back_to_menu() -> void:
	_go_to_menu()


## Join form submission: validates the mandatory Player Name, then connects
## through the transport with an inline "Connecting…" state.
func submit_join(player_name: String, ip: String, port_text: String) -> void:
	var trimmed := player_name.strip_edges()
	if trimmed.is_empty():
		role_selector.set_status("join_name_required")
		return
	is_host = false
	_ensure_transport()
	var port := int(port_text) if port_text.is_valid_int() else DEFAULT_PORT
	role_selector.set_status("join_connecting")
	role_selector.join_form_button.disabled = true
	transport.join(ip, port, trimmed)


# ----- transport wiring -----

func _set_transport(value: MpTransport) -> void:
	transport = value
	if transport == null:
		return
	transport.peer_joined.connect(_on_peer_joined)
	transport.peer_dropped.connect(_on_peer_dropped)
	transport.join_succeeded.connect(_on_join_succeeded)
	transport.join_failed.connect(_on_join_failed)
	transport.host_lost.connect(_on_host_lost)
	transport.room_closed.connect(_on_room_closed)
	transport.message_received.connect(_on_message_received)


func _ensure_transport() -> void:
	if transport == null:
		transport = _create_transport()


## Constructs the transport for the current Connection Mode. The Dev ENet
## transport lands in ticket 07; tests always inject FakeTransport instead.
func _create_transport() -> MpTransport:
	match connection_mode:
		_:
			return DevTransport.new()


# ----- transport event handlers -----

func _on_peer_joined(_peer_id: int, _peer_name: String) -> void:
	pass  # Ticket 03: seat assignment + state broadcast.


func _on_peer_dropped(_peer_id: int) -> void:
	pass  # Ticket 03.


func _on_join_succeeded() -> void:
	# Stay in the Connecting state: the Waiting Room is entered when the
	# Host's first room-state broadcast arrives (a rejected Peer never
	# leaves the Role Selector).
	pass


func _on_join_failed() -> void:
	role_selector.set_status("join_failed")
	role_selector.join_form_button.disabled = false


func _on_host_lost() -> void:
	pass  # Ticket 03: Menu + "host offline" Notification.


func _on_room_closed() -> void:
	pass  # Ticket 03: Menu + "host closed the room" Notification.


func _on_message_received(_sender_id: int, message: Dictionary) -> void:
	match message.get("type", ""):
		"room_state":
			_apply_room_state(message)


# ----- room state -----

## Peer-side: adopt the Host's room state and mirror it read-only.
func _apply_room_state(message: Dictionary) -> void:
	host_name = message.get("host_name", "")
	capacity = message.get("capacity", capacity)
	room_port = message.get("port", room_port)
	room_open = true
	peers.clear()
	for id_key in message.get("peers", {}):
		peers[int(id_key)] = message["peers"][id_key]
	_show_sub_scene(waiting_room)
	_render_room()


func _peer_in_role(role: String) -> int:
	for peer_id in peers:
		if peers[peer_id].get("role") == role:
			return peer_id
	return 0


func _render_room() -> void:
	var seat_a := _peer_in_role(ROLE_A)
	var seat_b := _peer_in_role(ROLE_B)
	waiting_room.host_name_edit.text = host_name
	waiting_room.capacity_spin.value = capacity
	waiting_room.port_edit.text = str(room_port)
	waiting_room.seat_a_name.text = peers[seat_a]["name"] if seat_a != 0 else Loc.t("wr_seat_empty")
	waiting_room.seat_b_name.text = peers[seat_b]["name"] if seat_b != 0 else Loc.t("wr_seat_empty")
	waiting_room.spectator_list.clear()
	for peer_id in peers:
		if peers[peer_id].get("role") == ROLE_SPECTATOR:
			waiting_room.spectator_list.add_item(peers[peer_id]["name"])
	# Host sees Start Game / Close Room; non-Host Peers see Leave.
	waiting_room.start_game_button.visible = is_host
	waiting_room.close_room_button.visible = is_host
	waiting_room.leave_button.visible = not is_host
	# Start is enabled exactly while both Players' Seats are taken.
	waiting_room.start_game_button.disabled = seat_a == 0 or seat_b == 0


# ----- internals -----

## Swaps sub-scenes inside the container, exactly one visible at a time.
func _show_sub_scene(sub: Node) -> void:
	for child in _container.get_children():
		if child is CanvasItem or child is Node3D:
			child.set("visible", child == sub)


func _go_to_menu() -> void:
	var target: PackedScene = load(MENU_SCENE_PATH)
	chosen_target = target
	get_tree().change_scene_to_packed(target)
