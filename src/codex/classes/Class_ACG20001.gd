extends "res://src/codex/classes/Class_ACG10001.gd"

## ACG20001 — Sentinel (Rank 2, From: Guard ACG10001)

func _init() -> void:
	super()
	_record_prerequisite("ACG10001")
	class_id = "ACG20001"
	name_key = "uib_class_sentinel"
	rank = 2
	trait_text = "self-focused"
