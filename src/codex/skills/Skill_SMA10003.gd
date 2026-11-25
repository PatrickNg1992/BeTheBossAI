extends MoveSkill

## SMA10003 — Patrol (Scout Base Move Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10003", p_skill_lv)
	name_key = "skill_name_SMA10003"
	description_key = "skill_desc_SMA10003"
	target_classes = ["ACS10001"]
	base_dist_min = 0.8
	base_dist_max = 1.0
	lv_dist_min = 0.0
	lv_dist_max = 0.2
