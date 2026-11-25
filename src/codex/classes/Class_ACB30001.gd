extends "res://src/codex/classes/Class_ACB20001.gd"

## ACB30001 — Champion (Rank 3, From: Warrior ACB20001)

func _init() -> void:
	super()
	_record_prerequisite("ACB20001")
	class_id = "ACB30001"
	name_key = "uib_class_champion"
	rank = 3
	trait_text = "balanced-attacker"
