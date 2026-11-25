extends "res://src/codex/classes/Class_ACA10001.gd"

## ACA20001 — Mage (Rank 2, From: Acolyte ACA10001)

func _init() -> void:
	super()
	_record_prerequisite("ACA10001")
	class_id = "ACA20001"
	name_key = "uib_class_mage"
	rank = 2
	trait_text = "damage-based"
