extends PassiveSkill

## SPA10004 — Chanting (Acolyte Base Passive Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SPA10004", p_skill_lv)
	name_key = "skill_name_SPA10004"
	description_key = "skill_desc_SPA10004"
	target_classes = ["ACA10001"]
	icon_path = "res://src/resource/battlefield/class_mage.png"
	trigger_times = ["on_action_time_start", "on_pocket_fall"]
