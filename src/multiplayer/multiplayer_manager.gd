extends Node

# Store connected client peer IDs on the server
var connected_players: Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Register signal callbacks for host connection events
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# Register signal callbacks for client connection events
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
# --- Server Signal Callbacks ---

func _on_peer_connected(id: int) -> void:
	# Fires on the server when a new client connects
	if multiplayer.is_server():
		print("SERVER: Player connected with ID: ", id)
		connected_players.append(id)
		print("Current connected players: ", connected_players)

func _on_peer_disconnected(id: int) -> void:
	# Fires on the server when a client leaves or drops connection
	if multiplayer.is_server():
		print("SERVER: Player disconnected with ID: ", id)
		connected_players.erase(id)
		print("Remaining connected players: ", connected_players)

# --- Client Signal Callbacks ---
func _on_connected_to_server() -> void:
	print("Connected to host.")
	
func _on_connection_failed() -> void:
	print("ERROR: Could not connect to host (server offline or timed out).")
	# Reset the peer so the client isn't left in a stuck state
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	print("NOTICE: Server disconnected.")
	multiplayer.multiplayer_peer = null
