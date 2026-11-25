extends MoveSkill

## SMA10001 — Block (Guard Base Move Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10001", p_skill_lv)
	name_key = "skill_name_SMA10001"
	description_key = "skill_desc_SMA10001"
	target_classes = ["ACG10001"]
	base_dist_min = 0.0
	base_dist_max = 1.3
	lv_dist_min = 0.0
	lv_dist_max = 0.2
