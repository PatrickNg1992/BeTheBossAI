extends Node3D

## Demo battlefield root. Surfaces battle_finished so the Multiplayer Scene
## manager can swap everyone back to the Waiting Room when the battle ends.
## (Battle content and win/lose rules are the battle side's concern — this
## demo ends when the Boss Monster dies.)

signal battle_finished()

@onready var _player: Node3D = $Player


func _ready() -> void:
	if _player != null and _player.has_signal("died"):
		_player.died.connect(func() -> void: battle_finished.emit())
