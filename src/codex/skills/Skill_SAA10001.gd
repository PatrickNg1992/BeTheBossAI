extends AttackSkill

## SAA10001 — Lance (Guard Base Attack Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SAA10001", p_skill_lv)
	name_key = "skill_name_SAA10001"
	description_key = "skill_desc_SAA10001"
	target_classes = ["ACG10001"]
	max_countdown = 9
	current_countdown = 9
	base_ratio_pct = 90.0
	lv_ratio_pct = 10.0
	attack_range = 7.0
	range_is_edge_to_edge = true
	target_mode = "random_in_range"
	skip_movement = true
	hit_level_add = 2
