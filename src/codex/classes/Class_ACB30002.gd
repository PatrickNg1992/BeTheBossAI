extends "res://src/codex/classes/Class_ACB20001.gd"

## ACB30002 — Berserker (Rank 3, From: Warrior ACB20001)

func _init() -> void:
	super()
	_record_prerequisite("ACB20001")
	class_id = "ACB30002"
	name_key = "uib_class_berserker"
	rank = 3
	trait_text = "strong attack with negative effects"
