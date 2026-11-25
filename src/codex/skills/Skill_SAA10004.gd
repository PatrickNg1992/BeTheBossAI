extends AttackSkill

## SAA10004 — Spell Attack (Acolyte Base Attack Skill)

func _init(p_skill_lv: int = 1) -> void:
	super("SAA10004", p_skill_lv)
	name_key = "skill_name_SAA10004"
	description_key = "skill_desc_SAA10004"
	target_classes = ["ACA10001"]
	max_countdown = 12
	current_countdown = 12
	base_ratio_pct = 225.0
	lv_ratio_pct = 25.0
	attack_range = INF
	range_is_edge_to_edge = false
	target_mode = "opponent_boss"
	skip_movement = true
	hit_level_add = 3
