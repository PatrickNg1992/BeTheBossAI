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


static func find_opponent_boss_puck(actor_do: UnitInformationDO, uim: UnitInformationManager) -> BasePuck:
	if actor_do == null or uim == null:
		return null
	for u in uim.get_all_units():
		if u == null or u.is_dead or u.unit_kind != "boss":
			continue
		if AttackSkill.is_opponent_unit(actor_do, u) and not u.pucks.is_empty() and is_instance_valid(u.pucks[0]):
			return u.pucks[0]
	return null


static func find_nearest_opponent_puck(actor_do: UnitInformationDO, actor_pos: Vector3, uim: UnitInformationManager) -> BasePuck:
	if actor_do == null or uim == null:
		return null
	var nearest: BasePuck = null
	var nearest_dist := INF
	for u in uim.get_all_units():
		if u == null or u.is_dead or not AttackSkill.is_opponent_unit(actor_do, u):
			continue
		if not UnitSkillManager.is_unit_on_cue_table(u):
			continue
		for p in u.pucks:
			if not is_instance_valid(p) or p.is_dead or p.is_falling_in_pocket:
				continue
			var d := Vector2(p.global_position.x - actor_pos.x, p.global_position.z - actor_pos.z).length()
			if d < nearest_dist:
				nearest_dist = d
				nearest = p
	return nearest


static func rotate_xz_direction(dir_xz: Vector2, angle_rad: float) -> Vector2:
	var n := dir_xz.normalized() if dir_xz.length_squared() > 0.00001 else Vector2(1.0, 0.0)
	return n.rotated(angle_rad)


## Overridden by concrete `Skill_SMA*.gd` scripts to compute the raw Target Position
## decided by the Move Skill's effect (`{"should_move": bool, "target_position": Vector3}`).
func compute_raw_target_position(
	_actor_do: UnitInformationDO,
	actor_puck: BasePuck,
	_uim: UnitInformationManager,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var start_pos := actor_puck.global_position if actor_puck != null else Vector3.ZERO
	var angle := randf_range(0.0, TAU) if rng == null else rng.randf_range(0.0, TAU)
	var dist := roll_distance(rng)
	return {
		"should_move": true,
		"target_position": Vector3(start_pos.x + cos(angle) * dist, start_pos.y, start_pos.z + sin(angle) * dist),
	}
