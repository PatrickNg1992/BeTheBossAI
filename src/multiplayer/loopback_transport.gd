class_name LoopbackTransport
extends MpTransport

## Local in-memory loopback transport for the Single-Player Scene.
## Runs with is_host = true and local peer ID 1 (HOST_ID), delivering messages
## synchronously in-memory so Single-Player and Multiplayer share the exact
## same Host-authoritative command-to-sync pipeline without OfflineMultiplayerPeer.

const HOST_ID := 1

var is_host := true
## Recorded outgoing messages so tests can assert whether a message was sent
## with RELIABLE or UNRELIABLE_ORDERED.
var sent_records: Array[Dictionary] = []
var last_transfer_mode: int = RELIABLE


func _init() -> void:
	is_serving = true


func serve(_port: int) -> void:
	is_host = true
	is_serving = true


func join(_ip: String, _port: int, _player_name: String, _version: String) -> void:
	join_succeeded.emit()


func leave() -> void:
	is_serving = false


func close_room() -> void:
	is_serving = false
	room_closed.emit()


func kick(_peer_id: int) -> void:
	pass


func broadcast(message: Dictionary, transfer_mode: int = RELIABLE) -> void:
	last_transfer_mode = transfer_mode
	var copy := message.duplicate(true)
	sent_records.append({
		"op": "broadcast",
		"target_peer_id": 0,
		"message": copy,
		"transfer_mode": transfer_mode,
	})
	message_received.emit(HOST_ID, copy.duplicate(true))


func send_to_host(message: Dictionary, transfer_mode: int = RELIABLE) -> void:
	last_transfer_mode = transfer_mode
	var copy := message.duplicate(true)
	sent_records.append({
		"op": "send_to_host",
		"target_peer_id": HOST_ID,
		"message": copy,
		"transfer_mode": transfer_mode,
	})
	message_received.emit(HOST_ID, copy.duplicate(true))


func send_to_peer(peer_id: int, message: Dictionary, transfer_mode: int = RELIABLE) -> void:
	last_transfer_mode = transfer_mode
	var copy := message.duplicate(true)
	sent_records.append({
		"op": "send_to_peer",
		"target_peer_id": peer_id,
		"message": copy,
		"transfer_mode": transfer_mode,
	})
	if peer_id == HOST_ID:
		message_received.emit(HOST_ID, copy.duplicate(true))


func get_local_id() -> int:
	return HOST_ID


func clear_sent_records() -> void:
	sent_records.clear()
