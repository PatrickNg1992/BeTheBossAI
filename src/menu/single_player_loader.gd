extends Node

## Single-Player Scene: invisible loader with no UI. Sets up an
## OfflineMultiplayerPeer and mounts the Battlefield as its child, so
## single-player and multiplayer share one Battlefield load path.

@export var battlefield_scene: PackedScene = preload("res://src/demo_bettlefield.tscn")


func _ready() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	add_child(battlefield_scene.instantiate())
