extends Node

## Single-Player Scene: invisible loader with no UI. Sets up a local
## LoopbackTransport (is_host = true, local peer 1, Player A = 1,
## Player B = empty) and mounts the Battlefield as its child, so
## single-player and multiplayer share one Host-authoritative Battlefield path.

@export var battlefield_scene: PackedScene = preload("res://src/demo_bettlefield.tscn")

var transport: LoopbackTransport = null
var battlefield: Node3D = null


func _ready() -> void:
	transport = LoopbackTransport.new()
	battlefield = battlefield_scene.instantiate()
	if battlefield.has_method("configure_session"):
		battlefield.configure_session(transport, true, LoopbackTransport.HOST_ID, {
			"player_a": LoopbackTransport.HOST_ID,
			"player_b": 0,
			"spectators": [],
		})
	add_child(battlefield)
