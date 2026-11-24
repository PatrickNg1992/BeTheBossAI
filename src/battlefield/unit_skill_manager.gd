class_name UnitSkillManager
extends Node

## Battle-scoped manager node (in group "unit_skill_manager") that handles:
## - Creating and equipping UnitSkill instances (MoveSkill, AttackSkill, ActiveSkill, PassiveSkill)
## - Maintaining a trigger-time-to-skills map so event sites query only skills
##   registered for a specific trigger time without looping all skills
## - Common skill effects: Statistic Buff/Debuff recalculation, On the cue table,
##   Pocket Area Damage +/-?%, and Skill Countdown ticking
## - Cross-unit skill effects (e.g. SPA10001 Protect, SPA10003 Safety Rope, SPA10004 Chanting)

# Checking times for Passive Skills per `.docmanual/battleField/unitInformation/unitSkills.md`:
const TRIGGER_ON_CREATED := "on_created"
const TRIGGER_ON_PUCK_COLLISION := "on_puck_collision"
const TRIGGER_ON_CUSHION_COLLISION := "on_cushion_collision"
const TRIGGER_ON_POCKET_FALL := "on_pocket_fall"
const TRIGGER_ON_POCKET_RETURN := "on_pocket_return"
const TRIGGER_ON_DAMAGE_DEALT := "on_damage_dealt"
const TRIGGER_ON_DAMAGE_RECEIVED := "on_damage_received"
const TRIGGER_ON_UNIT_DEFEATED := "on_unit_defeated"
const TRIGGER_ON_ACTION_TIME_START := "on_action_time_start"
const TRIGGER_ON_BEFORE_MOVE := "on_before_move"
const TRIGGER_ON_AFTER_MOVE := "on_after_move"
const TRIGGER_ON_BEFORE_ATTACK := "on_before_attack"
const TRIGGER_ON_AFTER_ATTACK := "on_after_attack"
const TRIGGER_ON_CARD_PLAYED := "on_card_played"
const TRIGGER_ON_CUE_SHOT := "on_cue_shot"
const TRIGGER_ON_CARD_COMPLETED := "on_card_completed"
const TRIGGER_ON_CARD_DRAWN := "on_card_drawn"

var unit_information_manager: UnitInformationManager = null
var _skills_by_unit: Dictionary = {} # unit_id -> Array[UnitSkill]
var _skills_by_trigger: Dictionary = {} # trigger_time -> Array[{"unit_id": String, "skill": UnitSkill}]


func _ready() -> void:
	add_to_group("unit_skill_manager")


func bind_unit_information_manager(p_uim: UnitInformationManager) -> void:
	if unit_information_manager != null and is_instance_valid(unit_information_manager):
		if unit_information_manager.unit_registered.is_connected(_on_unit_registered):
			unit_information_manager.unit_registered.disconnect(_on_unit_registered)
		if unit_information_manager.units_cleared.is_connected(clear_all):
			unit_information_manager.units_cleared.disconnect(clear_all)
	unit_information_manager = p_uim
	if unit_information_manager != null:
		unit_information_manager._skill_manager = self
		unit_information_manager.unit_registered.connect(_on_unit_registered)
		unit_information_manager.units_cleared.connect(clear_all)
		clear_all()
		for u in unit_information_manager.get_all_units():
			_on_unit_registered(u)


func clear_all() -> void:
	_skills_by_unit.clear()
	_skills_by_trigger.clear()


func _on_unit_registered(u: UnitInformationDO) -> void:
	if u == null:
		return
	register_unit_skills(u)


## Indexes all `UnitSkill` instances on `u` into `_skills_by_unit` and `_skills_by_trigger`.
## If `u.skills` contains skill ID strings (or `UnitSkill` instances), normalizes them into `UnitSkill` objects.
func register_unit_skills(u: UnitInformationDO) -> void:
	if u == null:
		return
	_remove_unit_from_trigger_map(u.unit_id)
	var normalized: Array = []
	for item in u.skills:
		if item is UnitSkill:
			normalized.append(item)
		elif item is String:
			var s_str := str(item)
			var created := create_skill(s_str, u.default_skill_lv)
			if created != null:
				normalized.append(created)
			else:
				normalized.append(s_str)
	u.skills = normalized

	var typed_skills: Array[UnitSkill] = []
	for item in u.skills:
		if item is UnitSkill:
			var sk := item as UnitSkill
			typed_skills.append(sk)
			for trig in sk.trigger_times:
				if not _skills_by_trigger.has(trig):
					_skills_by_trigger[trig] = []
				(_skills_by_trigger[trig] as Array).append({
					"unit_id": u.unit_id,
					"skill": sk,
				})
	_skills_by_unit[u.unit_id] = typed_skills


func _remove_unit_from_trigger_map(unit_id: String) -> void:
	_skills_by_unit.erase(unit_id)
	for trig in _skills_by_trigger.keys():
		var arr: Array = _skills_by_trigger[trig]
		for i in range(arr.size() - 1, -1, -1):
			if str(arr[i].get("unit_id", "")) == unit_id:
				arr.remove_at(i)


## Fast lookup of all registered skills for `trigger_time` without scanning all units/skills.
## If `unit_id` is non-empty, filters to skills belonging to `unit_id`.
func get_skills_for_trigger(trigger_time: String, unit_id: String = "") -> Array:
	if not _skills_by_trigger.has(trigger_time):
		return []
	var all_entries: Array = _skills_by_trigger[trigger_time]
	if unit_id.is_empty():
		return all_entries.duplicate()
	var filtered: Array = []
	for entry in all_entries:
		if str(entry.get("unit_id", "")) == unit_id:
			filtered.append(entry)
	return filtered


func get_unit_skills(unit_id: String) -> Array[UnitSkill]:
	if _skills_by_unit.has(unit_id):
		return (_skills_by_unit[unit_id] as Array[UnitSkill]).duplicate()
	if unit_information_manager != null:
		var u := unit_information_manager.get_unit(unit_id)
		if u != null:
			var res: Array[UnitSkill] = []
			for s in u.skills:
				if s is UnitSkill:
					res.append(s as UnitSkill)
			return res
	return []


func get_unit_move_skill(unit_id: String) -> MoveSkill:
	for sk in get_unit_skills(unit_id):
		if sk is MoveSkill:
			return sk as MoveSkill
	return null


func get_unit_attack_skill(unit_id: String) -> AttackSkill:
	for sk in get_unit_skills(unit_id):
		if sk is AttackSkill:
			return sk as AttackSkill
	return null


func get_unit_active_skill(unit_id: String) -> ActiveSkill:
	for sk in get_unit_skills(unit_id):
		if sk is ActiveSkill:
			return sk as ActiveSkill
	return null


func get_unit_passive_skills(unit_id: String) -> Array[PassiveSkill]:
	var res: Array[PassiveSkill] = []
	for sk in get_unit_skills(unit_id):
		if sk is PassiveSkill:
			res.append(sk as PassiveSkill)
	return res


## Ticks down all Skill Countdowns by `turns` (default 1) for all non-defeated units
## (including pocketed units, clamping at 0).
func tick_all_skill_countdowns(turns: int = 1) -> void:
	for uid in _skills_by_unit.keys():
		if unit_information_manager != null:
			var u := unit_information_manager.get_unit(str(uid))
			if u != null and u.is_dead:
				continue
		for sk in _skills_by_unit[uid]:
			if sk is UnitSkill:
				(sk as UnitSkill).tick_countdown(turns)


# ----- Common Skill Effects: Statistic Buff/Debuff (`commonSkillEffects.md`) -----

static func apply_stat_modifier(
	unit_do: UnitInformationDO,
	modifier_id: String,
	stat_name: String,
	pct_bonus: float = 0.0,
	flat_bonus: int = 0
) -> void:
	if unit_do == null or modifier_id.is_empty():
		return
	var updated := false
	for i in range(unit_do.stat_modifiers.size()):
		var entry: Dictionary = unit_do.stat_modifiers[i]
		if str(entry.get("id", "")) == modifier_id:
			unit_do.stat_modifiers[i] = {
				"id": modifier_id,
				"stat": stat_name,
				"pct": pct_bonus,
				"flat": flat_bonus,
			}
			updated = true
			break
	if not updated:
		unit_do.stat_modifiers.append({
			"id": modifier_id,
			"stat": stat_name,
			"pct": pct_bonus,
			"flat": flat_bonus,
		})
	recalculate_unit_stats(unit_do)


static func remove_stat_modifier(unit_do: UnitInformationDO, modifier_id: String) -> void:
	if unit_do == null or modifier_id.is_empty():
		return
	var removed := false
	for i in range(unit_do.stat_modifiers.size() - 1, -1, -1):
		if str(unit_do.stat_modifiers[i].get("id", "")) == modifier_id:
			unit_do.stat_modifiers.remove_at(i)
			removed = true
	if removed:
		recalculate_unit_stats(unit_do)


## Recalculates `max_hp`, `power`, and `spd` from `base_max_hp`, `base_power`, `base_spd`
## and active `stat_modifiers`:
##   `final = round(base_stat * (1.0 + sum_pct) + sum_flat)`
## When `max_hp` changes, `current_hp` is only clamped if `current_hp > max_hp`.
static func recalculate_unit_stats(unit_do: UnitInformationDO) -> void:
	if unit_do == null:
		return
	var hp_pct := 0.0
	var hp_flat := 0
	var pow_pct := 0.0
	var pow_flat := 0
	var spd_pct := 0.0
	var spd_flat := 0

	for mod in unit_do.stat_modifiers:
		if not mod is Dictionary:
			continue
		var s_name := str(mod.get("stat", ""))
		var pct := float(mod.get("pct", 0.0))
		var flat := int(mod.get("flat", 0))
		match s_name:
			"max_hp", "hp":
				hp_pct += pct
				hp_flat += flat
			"power", "pow":
				pow_pct += pct
				pow_flat += flat
			"spd", "speed":
				spd_pct += pct
				spd_flat += flat

	unit_do.max_hp = maxi(1, int(round(float(unit_do.base_max_hp) * (1.0 + hp_pct) + float(hp_flat))))
	if unit_do.current_hp > unit_do.max_hp:
		unit_do.current_hp = unit_do.max_hp
	unit_do.power = maxi(0, int(round(float(unit_do.base_power) * (1.0 + pow_pct) + float(pow_flat))))
	unit_do.spd = maxi(1, int(round(float(unit_do.base_spd) * (1.0 + spd_pct) + float(spd_flat))))


## Checks the "On the cue table" condition (`commonSkillEffects.md`):
## - unit is not defeated, and
## - unit is not pocketed (`is_pocketed == false`), and
## - if the unit has 3D pucks attached, at least one puck is not falling in a pocket.
static func is_unit_on_cue_table(unit_do: UnitInformationDO) -> bool:
	if unit_do == null or unit_do.is_dead or unit_do.is_pocketed:
		return false
	if not unit_do.pucks.is_empty():
		var has_active_table_puck := false
		for p in unit_do.pucks:
			if is_instance_valid(p) and not p.is_dead and not p.is_falling_in_pocket:
				if p.global_position.y >= Battlefield.TABLE_TOP_Y - 0.15:
					has_active_table_puck = true
					break
		return has_active_table_puck
	return true


# ----- Trigger-Time Passive Skill Dispatch (`ON_PUCK_COLLISION`, `ON_POCKET_FALL`) -----

## Dispatches `TRIGGER_ON_PUCK_COLLISION` when an opponent Boss Monster collides with `struck_unit`:
## - Evaluates `SPA10001 Protect`: reduces Boss Frenzy Power by `Y% = X * (4% + Lv * 1%)`
##   (where `X` is the number of non-defeated non-Guard-tree teammates in the SAME Adventurer Team,
##   including pocketed teammates), doubled to `2 * Y%` if `struck_puck` is the very first puck
##   in `boss_puck`'s Collision History for that shot.
func evaluate_boss_collision_frenzy_skills(
	_boss_unit: UnitInformationDO,
	struck_unit: UnitInformationDO,
	boss_puck: BasePuck = null,
	struck_puck: BasePuck = null
) -> float:
	if struck_unit == null:
		return 0.0
	var total_delta := 0.0
	var entries := get_skills_for_trigger(TRIGGER_ON_PUCK_COLLISION, struck_unit.unit_id)
	for entry in entries:
		var sk: UnitSkill = entry.get("skill", null) as UnitSkill
		if sk == null:
			continue
		if sk.skill_id == "SPA10001":
			var non_guard_count := PassiveSkill._count_same_team_non_guard_teammates(struck_unit, unit_information_manager)
			var y_delta := float(non_guard_count * (4 + sk.skill_lv * 1)) / 100.0
			var is_first_hit := true
			if boss_puck != null:
				is_first_hit = boss_puck.is_first_puck_hit_in_turn(struck_puck, struck_unit.unit_id)
			var mult := 2.0 if is_first_hit else 1.0
			total_delta -= y_delta * mult
	return total_delta


## Dispatches `TRIGGER_ON_PUCK_COLLISION` when two non-Boss units collide:
## - Evaluates `SPA10001 Protect`: when colliding with an ally in the SAME team,
##   reduces collision damage taken on both pucks by 50% (`0.50x`, fixed, not affected
##   by skill Lv, applied at most once per collision even if both pucks have Protect).
func evaluate_ally_collision_damage_multiplier(u1: UnitInformationDO, u2: UnitInformationDO) -> float:
	if u1 == null or u2 == null:
		return 1.0
	if u1.team_index != u2.team_index or u1.owner_seat != u2.owner_seat:
		return 1.0
	for uid in [u1.unit_id, u2.unit_id]:
		for entry in get_skills_for_trigger(TRIGGER_ON_PUCK_COLLISION, uid):
			var sk: UnitSkill = entry.get("skill", null) as UnitSkill
			if sk != null and sk.skill_id == "SPA10001":
				return 0.50
	return 1.0


## Dispatches `TRIGGER_ON_POCKET_FALL` when `falling_unit` falls into a Pocket Area:
## - Evaluates `SPA10003 Safety Rope`: every Scout in the SAME Adventurer Team that is
##   currently `On the cue table` (excluding `falling_unit` itself!) reduces Pocket Area
##   damage by `-(10 + Lv * 3)%` from the `50%` baseline (clamped to `0%..100%`).
## - Evaluates `SPA10004 Chanting`: if `falling_unit` has `SPA10004 Chanting`, resets its
##   chanting counter `N` to `0` and removes its chanting POW modifier immediately.
func handle_unit_pocket_fall_passives(falling_unit: UnitInformationDO) -> float:
	if falling_unit == null:
		return 0.50
	var pct := 0.50
	var entries := get_skills_for_trigger(TRIGGER_ON_POCKET_FALL)
	for entry in entries:
		var owner_id := str(entry.get("unit_id", ""))
		var sk: UnitSkill = entry.get("skill", null) as UnitSkill
		if sk == null:
			continue
		if sk.skill_id == "SPA10003":
			# The falling unit itself is no longer on the cue table when its pocket damage is calculated
			if owner_id == falling_unit.unit_id:
				continue
			var owner_u := unit_information_manager.get_unit(owner_id) if unit_information_manager != null else null
			if owner_u == null or owner_u.team_index != falling_unit.team_index or owner_u.owner_seat != falling_unit.owner_seat:
				continue
			if not is_unit_on_cue_table(owner_u):
				continue
			pct -= float(10 + sk.skill_lv * 3) / 100.0
		elif sk.skill_id == "SPA10004" and owner_id == falling_unit.unit_id:
			sk.counter = 0
			remove_stat_modifier(falling_unit, "SPA10004_chanting")
	return clampf(pct, 0.0, 1.0)


# ----- Factory for All Codex Skills (`SMA10001..10004`, `SAA10001..10004`, `SPA10001..10004`) -----

static func create_skill(skill_id: String, skill_lv: int = 1) -> UnitSkill:
	var lv := maxi(1, skill_lv)
	match skill_id:
		# ==================== MOVE SKILLS (SMA1) ====================
		"SMA10001":
			var sk := MoveSkill.new("SMA10001", lv)
			sk.name_key = "skill_name_SMA10001"
			sk.description_key = "skill_desc_SMA10001"
			sk.target_classes = ["ACG10001"]
			sk.base_dist_min = 0.0
			sk.base_dist_max = 1.3
			sk.lv_dist_min = 0.0
			sk.lv_dist_max = 0.2
			return sk
		"SMA10002":
			var sk := MoveSkill.new("SMA10002", lv)
			sk.name_key = "skill_name_SMA10002"
			sk.description_key = "skill_desc_SMA10002"
			sk.target_classes = ["ACB10001"]
			sk.base_dist_min = 0.8
			sk.base_dist_max = 1.0
			sk.lv_dist_min = 0.0
			sk.lv_dist_max = 0.2
			return sk
		"SMA10003":
			var sk := MoveSkill.new("SMA10003", lv)
			sk.name_key = "skill_name_SMA10003"
			sk.description_key = "skill_desc_SMA10003"
			sk.target_classes = ["ACS10001"]
			sk.base_dist_min = 0.8
			sk.base_dist_max = 1.0
			sk.lv_dist_min = 0.0
			sk.lv_dist_max = 0.2
			return sk
		"SMA10004":
			var sk := MoveSkill.new("SMA10004", lv)
			sk.name_key = "skill_name_SMA10004"
			sk.description_key = "skill_desc_SMA10004"
			sk.target_classes = ["ACA10001"]
			sk.base_dist_min = 1.5
			sk.base_dist_max = 2.0
			sk.lv_dist_min = 0.0
			sk.lv_dist_max = 0.2
			return sk

		# ==================== ATTACK SKILLS (SAA1) ====================
		"SAA10001":
			var sk := AttackSkill.new("SAA10001", lv)
			sk.name_key = "skill_name_SAA10001"
			sk.description_key = "skill_desc_SAA10001"
			sk.target_classes = ["ACG10001"]
			sk.max_countdown = 9
			sk.current_countdown = 9
			sk.base_ratio_pct = 90.0
			sk.lv_ratio_pct = 10.0
			sk.attack_range = 3.5
			sk.range_is_edge_to_edge = true
			sk.target_mode = "random_in_range"
			sk.skip_movement = true
			sk.hit_level_add = 2
			return sk
		"SAA10002":
			var sk := AttackSkill.new("SAA10002", lv)
			sk.name_key = "skill_name_SAA10002"
			sk.description_key = "skill_desc_SAA10002"
			sk.target_classes = ["ACB10001"]
			sk.max_countdown = 0
			sk.current_countdown = 0
			sk.base_ratio_pct = 90.0
			sk.lv_ratio_pct = 10.0
			sk.attack_range = 1.5
			sk.range_is_edge_to_edge = true
			sk.target_mode = "nearest"
			sk.skip_movement = true
			sk.hit_level_add = 1
			return sk
		"SAA10003":
			var sk := AttackSkill.new("SAA10003", lv)
			sk.name_key = "skill_name_SAA10003"
			sk.description_key = "skill_desc_SAA10003"
			sk.target_classes = ["ACS10001"]
			sk.max_countdown = 0
			sk.current_countdown = 0
			sk.base_ratio_pct = 45.0
			sk.lv_ratio_pct = 5.0
			sk.attack_range = 7.5
			sk.range_is_edge_to_edge = false
			sk.target_mode = "random_in_range"
			sk.skip_movement = false
			sk.hit_level_add = 1
			return sk
		"SAA10004":
			var sk := AttackSkill.new("SAA10004", lv)
			sk.name_key = "skill_name_SAA10004"
			sk.description_key = "skill_desc_SAA10004"
			sk.target_classes = ["ACA10001"]
			sk.max_countdown = 12
			sk.current_countdown = 12
			sk.base_ratio_pct = 225.0
			sk.lv_ratio_pct = 25.0
			sk.attack_range = INF
			sk.range_is_edge_to_edge = false
			sk.target_mode = "opponent_boss"
			sk.skip_movement = true
			sk.hit_level_add = 3
			return sk

		# ==================== PASSIVE SKILLS (SPA1) ====================
		"SPA10001":
			var sk := PassiveSkill.new("SPA10001", lv)
			sk.name_key = "skill_name_SPA10001"
			sk.description_key = "skill_desc_SPA10001"
			sk.target_classes = ["ACG10001"]
			sk.icon_path = "res://src/resource/battlefield/class_knight.png"
			sk.trigger_times = [TRIGGER_ON_PUCK_COLLISION]
			return sk
		"SPA10002":
			var sk := PassiveSkill.new("SPA10002", lv)
			sk.name_key = "skill_name_SPA10002"
			sk.description_key = "skill_desc_SPA10002"
			sk.target_classes = ["ACB10001"]
			sk.icon_path = "res://src/resource/battlefield/class_warrior.png"
			sk.trigger_times = []
			return sk
		"SPA10003":
			var sk := PassiveSkill.new("SPA10003", lv)
			sk.name_key = "skill_name_SPA10003"
			sk.description_key = "skill_desc_SPA10003"
			sk.target_classes = ["ACS10001"]
			sk.icon_path = "res://src/resource/battlefield/class_ranger.png"
			sk.trigger_times = [TRIGGER_ON_POCKET_FALL]
			return sk
		"SPA10004":
			var sk := PassiveSkill.new("SPA10004", lv)
			sk.name_key = "skill_name_SPA10004"
			sk.description_key = "skill_desc_SPA10004"
			sk.target_classes = ["ACA10001"]
			sk.icon_path = "res://src/resource/battlefield/class_mage.png"
			sk.trigger_times = [TRIGGER_ON_ACTION_TIME_START, TRIGGER_ON_POCKET_FALL]
			return sk
		_:
			return null
