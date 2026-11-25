class_name AutoFightManager
extends Node

## Battle-scoped manager node (in group "auto_fight_manager") that orchestrates
## the automated combat flow in Action Time and Settle Time for all units:
## - At the start of Action Time: dispatches `TRIGGER_ON_ACTION_TIME_START` passives
##   (`SPA10004 Chanting` increments counter `N` and boosts POW for on-table acting
##   Acolytes, while pocketed units returning on that turn skip the increment).
## - Phase 1 (All Active Skills): ordered by unit `SPD` descending, tie-broken by game order.
## - Phase 2 (All Attack Skills): ordered by unit `SPD` descending, tie-broken by game order;
##   checks `Skill Countdown` and range, plays staggered animations via `PresentationManager`,
##   pushes `unit.POW * ratio` DamageDO and applies `Hit Level+X` before Settle Time,
##   and marks `Skip Movement` if applicable.
## - Phase 3 (All Move Skills): ordered by unit `SPD` descending for units that did not
##   skip movement; computes raw Target Position from the Move Skill effect and resolves
##   a Valid Position (`Adjusted Target Position`) via the 3-circle spiral search
##   (checking against the `Adjusted Target Position` instead of the original position
##   for pucks that shall move), then glides with collider disabled.
## - Phase 4 (Pocketed Units Return): after all on-table units finish moving, respawns
##   pocketed units whose Action Countdown reached 0 in `SPD` descending order at a
##   random empty non-pocket Tile inside the middle 80% of the Cue Table (consuming
##   their action for that turn).
## - At Settle Time: respawns any surviving pocketed Boss Monster puck so the game continues.

signal action_time_completed(execution_trace: Array)

const GLIDE_SEARCH_STEP_DIST := 0.5
const GLIDE_SEARCH_STEPS_PER_CIRCLE := 8
const GLIDE_SEARCH_MAX_CIRCLES := 3
const POCKET_CORNER_MIN_X := 13.0
const POCKET_CORNER_MIN_Z := 8.0

var timing_manager: TimingManager = null
var unit_information_manager: UnitInformationManager = null
var unit_skill_manager: UnitSkillManager = null
var presentation_manager: PresentationManager = null
var battlefield: Battlefield = null
var time_board_model: TimeBoardModel = null

var auto_trigger_on_action_timing: bool = false
var last_execution_trace: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("auto_fight_manager")
	_rng.randomize()


func bind(
	p_tm: TimingManager,
	p_uim: UnitInformationManager,
	p_usm: UnitSkillManager = null,
	p_pm: PresentationManager = null,
	p_bf: Battlefield = null,
	p_tbm: TimeBoardModel = null
) -> void:
	if timing_manager != null and is_instance_valid(timing_manager):
		if timing_manager.timing_changed.is_connected(_on_timing_changed):
			timing_manager.timing_changed.disconnect(_on_timing_changed)
	timing_manager = p_tm
	unit_information_manager = p_uim
	unit_skill_manager = p_usm
	presentation_manager = p_pm
	battlefield = p_bf
	time_board_model = p_tbm
	if presentation_manager != null:
		presentation_manager.bind(timing_manager, unit_information_manager)
	if timing_manager != null and not timing_manager.timing_changed.is_connected(_on_timing_changed):
		timing_manager.timing_changed.connect(_on_timing_changed)


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	if not auto_trigger_on_action_timing:
		return
	if new_timing == TimingManager.TIMING_ACTION:
		if not _has_any_unit_ready_to_act():
			return
		var use_instant := true if presentation_manager == null else presentation_manager.instant_mode
		execute_action_time(use_instant, not use_instant)


func _has_any_unit_ready_to_act() -> bool:
	if unit_information_manager == null:
		return false
	for u in unit_information_manager.get_all_units():
		if u != null and not u.is_dead and u.unit_kind != "boss" and u.next_action_turns <= 0:
			return true
	return false


## Sorts units by `spd` descending, tie-broken by their registration order in `all_units`.
static func sort_units_by_spd_descending(units: Array[UnitInformationDO], all_units: Array[UnitInformationDO]) -> void:
	var order_map := {}
	for i in range(all_units.size()):
		if all_units[i] != null:
			order_map[all_units[i].unit_id] = i
	units.sort_custom(func(a: UnitInformationDO, b: UnitInformationDO) -> bool:
		if a.spd != b.spd:
			return a.spd > b.spd
		return int(order_map.get(a.unit_id, 0)) < int(order_map.get(b.unit_id, 0))
	)


## Executes the full Action Time flow:
## 0. `ON_ACTION_TIME_START` passives for on-table acting units (`SPA10004 Chanting`)
## 1. Phase 1: All Active Skills (`SPD` descending)
## 2. Phase 2: All Attack Skills (`SPD` descending)
## 3. Phase 3: All Move Skills (`SPD` descending, using `Move Glide Logic`)
## 4. Phase 4: Pocketed Units Return (`SPD` descending, consuming their action)
func execute_action_time(force_instant: bool = true, finish_timing_after_anim: bool = false) -> Array[Dictionary]:
	last_execution_trace.clear()
	if unit_information_manager == null:
		return last_execution_trace
	if unit_skill_manager == null:
		unit_skill_manager = unit_information_manager._skill_manager

	var all_units := unit_information_manager.get_all_units()
	var on_table_units: Array[UnitInformationDO] = []
	var returning_pocketed_units: Array[UnitInformationDO] = []

	for u in all_units:
		if u == null or u.is_dead or u.unit_kind == "boss":
			continue
		if u.next_action_turns > 0:
			continue
		if u.is_pocketed:
			returning_pocketed_units.append(u)
		elif UnitSkillManager.is_unit_on_cue_table(u):
			on_table_units.append(u)

	sort_units_by_spd_descending(on_table_units, all_units)
	sort_units_by_spd_descending(returning_pocketed_units, all_units)

	# 0. Start-of-Action Passives (`ON_ACTION_TIME_START`) — ONLY for on-table acting units
	#    (returning pocketed units skip the Chanting counter increment!)
	if unit_skill_manager != null:
		for u in on_table_units:
			unit_skill_manager.handle_unit_action_time_start_passives(u)
			unit_information_manager.unit_updated.emit(u)

	var movement_skipped: Dictionary = {} # unit_id -> true

	var max_glide_dur := 0.0
	var any_attack_fired := false

	# 1. Phase 1 — All Active Skills (`SPD` descending)
	if unit_skill_manager != null:
		for u in on_table_units:
			var act_sk := unit_skill_manager.get_unit_active_skill(u.unit_id)
			if act_sk == null or not act_sk.is_countdown_ready():
				continue
			# Active skills hook (none equipped on Rank-1 base classes)
			act_sk.mark_activated()
			if act_sk.skip_movement:
				movement_skipped[u.unit_id] = true
			last_execution_trace.append({
				"phase": "active",
				"unit_id": u.unit_id,
				"skill_id": act_sk.skill_id,
			})

	# 2. Phase 2 — All Attack Skills (`SPD` descending)
	if unit_skill_manager != null:
		for u in on_table_units:
			var atk_sk := unit_skill_manager.get_unit_attack_skill(u.unit_id)
			if atk_sk == null or not atk_sk.is_countdown_ready():
				continue
			var actor_puck: BasePuck = _get_primary_table_puck(u)
			var target_info := atk_sk.find_attack_target(u, actor_puck, unit_information_manager, _rng)
			if target_info.is_empty():
				continue
			var target_do: UnitInformationDO = target_info.get("target_unit", null) as UnitInformationDO
			var target_puck: BasePuck = target_info.get("target_puck", null) as BasePuck
			if target_do == null:
				continue

			atk_sk.mark_activated()
			any_attack_fired = true
			if atk_sk.skip_movement:
				movement_skipped[u.unit_id] = true

			var raw_dmg := float(u.power) * atk_sk.get_ratio_multiplier()
			if presentation_manager != null:
				presentation_manager.play_skill_attack_animation(u, target_do, atk_sk, actor_puck, target_puck, force_instant)
			elif unit_information_manager != null:
				unit_information_manager.trigger_unit_skill_popup(u.unit_id, atk_sk.get_localized_name())

			if atk_sk.hit_level_add != 0:
				unit_information_manager.modify_hit_level(target_do.unit_id, atk_sk.hit_level_add)
			unit_information_manager.push_damage(target_do.unit_id, raw_dmg, u.unit_id, "", "attack", false)
			if timing_manager != null:
				timing_manager.record_settle_event({
					"type": "attack_skill",
					"source_unit_id": u.unit_id,
					"target_unit_id": target_do.unit_id,
					"skill_id": atk_sk.skill_id,
					"damage": raw_dmg,
				})
			last_execution_trace.append({
				"phase": "attack",
				"unit_id": u.unit_id,
				"skill_id": atk_sk.skill_id,
				"target_unit_id": target_do.unit_id,
				"damage": raw_dmg,
				"hit_level_add": atk_sk.hit_level_add,
			})

	# 3. Phase 3 — All Move Skills (`SPD` descending, using `Move Glide Logic`)
	var moving_units: Array[UnitInformationDO] = []
	var moving_pucks_set: Dictionary = {}
	for u in on_table_units:
		if movement_skipped.has(u.unit_id):
			continue
		var move_sk := unit_skill_manager.get_unit_move_skill(u.unit_id) if unit_skill_manager != null else null
		if move_sk == null:
			continue
		moving_units.append(u)
		for p in u.pucks:
			if is_instance_valid(p) and not p.is_dead and not p.is_falling_in_pocket:
				moving_pucks_set[p] = true

	var planned_positions: Dictionary = {} # BasePuck -> Vector3 Adjusted Target Position
	for u in moving_units:
		var move_sk := unit_skill_manager.get_unit_move_skill(u.unit_id)
		var puck := _get_primary_table_puck(u)
		if puck == null:
			continue
		var from_pos := puck.global_position
		var raw_res := move_sk.compute_raw_target_position(u, puck, unit_information_manager, _rng)
		if not bool(raw_res.get("should_move", true)):
			planned_positions[puck] = from_pos
			continue
		var raw_target: Vector3 = raw_res.get("target_position", from_pos)
		var adj_res := resolve_adjusted_target_position(puck, raw_target, moving_pucks_set, planned_positions, _rng)
		if not bool(adj_res.get("valid", false)):
			# Cancelled after 3 circles -> stay at original position
			planned_positions[puck] = from_pos
			continue
		var adj_pos: Vector3 = adj_res.get("position", from_pos)
		planned_positions[puck] = adj_pos
		if presentation_manager != null:
			var g_dur := presentation_manager.play_glide_movement(u, puck, from_pos, adj_pos, force_instant)
			max_glide_dur = maxf(max_glide_dur, g_dur)
		else:
			puck.global_position = adj_pos
			puck.velocity = Vector3.ZERO
		last_execution_trace.append({
			"phase": "move",
			"unit_id": u.unit_id,
			"skill_id": move_sk.skill_id,
			"from": from_pos,
			"to": adj_pos,
		})

	# 4. Phase 4 — Pocketed Units Return (`SPD` descending, after all on-table units move)
	for u in returning_pocketed_units:
		respawn_unit_from_pocket(u)
		last_execution_trace.append({
			"phase": "pocket_return",
			"unit_id": u.unit_id,
		})

	action_time_completed.emit(last_execution_trace)
	if finish_timing_after_anim and is_inside_tree() and timing_manager != null:
		var time_sc := presentation_manager.get_time_scale() if presentation_manager != null else 1.0
		var atk_wait := (0.70 / time_sc) if any_attack_fired else 0.0
		var wait_sec := maxf(0.35 / time_sc, maxf(atk_wait, max_glide_dur) + 0.12)
		get_tree().create_timer(maxf(0.1, wait_sec)).timeout.connect(func() -> void:
			if is_instance_valid(self) and timing_manager != null and timing_manager.get_current_timing() == TimingManager.TIMING_ACTION:
				timing_manager.notify_actions_finished()
		)
	elif not finish_timing_after_anim and timing_manager != null and timing_manager.get_current_timing() == TimingManager.TIMING_ACTION:
		timing_manager.notify_actions_finished()
	return last_execution_trace


# ----- Move Glide Logic (`unitSkills.md` -> `### Move Glide Logic`) -----

## Resolves `raw_target_pos` to a Valid Position (`Adjusted Target Position`):
## - First checks whether `raw_target_pos` is a Valid Position; if yes, uses it.
## - Otherwise searches 3 concentric circles around `raw_target_pos`:
##   * Picks a random starting `Angle` on the table plane and sets `Distance = 0.5`.
##   * Checks `raw_target_pos + polar(Angle, Distance)`; if valid, uses it.
##   * Rotates `Angle` by 45 degrees clockwise; after every 8 steps (1 circle), increases `Distance` by +0.5.
##   * If 3 circles (24 checks at Distance = 0.5, 1.0, 1.5) complete without finding a Valid Position,
##     cancels the move (`{"valid": false, "position": puck.global_position}`).
func resolve_adjusted_target_position(
	puck: BasePuck,
	raw_target_pos: Vector3,
	moving_pucks_set: Dictionary = {},
	planned_positions: Dictionary = {},
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var y_val := puck.global_position.y if puck != null else 1.675
	var candidate_0 := Vector3(raw_target_pos.x, y_val, raw_target_pos.z)
	if is_valid_glide_position(puck, candidate_0, moving_pucks_set, planned_positions):
		return {"valid": true, "position": candidate_0, "circles_searched": 0}

	var start_angle := randf_range(0.0, TAU) if rng == null else rng.randf_range(0.0, TAU)
	var angle := start_angle
	var search_dist := GLIDE_SEARCH_STEP_DIST
	var step_angle := deg_to_rad(45.0)
	var total_checks := GLIDE_SEARCH_STEPS_PER_CIRCLE * GLIDE_SEARCH_MAX_CIRCLES

	for step in range(total_checks):
		var cand := Vector3(
			candidate_0.x + cos(angle) * search_dist,
			y_val,
			candidate_0.z + sin(angle) * search_dist
		)
		if is_valid_glide_position(puck, cand, moving_pucks_set, planned_positions):
			@warning_ignore("integer_division")
			var circle_num := (step / GLIDE_SEARCH_STEPS_PER_CIRCLE) + 1
			return {"valid": true, "position": cand, "circles_searched": circle_num}
		angle += step_angle
		if (step + 1) % GLIDE_SEARCH_STEPS_PER_CIRCLE == 0:
			search_dist += GLIDE_SEARCH_STEP_DIST

	return {
		"valid": false,
		"position": puck.global_position if puck != null else candidate_0,
		"circles_searched": GLIDE_SEARCH_MAX_CIRCLES,
	}


## Checks whether `candidate_pos` is a Valid Position for `puck`:
## 1. Inside the table and does not overlap with Cushions (`|x| <= 15 - r`, `|z| <= 10 - r`).
## 2. Not on a Pocket Area (neither on a pocket tile nor overlapping the 2x2 corner pocket zones).
## 3. Does not overlap with other pucks or obstacles (for any puck that shall move in the
##    current Move Skill phase and has already resolved its `Adjusted Target Position` in
##    `planned_positions`, uses its `Adjusted Target Position` instead of its original position).
func is_valid_glide_position(
	puck: BasePuck,
	candidate_pos: Vector3,
	moving_pucks_set: Dictionary = {},
	planned_positions: Dictionary = {}
) -> bool:
	var r := maxf(puck.radius if puck != null else 0.6, 0.2)
	var max_x := Battlefield.TABLE_HALF_X - r
	var max_z := Battlefield.TABLE_HALF_Z - r

	# 1. Inside the table and not overlapping Cushions
	if absf(candidate_pos.x) > max_x + 0.0001 or absf(candidate_pos.z) > max_z + 0.0001:
		return false

	# 2. Not on a Pocket Area
	if _is_position_on_pocket_area(candidate_pos, r):
		return false

	# 3. Not overlapping other pucks (considering Adjusted Target Position for pucks that shall move)
	if unit_information_manager != null:
		for u in unit_information_manager.get_all_units():
			if u == null or u.is_dead or u.is_pocketed:
				continue
			for other in u.pucks:
				if other == null or not is_instance_valid(other) or other == puck or other.is_dead or other.is_falling_in_pocket:
					continue
				if other.global_position.y < Battlefield.TABLE_TOP_Y - 0.15:
					continue
				var other_pos: Vector3 = other.global_position
				if planned_positions.has(other):
					other_pos = planned_positions[other] as Vector3
				elif moving_pucks_set.has(other):
					other_pos = other.global_position
				var min_sep := r + maxf(other.radius, 0.2)
				var d := Vector2(candidate_pos.x - other_pos.x, candidate_pos.z - other_pos.z).length()
				if d < min_sep - 0.0001:
					return false
	return true


func _is_position_on_pocket_area(pos: Vector3, puck_radius: float) -> bool:
	if battlefield != null and battlefield.is_pocket_at_world(pos):
		return true
	# Corner 2x2 Pocket Areas sit at |X| in [13, 15] and |Z| in [8, 10]
	if absf(pos.x) >= POCKET_CORNER_MIN_X - puck_radius * 0.5 and absf(pos.z) >= POCKET_CORNER_MIN_Z - puck_radius * 0.5:
		return true
	return false


# ----- Pocket Respawn Helpers (Phase 4 Adventurer Respawn & Settle Time Boss Respawn) -----

func respawn_unit_from_pocket(u: UnitInformationDO) -> bool:
	if u == null or u.is_dead:
		return false
	if unit_information_manager != null:
		unit_information_manager.set_unit_pocketed(u.unit_id, false, 0)
	for p in u.pucks:
		if is_instance_valid(p) and not p.is_dead:
			var spawn_pos := find_random_middle_80_empty_spawn_position(p)
			p.reset_from_pocket_fall(spawn_pos)
	return true


func respawn_pocketed_boss_units() -> void:
	if unit_information_manager == null:
		return
	for u in unit_information_manager.get_all_units():
		if u == null or u.is_dead or u.unit_kind != "boss":
			continue
		var any_pocketed := u.is_pocketed
		for p in u.pucks:
			if is_instance_valid(p) and (p.is_falling_in_pocket or p.global_position.y < Battlefield.TABLE_TOP_Y - 0.15):
				any_pocketed = true
		if any_pocketed:
			respawn_unit_from_pocket(u)


func find_random_middle_80_empty_spawn_position(ignore_puck: BasePuck) -> Vector3:
	var floor_y := _puck_floor_y(ignore_puck)
	var mid_x := Battlefield.TABLE_HALF_X * PhysicsConstant.POCKET_RESPAWN_MIDDLE_RATIO
	var mid_z := Battlefield.TABLE_HALF_Z * PhysicsConstant.POCKET_RESPAWN_MIDDLE_RATIO

	if battlefield != null:
		var blocks_root := battlefield.get_node_or_null("TableBlocks")
		if blocks_root != null:
			var middle_candidates: Array[TableBlock] = []
			var fallback_candidates: Array[TableBlock] = []
			for child in blocks_root.get_children():
				if not child is TableBlock:
					continue
				var blk := child as TableBlock
				if blk.is_pocket():
					continue
				var tile_world := battlefield.to_global(blk.position)
				var cand_pos := Vector3(tile_world.x, floor_y, tile_world.z)
				if not is_valid_glide_position(ignore_puck, cand_pos, {}, {}):
					continue
				fallback_candidates.append(blk)
				if absf(blk.position.x) <= mid_x + 0.001 and absf(blk.position.z) <= mid_z + 0.001:
					middle_candidates.append(blk)
			if not middle_candidates.is_empty():
				var blk := middle_candidates[_rng.randi_range(0, middle_candidates.size() - 1)]
				var w := battlefield.to_global(blk.position)
				return Vector3(w.x, floor_y, w.z)
			if not fallback_candidates.is_empty():
				var blk := fallback_candidates[_rng.randi_range(0, fallback_candidates.size() - 1)]
				var w := battlefield.to_global(blk.position)
				return Vector3(w.x, floor_y, w.z)

	for _attempt in range(40):
		var cand := Vector3(_rng.randf_range(-mid_x, mid_x), floor_y, _rng.randf_range(-mid_z, mid_z))
		if is_valid_glide_position(ignore_puck, cand, {}, {}):
			return cand
	return Vector3(0.0, floor_y, 0.0)


static func _puck_floor_y(puck: BasePuck) -> float:
	var half_h := 0.20
	if puck != null:
		var col := puck.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col != null and col.shape is CylinderShape3D:
			half_h = (col.shape as CylinderShape3D).height * 0.5
	return Battlefield.TABLE_TOP_Y + half_h


static func _get_primary_table_puck(u: UnitInformationDO) -> BasePuck:
	if u == null:
		return null
	for p in u.pucks:
		if is_instance_valid(p) and not p.is_dead and not p.is_falling_in_pocket:
			return p
	return null
