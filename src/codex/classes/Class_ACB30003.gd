extends "res://src/codex/classes/Class_ACB20002.gd"

## ACB30003 — Virtuoso (Rank 3, From: Duelist ACB20002)

func _init() -> void:
	super()
	_record_prerequisite("ACB20002")
	class_id = "ACB30003"
	name_key = "uib_class_virtuoso"
	rank = 3
	trait_text = "effect-buffed attack"
