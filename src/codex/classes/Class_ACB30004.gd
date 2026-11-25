extends "res://src/codex/classes/Class_ACB20002.gd"

## ACB30004 — Spellblade (Rank 3, From: Duelist ACB20002)

func _init() -> void:
	super()
	_record_prerequisite("ACB20002")
	class_id = "ACB30004"
	name_key = "uib_class_spellblade"
	rank = 3
	trait_text = "effect damage"
