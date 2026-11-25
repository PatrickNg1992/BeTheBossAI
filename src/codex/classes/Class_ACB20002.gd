extends "res://src/codex/classes/Class_ACB10001.gd"

## ACB20002 — Duelist (Rank 2, From: Brawler ACB10001)

func _init() -> void:
	super()
	_record_prerequisite("ACB10001")
	class_id = "ACB20002"
	name_key = "uib_class_duelist"
	rank = 2
	trait_text = "effect-focused"
