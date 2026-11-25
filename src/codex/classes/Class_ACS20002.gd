extends "res://src/codex/classes/Class_ACS10001.gd"

## ACS20002 — Ranger (Rank 2, From: Scout ACS10001)

func _init() -> void:
	super()
	_record_prerequisite("ACS10001")
	class_id = "ACS20002"
	name_key = "uib_class_ranger"
	rank = 2
	trait_text = "effect-based"
