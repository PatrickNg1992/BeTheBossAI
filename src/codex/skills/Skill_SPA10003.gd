extends PassiveSkill

## SPA10003 — Safety Rope (Scout Base Passive Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SPA10003", p_skill_lv)
	name_key = "skill_name_SPA10003"
	description_key = "skill_desc_SPA10003"
	target_classes = ["ACS10001"]
	icon_path = "res://src/resource/battlefield/class_ranger.png"
	trigger_times = ["on_pocket_fall"]
