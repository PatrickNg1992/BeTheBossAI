extends AttackSkill

## SAA10002 — Melee (Brawler Base Attack Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SAA10002", p_skill_lv)
	name_key = "skill_name_SAA10002"
	description_key = "skill_desc_SAA10002"
	target_classes = ["ACB10001"]
	max_countdown = 0
	current_countdown = 0
	base_ratio_pct = 90.0
	lv_ratio_pct = 10.0
	attack_range = 1.5
	range_is_edge_to_edge = true
	target_mode = "nearest"
	skip_movement = true
	hit_level_add = 1
