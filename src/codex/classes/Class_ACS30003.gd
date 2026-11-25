extends "res://src/codex/classes/Class_ACS20002.gd"

## ACS30003 — Trapper (Rank 3, From: Ranger ACS20002)

func _init() -> void:
	super()
	_record_prerequisite("ACS20002")
	class_id = "ACS30003"
	name_key = "uib_class_trapper"
	rank = 3
	trait_text = "hinder effects"
