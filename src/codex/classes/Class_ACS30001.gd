extends "res://src/codex/classes/Class_ACS20001.gd"

## ACS30001 — Marksman (Rank 3, From: Shooter ACS20001)

func _init() -> void:
	super()
	_record_prerequisite("ACS20001")
	class_id = "ACS30001"
	name_key = "uib_class_marksman"
	rank = 3
	trait_text = "single-target focused"
