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


static func is_opponent_unit(actor: UnitInformationDO, candidate: UnitInformationDO) -> bool:
	if actor == null or candidate == null or candidate.is_dead:
		return false
	if actor.owner_seat != "enemy" and candidate.owner_seat != "enemy":
		return actor.owner_seat != candidate.owner_seat
	if actor.owner_seat == "enemy":
		return candidate.owner_seat != "enemy"
	return candidate.owner_seat == "enemy"


## Finds a valid opponent target `{target_unit: UnitInformationDO, target_puck: BasePuck}`
## according to `target_mode` ("opponent_boss" | "nearest" | "random_in_range"),
## `attack_range`, and `range_is_edge_to_edge`.
func find_attack_target(
	actor_do: UnitInformationDO,
	actor_puck: BasePuck,
	uim: UnitInformationManager,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	if actor_do == null or uim == null:
		return {}
	var actor_pos := actor_puck.global_position if actor_puck != null else Vector3.ZERO
	var actor_r := actor_puck.radius if actor_puck != null else actor_do.radius

	if target_mode == "opponent_boss":
		for u in uim.get_all_units():
			if u == null or u.is_dead or u.unit_kind != "boss":
				continue
			if not is_opponent_unit(actor_do, u):
				continue
			if not UnitSkillManager.is_unit_on_cue_table(u):
				continue
			var t_puck: BasePuck = u.pucks[0] if not u.pucks.is_empty() else null
			return {"target_unit": u, "target_puck": t_puck}
		return {}

	var candidates: Array[Dictionary] = []
	var nearest_entry: Dictionary = {}
	var nearest_dist := INF

	for u in uim.get_all_units():
		if u == null or u.is_dead or not is_opponent_unit(actor_do, u):
			continue
		if not UnitSkillManager.is_unit_on_cue_table(u):
			continue
		if u.pucks.is_empty():
			continue
		for p in u.pucks:
			if not is_instance_valid(p) or p.is_dead or p.is_falling_in_pocket:
				continue
			var center_dist := Vector2(p.global_position.x - actor_pos.x, p.global_position.z - actor_pos.z).length()
			var eff_dist := (center_dist - (actor_r + p.radius)) if range_is_edge_to_edge else center_dist
			var entry := {"target_unit": u, "target_puck": p, "distance": eff_dist}
			if eff_dist < nearest_dist:
				nearest_dist = eff_dist
				nearest_entry = entry
			if eff_dist <= attack_range + 0.001:
				candidates.append(entry)

	if target_mode == "nearest":
		if not nearest_entry.is_empty() and nearest_dist <= attack_range + 0.001:
			return nearest_entry
		return {}

	if candidates.is_empty():
		return {}
	var pick_idx := randi_range(0, candidates.size() - 1) if rng == null else rng.randi_range(0, candidates.size() - 1)
	return candidates[pick_idx]
