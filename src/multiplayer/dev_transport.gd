class_name DevTransport
extends MpTransport

## Dev Connection Mode transport: ENet over direct IP + port (default 8910).
## Built on a raw ENetConnection (no MultiplayerAPI/RPC): connect/disconnect/
## receive events arrive synchronously from poll(), which the manager calls
## every frame and tests pump manually.
##
## Wire format: packets are var_to_bytes Dictionaries on channel 0 (reliable).
## Handshake — client sends {"k": "hello", "name", "version"} once ENet
## connects; the server answers {"k": "welcome", "id"} and only then reports
## peer_joined. Manager messages ride as {"k": "msg", "d": {...}}; a clean
## Close Room rides as {"k": "closed"} before the disconnect.

const MAX_PEERS := 6
const CHANNEL := 0

var is_host := false
## Connect-attempt deadline — join_failed fires when it lapses. Tests
## shrink this to keep the suite fast.
var connect_timeout_ms := 5000

var _conn: ENetConnection = null
var _next_id := 2
var _peers := {}  # host: logical id -> ENetPacketPeer (welcomed)
var _pending: Array = []  # host: ENetPacketPeer awaiting hello
var _server_peer: ENetPacketPeer = null  # client side
var _welcomed := false
var _local_id := 0  # client: assigned by the Host's welcome
var _closed_cleanly := false
var _connect_started_ms := -1
var _join_name := ""
var _join_version := ""


func serve(port: int) -> void:
	is_host = true
	_conn = ENetConnection.new()
	# In Godot 4.6 create_host() has no port — listening requires the
	# bound variant on the wildcard address.
	var err := _conn.create_host_bound("0.0.0.0", port, MAX_PEERS, 1)
	if err != OK:
		_conn = null
		serve_failed.emit()
		return
	is_serving = true


func join(ip: String, port: int, player_name: String, version: String) -> void:
	is_host = false
	_join_name = player_name
	_join_version = version
	_conn = ENetConnection.new()
	var err := _conn.create_host(1, 1)
	if err != OK:
		_conn = null
		join_failed.emit()
		return
	_server_peer = _conn.connect_to_host(ip, port, 1)
	if _server_peer == null:
		_conn = null
		join_failed.emit()
		return
	_connect_started_ms = Time.get_ticks_msec()


func leave() -> void:
	if _conn == null:
		return
	if not is_host and _server_peer != null and _server_peer.is_active():
		_server_peer.peer_disconnect()
		_conn.flush()
	dispose()


func close_room() -> void:
	if _conn == null or not is_host:
		return
	for id in _peers:
		_send(_peers[id], {"k": "closed"})
	_conn.flush()
	for id in _peers:
		_peers[id].peer_disconnect_later()
	_conn.flush()
	dispose()


func kick(peer_id: int) -> void:
	var peer: ENetPacketPeer = _peers.get(peer_id)
	if peer == null:
		return
	_peers.erase(peer_id)
	peer.peer_disconnect()
	_conn.flush()


func broadcast(message: Dictionary) -> void:
	if _conn == null or not is_host:
		return
	for id in _peers:
		_send(_peers[id], {"k": "msg", "d": message})
	_conn.flush()


func send_to_host(message: Dictionary) -> void:
	if _conn == null or is_host or _server_peer == null:
		return
	_send(_server_peer, {"k": "msg", "d": message})
	_conn.flush()


func send_to_peer(peer_id: int, message: Dictionary) -> void:
	var peer: ENetPacketPeer = _peers.get(peer_id)
	if peer == null:
		return
	_send(peer, {"k": "msg", "d": message})
	_conn.flush()


func get_local_id() -> int:
	return 1 if is_host else _local_id


## Services ENet: delivers events and enforces the connect deadline.
## Called by the manager every frame; tests pump it manually.
func poll() -> void:
	if _conn == null:
		return
	if not is_host and not _welcomed and _connect_started_ms >= 0:
		if Time.get_ticks_msec() - _connect_started_ms > connect_timeout_ms:
			dispose()
			join_failed.emit()
			return
	while true:
		var event: Array = _conn.service(0)
		if event[0] != ENetConnection.EVENT_CONNECT \
				and event[0] != ENetConnection.EVENT_DISCONNECT \
				and event[0] != ENetConnection.EVENT_RECEIVE:
			break
		_handle_event(event)


## Releases the ENet connection and resets state.
func dispose() -> void:
	if _conn != null:
		_conn.destroy()
	_conn = null
	_server_peer = null
	_pending.clear()
	_peers.clear()
	_welcomed = false
	_closed_cleanly = false
	_connect_started_ms = -1
	_local_id = 0
	is_serving = false


# ----- internals -----

func _send(peer: ENetPacketPeer, packet: Dictionary) -> void:
	peer.send(CHANNEL, var_to_bytes(packet), ENetPacketPeer.FLAG_RELIABLE)


func _handle_event(event: Array) -> void:
	var type: int = event[0]
	var peer: ENetPacketPeer = event[1]
	match type:
		ENetConnection.EVENT_CONNECT:
			if is_host:
				_pending.append(peer)
			else:
				_send(peer, {"k": "hello", "name": _join_name, "version": _join_version})
				_conn.flush()
		ENetConnection.EVENT_RECEIVE:
			# The event carries no payload — the packet is queued on the
			# ENetPacketPeer (PacketPeer API) on the event's channel.
			while peer.get_available_packet_count() > 0:
				_on_packet(peer, bytes_to_var(peer.get_packet()))
		ENetConnection.EVENT_DISCONNECT:
			_on_disconnect(peer)


func _on_packet(peer: ENetPacketPeer, packet: Variant) -> void:
	if not packet is Dictionary:
		return
	match packet.get("k", ""):
		"hello":
			if not is_host or not _pending.has(peer):
				return
			_pending.erase(peer)
			var id := _next_id
			_next_id += 1
			_peers[id] = peer
			_send(peer, {"k": "welcome", "id": id})
			_conn.flush()
			peer_joined.emit(id, packet.get("name", ""), packet.get("version", ""))
		"welcome":
			_welcomed = true
			_local_id = packet.get("id", 0)
			join_succeeded.emit()
		"msg":
			message_received.emit(_logical_id_of(peer), packet.get("d", {}))
		"closed":
			_closed_cleanly = true
			room_closed.emit()


func _on_disconnect(peer: ENetPacketPeer) -> void:
	if is_host:
		_pending.erase(peer)
		var id := _logical_id_of(peer)
		if id != 0:
			_peers.erase(id)
			peer_dropped.emit(id)
	else:
		var was_welcomed := _welcomed
		var was_clean := _closed_cleanly
		dispose()
		if not was_welcomed:
			join_failed.emit()
		elif not was_clean:
			host_lost.emit()


func _logical_id_of(peer: ENetPacketPeer) -> int:
	if not is_host:
		return 1  # the Peer's only counterpart is the Host
	for id in _peers:
		if _peers[id] == peer:
			return id
	return 0
