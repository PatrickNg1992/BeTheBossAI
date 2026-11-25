extends PassiveSkill

## SPA10001 — Protect (Guard Base Passive Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SPA10001", p_skill_lv)
	name_key = "skill_name_SPA10001"
	description_key = "skill_desc_SPA10001"
	target_classes = ["ACG10001"]
	icon_path = "res://src/resource/battlefield/class_knight.png"
	trigger_times = ["on_puck_collision"]
