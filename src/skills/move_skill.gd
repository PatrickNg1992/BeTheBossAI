class_name MoveSkill
extends UnitSkill

## Abstract Move Skill subclass (SMA10001..10004).
## Defines unit movement distance range and direction rules in Action Time.
## By default, all distance checks in Move Skills are measured centre-to-centre.

var base_dist_min: float = 0.8
var base_dist_max: float = 1.0
var lv_dist_min: float = 0.0
var lv_dist_max: float = 0.2


func _init(p_skill_id: String = "", p_skill_lv: int = 1) -> void:
	super(p_skill_id, p_skill_lv)
	skill_category = CATEGORY_MOVE
	type_key = "skill_type_move"
	max_lv = 3
	icon_path = "res://src/resource/battlefield/double_arrow.png"


func get_min_distance() -> float:
	return base_dist_min + float(skill_lv) * lv_dist_min


func get_max_distance() -> float:
	return base_dist_max + float(skill_lv) * lv_dist_max


func roll_distance(rng: RandomNumberGenerator = null) -> float:
	var r_base := randf_range(base_dist_min, base_dist_max) if rng == null else rng.randf_range(base_dist_min, base_dist_max)
	var r_lv := randf_range(lv_dist_min, lv_dist_max) if rng == null else rng.randf_range(lv_dist_min, lv_dist_max)
	return r_base + float(skill_lv) * r_lv


func resolve_variables(_owner_unit: UnitInformationDO = null, _manager: UnitInformationManager = null) -> Dictionary:
	return {
		"DIST": "%.1f-%.1f" % [get_min_distance(), get_max_distance()],
	}
