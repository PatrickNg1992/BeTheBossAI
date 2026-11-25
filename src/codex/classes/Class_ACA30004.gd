extends "res://src/codex/classes/Class_ACA20002.gd"

## ACA30004 — Enchanter (Rank 3, From: Priest ACA20002)

func _init() -> void:
	super()
	_record_prerequisite("ACA20002")
	class_id = "ACA30004"
	name_key = "uib_class_enchanter"
	rank = 3
	trait_text = "buffs"
