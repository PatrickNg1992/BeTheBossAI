extends "res://src/codex/classes/Class_ACG20001.gd"

## ACG30001 — Bastion (Rank 3, From: Sentinel ACG20001)

func _init() -> void:
	super()
	_record_prerequisite("ACG20001")
	class_id = "ACG30001"
	name_key = "uib_class_bastion"
	rank = 3
	trait_text = "tanky"
