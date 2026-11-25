extends "res://src/codex/classes/Class_ACG20002.gd"

## ACG30003 — Paladin (Rank 3, From: Knight ACG20002)

func _init() -> void:
	super()
	_record_prerequisite("ACG20002")
	class_id = "ACG30003"
	name_key = "uib_class_paladin"
	rank = 3
	trait_text = "support and heal effects"
