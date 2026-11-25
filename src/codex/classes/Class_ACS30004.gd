extends "res://src/codex/classes/Class_ACS20002.gd"

## ACS30004 — Assassin (Rank 3, From: Ranger ACS20002)

func _init() -> void:
	super()
	_record_prerequisite("ACS20002")
	class_id = "ACS30004"
	name_key = "uib_class_assassin"
	rank = 3
	trait_text = "effect damage and damage prevention"
