extends "res://src/codex/classes/Class_ACS10001.gd"

## ACS20001 — Shooter (Rank 2, From: Scout ACS10001)

func _init() -> void:
	super()
	_record_prerequisite("ACS10001")
	class_id = "ACS20001"
	name_key = "uib_class_shooter"
	rank = 2
	trait_text = "attack-based"
