extends "res://src/codex/classes/Class_ACS20001.gd"

## ACS30002 — Barrager (Rank 3, From: Shooter ACS20001)

func _init() -> void:
	super()
	_record_prerequisite("ACS20001")
	class_id = "ACS30002"
	name_key = "uib_class_barrager"
	rank = 3
	trait_text = "heavy-power focused"
