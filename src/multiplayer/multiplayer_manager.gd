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
## Loaded lazily at Start Game (no preload weight, no preload cycle).
const BATTLEFIELD_SCENE_PATH := "res://src/demo_bettlefield.tscn"
## The game version string, compared on every connect (Version Check).
## Mismatching Peers are rejected before any seat assignment.
const GAME_VERSION := "0.1.0"

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
## The version this build reports on connect. Instance-level so tests can
## simulate a mismatch; defaults to the GAME_VERSION constant.
var game_version := GAME_VERSION
## The in-place Notification popup (version mismatch, etc.), when shown.
var notification_dialog: AcceptDialog = null
## The live Battlefield instance while a battle is running (null otherwise).
## Loaded into the same container as the other sub-scenes on Start Game;
## the Host's instance is authoritative (ADR-0003).
var battlefield: Node3D = null

## Room state (Host-authoritative; Peers hold the mirrored copy).
var peers: Dictionary = {}  # int peer_id -> {"name": String, "role": String}
var host_name := ""
var capacity := 2
var room_port := DEFAULT_PORT
var room_open := false


## True between submitting the Join form and the connect resolving — the
## Connecting state is modal, and late messages are ignored once it ends.
var _join_pending := false


func _ready() -> void:
	role_selector.manager = self
	waiting_room.manager = self


## Pumps the transport every frame (no-op for in-memory transports).
func _process(_delta: float) -> void:
	if transport != null:
		transport.poll()


# ----- Role Selector flow -----

func choose_host() -> void:
	is_host = true
	peers = {HOST_ID: {"name": "", "role": ROLE_A}}
	_show_sub_scene(waiting_room)
	_render_room()


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
	_join_pending = true
	role_selector.set_status("join_connecting")
	role_selector.set_connecting(true)
	transport.join(ip, port, trimmed, game_version)


# ----- Waiting Room: Room Configuration (Host) -----

## Live update while the Host types their name: the Player A seat label
## follows, and Confirm is gated on a non-empty name.
func host_name_changed(new_text: String) -> void:
	if not is_host or room_open:
		return
	peers[HOST_ID]["name"] = new_text.strip_edges()
	_render_room()


## Confirm locks the Game Config and starts serving so Peers can connect.
func confirm_room_config() -> void:
	if not is_host or room_open:
		return
	var typed := waiting_room.host_name_edit.text.strip_edges()
	if typed.is_empty():
		return
	host_name = typed
	capacity = int(waiting_room.capacity_spin.value)
	room_port = int(waiting_room.port_edit.text) if waiting_room.port_edit.text.is_valid_int() else DEFAULT_PORT
	peers[HOST_ID]["name"] = host_name
	_ensure_transport()
	transport.serve(room_port)
	if not transport.is_serving:
		# serve_failed already popped the Notification; the Game Config
		# stays editable so the Host can fix the port and retry.
		return
	room_open = true
	_render_room()


# ----- Waiting Room: roles, start, leave / close -----

## Any Peer clicks an empty seat to take it. The Host applies directly;
## Peers send a request the Host validates.
func request_take_seat(seat: String) -> void:
	if is_host:
		_apply_take_seat(HOST_ID, seat)
	else:
		transport.send_to_host({"type": "take_seat", "seat": seat})


## A seated player clicks the Spectator list to step down to Spectator.
func request_step_down() -> void:
	if is_host:
		_apply_step_down(HOST_ID)
	else:
		transport.send_to_host({"type": "step_down"})


## Host-side: take an empty seat. Occupied seats are inert — only one
## Player A and one Player B at a time.
func _apply_take_seat(peer_id: int, seat: String) -> void:
	if not peers.has(peer_id):
		return
	if seat != ROLE_A and seat != ROLE_B:
		return
	if peers[peer_id]["role"] == seat or _peer_in_role(seat) != 0:
		return
	peers[peer_id]["role"] = seat
	_broadcast_room_state()
	_render_room()


## Host-side: a seated player steps down to Spectator.
func _apply_step_down(peer_id: int) -> void:
	if not peers.has(peer_id):
		return
	if peers[peer_id]["role"] == ROLE_SPECTATOR:
		return
	peers[peer_id]["role"] = ROLE_SPECTATOR
	_broadcast_room_state()
	_render_room()


## Host-only: Start Game loads the Battlefield into the container on every
## Peer. Enabled exactly while both Players' Seats are taken (the button's
## gating enforces this; the guard double-checks).
func request_start_game() -> void:
	if not is_host or battlefield != null or transport == null:
		return
	if _peer_in_role(ROLE_A) == 0 or _peer_in_role(ROLE_B) == 0:
		return
	transport.broadcast({"type": "game_start"})
	_start_battle()


## Host: Close Room kicks all Peers (they get the host-closed Notification)
## and returns the Host to the Menu — the only clean session end.
func close_room() -> void:
	if not is_host or transport == null:
		return
	transport.close_room()
	_go_to_menu()


## Non-Host Peer: Leave disconnects and returns to the Menu.
func leave_room() -> void:
	if is_host or transport == null:
		return
	transport.leave()
	_go_to_menu()


# ----- battle (Start Game / return) -----

## Every Peer loads the same demo Battlefield into the container; the
## Host's instance is authoritative (ADR-0003). The battlefield root
## carries the battle_finished seam (demo_battlefield.gd).
func _start_battle() -> void:
	var packed: PackedScene = load(BATTLEFIELD_SCENE_PATH)
	battlefield = packed.instantiate()
	_container.add_child(battlefield)
	if battlefield.has_signal("battle_finished"):
		battlefield.battle_finished.connect(_on_battle_finished)
	_show_sub_scene(battlefield)


## Host-authoritative game end: the Host decides when the battle is over
## and tells every Peer to return to the Waiting Room (connection stays
## open — rematches need no reconnect).
func _on_battle_finished() -> void:
	if not is_host or transport == null:
		return
	transport.broadcast({"type": "game_end"})
	_end_battle()


func _end_battle() -> void:
	if battlefield != null:
		_container.remove_child(battlefield)
		battlefield.queue_free()
		battlefield = null
	_show_sub_scene(waiting_room)
	_render_room()


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
	transport.serve_failed.connect(_on_serve_failed)


func _ensure_transport() -> void:
	if transport == null:
		transport = _create_transport()


## Constructs the transport for the current Connection Mode. v1 has only
## Dev mode — its ENet transport lands in ticket 07 (Steam slots in here
## later); tests always inject FakeTransport instead.
func _create_transport() -> MpTransport:
	return DevTransport.new()


# ----- transport event handlers -----

func _on_peer_joined(peer_id: int, peer_name: String, peer_version: String) -> void:
	if not is_host or not room_open:
		return
	# Version Check: a mismatching Peer is rejected and kicked before any
	# seat assignment; both sides get the localized message.
	if peer_version != game_version:
		transport.send_to_peer(peer_id, {"type": "rejected", "reason": "version_mismatch"})
		transport.kick(peer_id)
		_show_notification("notif_version_mismatch")
		return
	# Room Capacity reached: reject, then kick — enforcement does not rely
	# on the Peer leaving voluntarily.
	if peers.size() >= capacity:
		transport.send_to_peer(peer_id, {"type": "rejected", "reason": "room_full"})
		transport.kick(peer_id)
		return
	# Default assignment: fill the free Players' Seat (Player B first),
	# Spectator only once both seats are taken.
	var role := ROLE_SPECTATOR
	if _peer_in_role(ROLE_B) == 0:
		role = ROLE_B
	elif _peer_in_role(ROLE_A) == 0:
		role = ROLE_A
	peers[peer_id] = {"name": peer_name, "role": role}
	_broadcast_room_state()
	_render_room()


func _on_peer_dropped(peer_id: int) -> void:
	if not is_host:
		return
	if peers.erase(peer_id):
		_broadcast_room_state()
		_render_room()


func _on_join_succeeded() -> void:
	# Stay in the Connecting state: the Waiting Room is entered when the
	# Host's first room-state broadcast arrives (a rejected Peer never
	# leaves the Role Selector).
	pass


func _on_join_failed() -> void:
	if not _join_pending:
		return
	_join_pending = false
	role_selector.set_status("join_failed")
	role_selector.set_connecting(false)


func _on_host_lost() -> void:
	# The Host went offline while waiting: back to the Menu, notified.
	PendingNotification.set_pending("notif_host_offline")
	_go_to_menu()


func _on_room_closed() -> void:
	# The Host explicitly closed the room: kicked to the Menu, notified.
	PendingNotification.set_pending("notif_host_closed")
	_go_to_menu()


func _on_serve_failed() -> void:
	# The room could not open (e.g. port busy). Room state is untouched —
	# confirm_room_config keeps the Game Config editable.
	_show_notification("notif_serve_failed")


func _on_message_received(sender_id: int, message: Dictionary) -> void:
	if is_host:
		# Peers send role-change requests; the Host validates them.
		match message.get("type", ""):
			"take_seat":
				_apply_take_seat(sender_id, message.get("seat", ""))
			"step_down":
				_apply_step_down(sender_id)
	else:
		match message.get("type", ""):
			"room_state":
				_apply_room_state(message)
			"game_start":
				_start_battle()
			"game_end":
				_end_battle()
			"rejected":
				# E.g. room full: disconnect and land on the Menu with the
				# localized Notification for the rejection reason.
				transport.leave()
				PendingNotification.set_pending("notif_" + message.get("reason", "connection_lost"))
				_go_to_menu()


# ----- room state -----

## Host-side: the authoritative room state as a broadcast message.
func _build_room_state() -> Dictionary:
	var peer_data := {}
	for peer_id in peers:
		peer_data[str(peer_id)] = peers[peer_id].duplicate()
	return {
		"type": "room_state",
		"host_name": host_name,
		"capacity": capacity,
		"port": room_port,
		"peers": peer_data,
	}


## Host-side: replicate the room state to every Peer's Waiting Room.
func _broadcast_room_state() -> void:
	transport.broadcast(_build_room_state())


## Peer-side: adopt the Host's room state and mirror it read-only.
func _apply_room_state(message: Dictionary) -> void:
	# Ignore late room-state messages when no join is pending and the
	# Waiting Room is not up (e.g. after a failed connect).
	if not _join_pending and not waiting_room.visible:
		return
	_join_pending = false
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
	# Peers mirror the Host's Game Config read-only; the pre-confirm Host's
	# fields are the edit source, so they are left untouched while editing.
	if not (is_host and not room_open):
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
	# Game Config is Host-editable only before the room opens.
	var editable := is_host and not room_open
	waiting_room.host_name_edit.editable = editable
	waiting_room.capacity_spin.editable = editable
	waiting_room.port_edit.editable = editable
	waiting_room.confirm_button.visible = is_host
	waiting_room.confirm_button.disabled = not editable or str(peers.get(HOST_ID, {}).get("name", "")).is_empty()


# ----- internals -----

## In-place Notification popup for events that don't navigate away
## (e.g. the Host side of a version mismatch). Same AcceptDialog pattern
## as the Menu's pending Notification.
func _show_notification(key: String) -> void:
	notification_dialog = AcceptDialog.new()
	notification_dialog.dialog_text = Loc.t(key)
	add_child(notification_dialog)
	notification_dialog.popup_centered()


## Swaps sub-scenes inside the container, exactly one visible at a time.
func _show_sub_scene(sub: Node) -> void:
	for child in _container.get_children():
		if child is CanvasItem or child is Node3D:
			child.set("visible", child == sub)


func _go_to_menu() -> void:
	var target: PackedScene = load(MENU_SCENE_PATH)
	chosen_target = target
	get_tree().change_scene_to_packed(target)
