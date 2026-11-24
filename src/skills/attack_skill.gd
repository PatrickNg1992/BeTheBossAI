class_name AttackSkill
extends UnitSkill

## Abstract Attack Skill subclass (SAA10001..10004).
## Defines basic attack range, targeting, ratio (`unit.POW * ratio`),
## Skill Countdown, Hit Level bonus, and Skip Movement flag.

var base_ratio_pct: float = 90.0
var lv_ratio_pct: float = 10.0
var attack_range: float = 1.5
var range_is_edge_to_edge: bool = true
var target_mode: String = "nearest" # "nearest" | "random_in_range" | "opponent_boss"


func _init(p_skill_id: String = "", p_skill_lv: int = 1) -> void:
	super(p_skill_id, p_skill_lv)
	skill_category = CATEGORY_ATTACK
	type_key = "skill_type_attack"
	max_lv = 11
	icon_path = "res://src/resource/battlefield/sword.png"


func get_ratio_pct() -> float:
	return base_ratio_pct + float(skill_lv) * lv_ratio_pct


func get_ratio_multiplier() -> float:
	return get_ratio_pct() / 100.0


func resolve_variables(_owner_unit: UnitInformationDO = null, _manager: UnitInformationManager = null) -> Dictionary:
	var pct := get_ratio_pct()
	var pct_str := "%d%%" % int(round(pct)) if is_equal_approx(pct, round(pct)) else "%.1f%%" % pct
	return {
		"X": pct_str,
	}
