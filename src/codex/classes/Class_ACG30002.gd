extends "res://src/codex/classes/Class_ACG20001.gd"

## ACG30002 — Vanguard (Rank 3, From: Sentinel ACG20001)

func _init() -> void:
	super()
	_record_prerequisite("ACG20001")
	class_id = "ACG30002"
	name_key = "uib_class_vanguard"
	rank = 3
	trait_text = "taunt and block"
