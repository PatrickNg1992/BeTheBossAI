class_name MpTransport
extends RefCounted

## Network-transport seam for the Multiplayer Scene. The manager talks only
## to this interface; the Connection Mode picks the implementation
## (Dev ENet / future Steam). Tests inject FakeTransport.
##
## Operations: serve / join / leave / close_room, plus a message channel —
## broadcast (Host→all Peers), send_to_host (Peer→Host), send_to_peer
## (Host→one Peer). Lifecycle and messages arrive via the signals below.
## The Host always has local id 1.

## Host-side: a Peer connected (carries the Player Name and game version
## given at join — the manager Version-Checks before assigning a seat).
signal peer_joined(peer_id: int, peer_name: String, peer_version: String)
## Host-side: a Peer disconnected (left, dropped, or rejected-then-left).
signal peer_dropped(peer_id: int)
## Peer-side: the connection to the Host succeeded.
signal join_succeeded()
## Peer-side: the connection attempt failed (timeout / refused).
signal join_failed()
## Peer-side: the link to the Host was lost without a clean Close Room.
signal host_lost()
## Peer-side: the Host explicitly closed the room (the only clean end).
signal room_closed()
## Both sides: a message arrived. On a Peer, sender_id is the Host (1).
signal message_received(sender_id: int, message: Dictionary)
## Host-side: the room could not start serving (e.g. the port is busy).
signal serve_failed()

## Host-side: whether the room is currently open for connections.
var is_serving := false


## Pumps the transport (no-op for in-memory transports; the Dev transport
## services ENet here). The manager calls this every frame when a transport
## exists; tests pump the Dev transport manually.
func poll() -> void:
	pass


## Host: start listening for Peers on the given port.
func serve(_port: int) -> void:
	push_error("MpTransport.serve not implemented")


## Peer: attempt to connect, identified by player_name and game version.
func join(_ip: String, _port: int, _player_name: String, _version: String) -> void:
	push_error("MpTransport.join not implemented")


## Peer: disconnect from the room.
func leave() -> void:
	push_error("MpTransport.leave not implemented")


## Host: kick all Peers and stop serving (room_closed on the Peers).
func close_room() -> void:
	push_error("MpTransport.close_room not implemented")


## Host: forcibly disconnect one Peer (e.g. after a room-full rejection, so
## enforcement does not rely on the Peer leaving voluntarily).
func kick(_peer_id: int) -> void:
	push_error("MpTransport.kick not implemented")


## Host: send a message to every connected Peer.
func broadcast(_message: Dictionary) -> void:
	push_error("MpTransport.broadcast not implemented")


## Peer: send a message to the Host.
func send_to_host(_message: Dictionary) -> void:
	push_error("MpTransport.send_to_host not implemented")


## Host: send a message to one specific Peer.
func send_to_peer(_peer_id: int, _message: Dictionary) -> void:
	push_error("MpTransport.send_to_peer not implemented")


## The local peer id — 1 for the Host, assigned for Peers (0 before the
## welcome completes).
func get_local_id() -> int:
	push_error("MpTransport.get_local_id not implemented")
	return 0
