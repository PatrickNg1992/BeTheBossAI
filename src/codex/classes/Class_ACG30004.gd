extends "res://src/codex/classes/Class_ACG20002.gd"

## ACG30004 — Banneret (Rank 3, From: Knight ACG20002)

func _init() -> void:
	super()
	_record_prerequisite("ACG20002")
	class_id = "ACG30004"
	name_key = "uib_class_banneret"
	rank = 3
	trait_text = "aura-focused"
