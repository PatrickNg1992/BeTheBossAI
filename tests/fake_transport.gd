class_name FakeTransport
extends MpTransport

## Fake in-memory transport for tests. Simulates Peers joining, dropping and
## rejoining deterministically — no real sockets, no timing flakiness.
##
## A Host fake registers itself in the static registry on serve(); a Peer
## fake's join() finds its Host by "ip:port", mirroring how the manager calls
## the real transport. Message delivery is synchronous. Tests drive lifecycle
## events with simulate_* methods; delivered messages are deep-duplicated so
## Host and Peer state never alias.

var served_port := 0
var join_attempts := 0
## When true, the next serve() emits serve_failed instead of registering.
var fail_next_serve := false
var _is_host := false
var _local_id := 0
var _host: FakeTransport = null
var _peers: Dictionary = {}  # host-side: peer_id -> FakeTransport
var _next_peer_id := 2

## port -> serving host FakeTransport (the fake ignores the IP; Dev-mode
## tests are all localhost anyway). Reset between tests.
static var registry: Dictionary = {}


static func reset_registry() -> void:
	registry.clear()


## Host-side constructor.
static func create_host() -> FakeTransport:
	var t := FakeTransport.new()
	t._is_host = true
	t._local_id = 1
	return t


## Peer-side constructor.
static func create_peer() -> FakeTransport:
	return FakeTransport.new()


func serve(port: int) -> void:
	if fail_next_serve:
		fail_next_serve = false
		serve_failed.emit()
		return
	is_serving = true
	served_port = port
	registry[port] = self


func join(_ip: String, port: int, player_name: String, version: String) -> void:
	join_attempts += 1
	var host: FakeTransport = registry.get(port)
	if host == null or not host.is_serving:
		join_failed.emit()
		return
	_host = host
	_host._accept_peer(self, player_name, version)
	join_succeeded.emit()


func leave() -> void:
	if _host != null:
		_host._remove_peer(_local_id)
		_host = null


func close_room() -> void:
	var peers := _peers.values()
	_peers.clear()
	is_serving = false
	registry.erase(served_port)
	for peer in peers:
		peer._host = null
		peer.room_closed.emit()


func broadcast(message: Dictionary) -> void:
	for peer_id in _peers:
		_peers[peer_id].message_received.emit(1, message.duplicate(true))


func send_to_host(message: Dictionary) -> void:
	if _host != null:
		_host.message_received.emit(_local_id, message.duplicate(true))


func send_to_peer(peer_id: int, message: Dictionary) -> void:
	var peer: FakeTransport = _peers.get(peer_id)
	if peer != null:
		peer.message_received.emit(1, message.duplicate(true))


## Host-side: forcibly disconnect a Peer; its link dies (host_lost).
func kick(peer_id: int) -> void:
	var peer: FakeTransport = _peers.get(peer_id)
	if peer == null:
		return
	peer._host = null
	_peers.erase(peer_id)
	peer.host_lost.emit()


func get_local_id() -> int:
	return _local_id


## Host-side: accept an incoming Peer, assigning the next id.
func _accept_peer(peer: FakeTransport, peer_name: String, peer_version: String) -> void:
	peer._local_id = _next_peer_id
	_next_peer_id += 1
	_peers[peer._local_id] = peer
	peer_joined.emit(peer._local_id, peer_name, peer_version)


## Host-side: drop the Peer record and notify.
func _remove_peer(peer_id: int) -> void:
	if _peers.erase(peer_id):
		peer_dropped.emit(peer_id)


# ----- test drivers -----

## Peer-side: simulate the link to the Host dying without a clean close.
func simulate_host_lost() -> void:
	var host := _host
	_host = null
	if host != null:
		host._remove_peer(_local_id)
	host_lost.emit()


## Peer-side: simulate a connection attempt timing out mid-"Connecting…".
func simulate_join_timeout() -> void:
	join_failed.emit()


## Host-side: simulate a Peer vanishing mid-room (Peer machine died — the
## Peer side is not notified, matching a pure drop).
func simulate_peer_drop(peer_id: int) -> void:
	var peer: FakeTransport = _peers.get(peer_id)
	if peer != null:
		peer._host = null
		_remove_peer(peer_id)


## Host-side: count of currently linked Peers.
func peer_count() -> int:
	return _peers.size()
