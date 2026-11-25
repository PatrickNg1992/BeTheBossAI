extends PassiveSkill

## SPA10002 — Heavy Hit (Brawler Base Passive Skill, TBC empty effect)

func _init(p_skill_lv: int = 1) -> void:
	super("SPA10002", p_skill_lv)
	name_key = "skill_name_SPA10002"
	description_key = "skill_desc_SPA10002"
	target_classes = ["ACB10001"]
	icon_path = "res://src/resource/battlefield/class_warrior.png"
	trigger_times = []
