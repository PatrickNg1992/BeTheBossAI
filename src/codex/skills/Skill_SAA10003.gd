extends AttackSkill

## SAA10003 — Shoot (Scout Base Attack Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SAA10003", p_skill_lv)
	name_key = "skill_name_SAA10003"
	description_key = "skill_desc_SAA10003"
	target_classes = ["ACS10001"]
	max_countdown = 0
	current_countdown = 0
	base_ratio_pct = 45.0
	lv_ratio_pct = 5.0
	attack_range = 15.0
	range_is_edge_to_edge = false
	target_mode = "random_in_range"
	skip_movement = false
	hit_level_add = 1
