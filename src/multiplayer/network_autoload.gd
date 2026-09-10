extends Node

const PORT = 8910
const MAX_CLIENTS = 2

func host_game() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_CLIENTS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Server started on port ", PORT)

func join_game(ip_address: String = "127.0.0.1") -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip_address, PORT)
	if error == OK:
		peer.get_peer(1).set_timeout(0, 10000, 15000)
		multiplayer.multiplayer_peer = peer
		print("Connecting to host...")
		
