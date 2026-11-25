extends "res://src/codex/classes/Class_ACG10001.gd"

## ACG20002 — Knight (Rank 2, From: Guard ACG10001)

func _init() -> void:
	super()
	_record_prerequisite("ACG10001")
	class_id = "ACG20002"
	name_key = "uib_class_knight"
	rank = 2
	trait_text = "protection-focused"
