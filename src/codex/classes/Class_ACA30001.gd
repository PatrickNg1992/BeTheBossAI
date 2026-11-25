extends "res://src/codex/classes/Class_ACA20001.gd"

## ACA30001 — Sorcerer (Rank 3, From: Mage ACA20001)

func _init() -> void:
	super()
	_record_prerequisite("ACA20001")
	class_id = "ACA30001"
	name_key = "uib_class_sorcerer"
	rank = 3
	trait_text = "attack focused"
