class_name PassiveSkill
extends UnitSkill

## Abstract Passive Skill subclass (SPA10001..10004).
## Triggered at specific checking times via UnitSkillManager's trigger-time map.


func _init(p_skill_id: String = "", p_skill_lv: int = 1) -> void:
	super(p_skill_id, p_skill_lv)
	skill_category = CATEGORY_PASSIVE
	type_key = "skill_type_passive"
	max_lv = 3
	icon_path = "res://src/resource/battlefield/class_knight.png"


func resolve_variables(owner_unit: UnitInformationDO = null, manager: UnitInformationManager = null) -> Dictionary:
	match skill_id:
		"SPA10001":
			var non_guard_count := _count_same_team_non_guard_teammates(owner_unit, manager)
			var per_unit := 4 + skill_lv * 1
			var y_pct := non_guard_count * per_unit
			return {
				"X": str(non_guard_count),
				"Y": "%d%%" % y_pct,
			}
		"SPA10003":
			var x_pct := 10 + skill_lv * 3
			return {
				"X": "%d%%" % x_pct,
			}
		"SPA10004":
			var n_val := maxi(1, counter)
			var x_pct := float(n_val) * (7.5 + float(skill_lv) * 2.5)
			var x_str := "%d%%" % int(round(x_pct)) if is_equal_approx(x_pct, round(x_pct)) else "%.1f%%" % x_pct
			return {
				"N": str(counter),
				"X": x_str,
			}
		_:
			return {}


static func _count_same_team_non_guard_teammates(owner_unit: UnitInformationDO, manager: UnitInformationManager) -> int:
	if owner_unit == null or manager == null:
		return 0
	var count := 0
	for u in manager.get_all_units():
		if u == null or u.is_dead or u.unit_id == owner_unit.unit_id:
			continue
		if u.unit_kind != "enemy_adventurer":
			continue
		if u.team_index != owner_unit.team_index or u.owner_seat != owner_unit.owner_seat:
			continue
		if not ClassCodex.is_in_class_tree(u.class_id if not u.class_id.is_empty() else u.adventurer_class, ClassCodex.TREE_GUARD):
			count += 1
	return count
