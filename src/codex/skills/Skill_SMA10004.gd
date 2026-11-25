extends MoveSkill

## SMA10004 — Move Away (Acolyte Base Move Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10004", p_skill_lv)
	name_key = "skill_name_SMA10004"
	description_key = "skill_desc_SMA10004"
	target_classes = ["ACA10001"]
	base_dist_min = 1.5
	base_dist_max = 2.0
	lv_dist_min = 0.0
	lv_dist_max = 0.2
