class_name PuckVelocityManager
extends Node

## Central Battlefield Puck physics manager:
## - Advances moving Puck positions every frame (step_positions / calculate_puck_position)
## - Recalculates velocity changes (ground Friction Forces via apply_force_to_puck,
##   and in ticket 03 Puck/Cushion collisions) at 20 Hz (TICK_INTERVAL = 0.05s)
## - Adopts Fast Play ratio across both position calculation and force application
## - Detects when all Pucks come to rest during Puck-puck Time! and notifies
##   TimingManager.

signal all_pucks_at_rest()

const TICK_INTERVAL := PhysicsConstant.VELOCITY_TICK_INTERVAL
const STOP_SPEED_THRESHOLD := PhysicsConstant.STOP_SPEED_THRESHOLD
const DEFAULT_DECELERATION := PhysicsConstant.DEFAULT_DECELERATION
const POCKET_RESPAWN_MIDDLE_RATIO := PhysicsConstant.POCKET_RESPAWN_MIDDLE_RATIO

var battlefield: Battlefield = null
var timing_manager: TimingManager = null
var unit_information_manager: UnitInformationManager = null

var _tick_accumulator: float = 0.0
var _in_puck_puck_time: bool = false
var _clock_paused: bool = false
var _boss_collision_energy_awarded_this_turn: bool = false


func _ready() -> void:
	add_to_group("puck_velocity_manager")
	_resolve_references()
	_bind_timing_signals()


func _resolve_references() -> void:
	var parent := get_parent()
	if battlefield == null and parent != null:
		battlefield = parent.get_node_or_null("Battlefield") as Battlefield
	if battlefield == null and is_inside_tree():
		battlefield = get_tree().get_first_node_in_group("cue_table") as Battlefield
	if timing_manager == null and parent != null:
		timing_manager = parent.get_node_or_null("TimingManager") as TimingManager
	if timing_manager == null and is_inside_tree():
		timing_manager = get_tree().get_first_node_in_group("timing_manager") as TimingManager
	if unit_information_manager == null and parent != null:
		unit_information_manager = parent.get_node_or_null("UnitInformationManager") as UnitInformationManager
	if unit_information_manager == null and is_inside_tree():
		unit_information_manager = get_tree().get_first_node_in_group("unit_information_manager") as UnitInformationManager


func _bind_timing_signals() -> void:
	if timing_manager == null:
		return
	if not timing_manager.timing_changed.is_connected(_on_timing_changed):
		timing_manager.timing_changed.connect(_on_timing_changed)
	if not timing_manager.pause_changed.is_connected(_on_pause_changed):
		timing_manager.pause_changed.connect(_on_pause_changed)
	_in_puck_puck_time = timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK
	_clock_paused = timing_manager.is_paused()


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	_in_puck_puck_time = new_timing == TimingManager.TIMING_PUCK_PUCK
	_tick_accumulator = 0.0
	if _in_puck_puck_time:
		reset_puck_puck_turn_state()


func reset_puck_puck_turn_state() -> void:
	_boss_collision_energy_awarded_this_turn = false


func _on_pause_changed(paused: bool) -> void:
	_clock_paused = paused


func get_fast_play_ratio(override_ratio: float = -1.0) -> float:
	if override_ratio >= 0.0:
		return override_ratio
	if timing_manager != null:
		return timing_manager.get_effective_time_scale()
	return 1.0


func apply_impulse_to_puck(puck: BasePuck, impulse: Vector3) -> void:
	if puck == null:
		return
	puck.apply_impulse(impulse)


func apply_force_to_puck(puck: BasePuck, force: Vector3, dt: float, fast_play_ratio: float = -1.0) -> void:
	if puck == null or dt <= 0.0:
		return
	var ratio := get_fast_play_ratio(fast_play_ratio)
	puck.apply_force(force, dt, ratio)
	if Vector2(puck.velocity.x, puck.velocity.z).length() < STOP_SPEED_THRESHOLD:
		puck.velocity.x = 0.0
		puck.velocity.z = 0.0


func calculate_puck_position(puck: BasePuck, delta: float, fast_play_ratio: float = -1.0) -> Vector3:
	if puck == null or puck.is_dead or delta <= 0.0:
		return puck.global_position if puck != null else Vector3.ZERO
	var ratio := get_fast_play_ratio(fast_play_ratio)
	var eff_dt := delta * ratio
	var horiz_sq := puck.velocity.x * puck.velocity.x + puck.velocity.z * puck.velocity.z
	if horiz_sq > 0.000001:
		var next_pos := puck.calculate_position(delta, ratio)
		puck.global_position.x = next_pos.x
		puck.global_position.z = next_pos.z
	# Check if moving puck just entered a Pocket block's 3/4 capture zone
	if not puck.is_falling_in_pocket and battlefield != null:
		var blk := battlefield.get_table_block_at_world(puck.global_position)
		if blk != null and blk.is_pocket() and blk.is_within_pocket_capture_zone(puck.global_position):
			blk.apply_pocket_effect(puck, delta, ratio)
			if puck.is_falling_in_pocket:
				_on_puck_entered_pocket(puck)
	puck.apply_table_physics(eff_dt)
	if absf(puck.velocity.y) > 0.0001:
		puck.global_position.y += puck.velocity.y * eff_dt
		var floor_y := _puck_floor_y(puck)
		if not puck.is_falling_in_pocket and puck.global_position.y <= floor_y and puck.velocity.y < 0.0:
			puck.global_position.y = floor_y
			puck.velocity.y = 0.0
	return puck.global_position


func _process(delta: float) -> void:
	if _clock_paused or delta <= 0.0:
		return
	if timing_manager != null:
		_in_puck_puck_time = timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK
		if not _in_puck_puck_time:
			return
	var ratio := get_fast_play_ratio()
	step_positions(delta, ratio)
	_tick_accumulator += delta
	while _tick_accumulator >= TICK_INTERVAL - 0.00001:
		_tick_accumulator = maxf(_tick_accumulator - TICK_INTERVAL, 0.0)
		step_velocities(TICK_INTERVAL, ratio)
		if timing_manager != null and timing_manager.get_current_timing() != TimingManager.TIMING_PUCK_PUCK:
			break
	var parent := get_parent()
	if parent != null and parent.has_method("sync_puck_positions") and _in_puck_puck_time:
		if timing_manager == null or timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK:
			parent.call("sync_puck_positions", {}, MpTransport.UNRELIABLE_ORDERED)


func step_positions(delta: float, fast_play_ratio: float = -1.0) -> void:
	if delta <= 0.0:
		return
	var ratio := get_fast_play_ratio(fast_play_ratio)
	var pucks := _get_pucks()
	for puck in pucks:
		if puck.is_dead:
			continue
		calculate_puck_position(puck, delta, ratio)


func step_velocities(tick_dt: float = TICK_INTERVAL, fast_play_ratio: float = -1.0) -> void:
	if tick_dt <= 0.0:
		return
	_resolve_references()
	var ratio := get_fast_play_ratio(fast_play_ratio)
	var pucks := _get_pucks()

	# 1. Swept/overlap collision check between all Puck pairs and against Cushions
	_resolve_all_puck_collisions(pucks, tick_dt * ratio)
	for puck in pucks:
		if not puck.is_dead and not _is_puck_pocketed(puck):
			_resolve_puck_cushion_collision(puck)

	# 2. Ground Friction / Pocket Floor Effects
	for puck in pucks:
		if puck.is_dead:
			continue
		var block: TableBlock = null
		if battlefield != null:
			block = battlefield.get_table_block_at_world(puck.global_position)
		if puck.is_falling_in_pocket:
			if block != null and block.is_pocket():
				block.apply_pocket_effect(puck, tick_dt, ratio)
			else:
				var drag := -Vector3(puck.velocity.x, 0.0, puck.velocity.z).normalized() * (TableBlock.POCKET_DECELERATION * puck.mass)
				apply_force_to_puck(puck, drag, tick_dt, ratio)
			continue
		if block != null and block.is_pocket():
			var was_falling := puck.is_falling_in_pocket
			block.apply_ground_effect(puck, tick_dt, ratio)
			if not was_falling and puck.is_falling_in_pocket:
				_on_puck_entered_pocket(puck)
			continue
		var horiz := Vector2(puck.velocity.x, puck.velocity.z)
		if horiz.length() <= 0.00001:
			puck.velocity.x = 0.0
			puck.velocity.z = 0.0
			continue
		if block != null:
			block.apply_ground_effect(puck, tick_dt, ratio)
		else:
			var force := -Vector3(puck.velocity.x, 0.0, puck.velocity.z).normalized() * (DEFAULT_DECELERATION * puck.mass)
			apply_force_to_puck(puck, force, tick_dt, ratio)

	if are_all_pucks_at_rest():
		_respawn_pocketed_pucks(pucks)
		all_pucks_at_rest.emit()
		if timing_manager != null and timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK:
			timing_manager.notify_all_pucks_at_rest()


## Resolves all Puck–Puck collisions over the current 20 Hz tick window using a
## simple swept/overlap check. Pocketed or falling pucks have their collider disabled
## and never block or collide with other pucks.
func _resolve_all_puck_collisions(pucks: Array[BasePuck], eff_dt: float) -> void:
	var count := pucks.size()
	for i in range(count):
		var p1 := pucks[i]
		if p1 == null or p1.is_dead or _is_puck_pocketed(p1):
			continue
		for j in range(i + 1, count):
			var p2 := pucks[j]
			if p2 == null or p2.is_dead or _is_puck_pocketed(p2):
				continue
			if _check_swept_or_overlap_pair(p1, p2, eff_dt):
				resolve_puck_puck_collision(p1, p2)


## Returns true if p1 and p2 are currently overlapping or if their relative
## motion over `eff_dt` brought them within combined radius `r1 + r2`.
func _check_swept_or_overlap_pair(p1: BasePuck, p2: BasePuck, eff_dt: float) -> bool:
	var combined_r := maxf(p1.radius, 0.1) + maxf(p2.radius, 0.1)
	var d_now := Vector2(p1.global_position.x - p2.global_position.x, p1.global_position.z - p2.global_position.z)
	var v_rel := Vector2(p1.velocity.x - p2.velocity.x, p1.velocity.z - p2.velocity.z)
	var v_len_sq := v_rel.length_squared()
	if eff_dt > 0.0 and v_len_sq > 0.000001:
		var d_prev := d_now - v_rel * eff_dt
		var a := v_len_sq
		var b := 2.0 * d_prev.dot(v_rel)
		var c := d_prev.length_squared() - combined_r * combined_r
		# If not already overlapping at the start of the tick, find the exact entry time t_hit in [0, eff_dt]
		if c > 0.0:
			var disc := b * b - 4.0 * a * c
			if disc >= 0.0:
				var t_hit := (-b - sqrt(disc)) / (2.0 * a)
				if t_hit >= 0.0 and t_hit <= eff_dt:
					var rem := eff_dt - t_hit
					p1.global_position.x -= p1.velocity.x * rem
					p1.global_position.z -= p1.velocity.z * rem
					p2.global_position.x -= p2.velocity.x * rem
					p2.global_position.z -= p2.velocity.z * rem
					return true
			return false
	if d_now.length_squared() <= combined_r * combined_r + 0.0001:
		return true
	return false


## 4-step classical Puck–Puck impulse exchange along the collision normal:
##   1. n = normalize(p1 - p2)
##   2. v_rel = (v1 - v2) . n  (only collide if approaching: v_rel < 0)
##   3. J = -(1 + e) * v_rel / (1/m1 + 1/m2)
##   4. v1f = v1 + (J / m1) * n,  v2f = v2 - (J / m2) * n
## Also separates positional overlap along n so pucks never snag.
func resolve_puck_puck_collision(p1: BasePuck, p2: BasePuck) -> bool:
	if p1 == null or p2 == null or p1.is_dead or p2.is_dead or _is_puck_pocketed(p1) or _is_puck_pocketed(p2):
		return false
	var delta_xz := Vector3(
		p1.global_position.x - p2.global_position.x,
		0.0,
		p1.global_position.z - p2.global_position.z
	)
	var dist := delta_xz.length()
	var combined_r := maxf(p1.radius, 0.1) + maxf(p2.radius, 0.1)
	if dist > combined_r + 0.05:
		return false
	var n := delta_xz / dist if dist > 0.0001 else Vector3(1.0, 0.0, 0.0)

	# Separate any positional overlap inversely proportional to mass
	var overlap := combined_r - dist
	if overlap > 0.0:
		var inv_m1 := 1.0 / maxf(p1.mass, 0.0001)
		var inv_m2 := 1.0 / maxf(p2.mass, 0.0001)
		var inv_sum := inv_m1 + inv_m2
		p1.global_position += n * (overlap * (inv_m1 / inv_sum))
		p2.global_position -= n * (overlap * (inv_m2 / inv_sum))

	var v1 := Vector3(p1.velocity.x, 0.0, p1.velocity.z)
	var v2 := Vector3(p2.velocity.x, 0.0, p2.velocity.z)
	var v_rel := (v1 - v2).dot(n)
	if v_rel >= -0.0001:
		return false

	var e := clampf(minf(p1.restitution, p2.restitution), 0.0, 1.0)
	var inv_m1 := 1.0 / maxf(p1.mass, 0.0001)
	var inv_m2 := 1.0 / maxf(p2.mass, 0.0001)
	var j_mag := -(1.0 + e) * v_rel / (inv_m1 + inv_m2)
	var impulse_vec := n * j_mag

	apply_impulse_to_puck(p1, impulse_vec)
	apply_impulse_to_puck(p2, -impulse_vec)
	p1.record_collision("puck", p2.get_unit_id(), p2)
	p2.record_collision("puck", p1.get_unit_id(), p1)
	p1._last_recorded_collision_puck = p2
	p2._last_recorded_collision_puck = p1
	_resolve_references()
	# In Multiplayer PvP, when a Boss Monster collides with the opponent Boss Monster:
	# - 0 damage is dealt to both Boss Monsters
	# - Both Boss pucks' post-collision velocities are immediately multiplied by 20% (0.2x)
	# - The non-active opponent gains +3 Energy (at most once per Puck-puck Time!)
	if p1 is BaseBossMonster and p2 is BaseBossMonster:
		p1.velocity.x *= PhysicsConstant.BOSS_VS_BOSS_VELOCITY_DAMPING
		p1.velocity.z *= PhysicsConstant.BOSS_VS_BOSS_VELOCITY_DAMPING
		p2.velocity.x *= PhysicsConstant.BOSS_VS_BOSS_VELOCITY_DAMPING
		p2.velocity.z *= PhysicsConstant.BOSS_VS_BOSS_VELOCITY_DAMPING
		_award_boss_collision_opponent_energy_once()
	if unit_information_manager != null:
		unit_information_manager.handle_puck_collision(p1, p2, j_mag)
		if timing_manager != null and j_mag > 0.0001:
			timing_manager.record_settle_event({"type": "collision", "impulse": j_mag})
	return true


func _award_boss_collision_opponent_energy_once() -> void:
	if _boss_collision_energy_awarded_this_turn:
		return
	_boss_collision_energy_awarded_this_turn = true
	var parent := get_parent()
	var shooter_seat := "a"
	if parent != null and "active_player" in parent:
		var act := str(parent.get("active_player"))
		if act == "a" or act == "b":
			shooter_seat = act
	var opponent_seat := "b" if shooter_seat == "a" else "a"
	if parent != null and parent.has_method("get_player_energy") and parent.has_method("set_player_energy"):
		var cur_e := float(parent.call("get_player_energy", opponent_seat))
		parent.call("set_player_energy", opponent_seat, minf(TimingManager.MAX_ENERGY, cur_e + 3.0))
		if parent.has_method("sync_time_board") and ("is_host" in parent and bool(parent.get("is_host"))):
			parent.call("sync_time_board", {}, MpTransport.RELIABLE)
	elif timing_manager != null:
		var cur_e := timing_manager.get_player_energy(opponent_seat)
		timing_manager.set_player_energy(opponent_seat, minf(TimingManager.MAX_ENERGY, cur_e + 3.0))


func are_all_pucks_at_rest() -> bool:
	for puck in _get_pucks():
		if puck.is_dead:
			continue
		if puck.is_falling_in_pocket:
			# Wait until a falling puck has sunk below the floor (y < 0.4) before declaring all at rest
			if puck.global_position.y > 0.4:
				return false
			continue
		if _is_puck_pocketed(puck):
			continue
		if Vector2(puck.velocity.x, puck.velocity.z).length() > STOP_SPEED_THRESHOLD:
			return false
	return true


## Resolves Puck–Cushion impact using the struck CushionBlock's extendable
## `apply_cushion_impact(puck, normal)` method (or standard rebound fallback).
func _resolve_puck_cushion_collision(puck: BasePuck) -> void:
	var r := maxf(puck.radius, 0.2)
	var max_x := Battlefield.TABLE_HALF_X - r
	var max_z := Battlefield.TABLE_HALF_Z - r

	if puck.global_position.x < -max_x:
		puck.global_position.x = -max_x
		if puck.velocity.x < 0.0:
			_apply_cushion_or_fallback(puck, Vector3(1.0, 0.0, 0.0))
	elif puck.global_position.x > max_x:
		puck.global_position.x = max_x
		if puck.velocity.x > 0.0:
			_apply_cushion_or_fallback(puck, Vector3(-1.0, 0.0, 0.0))

	if puck.global_position.z < -max_z:
		puck.global_position.z = -max_z
		if puck.velocity.z < 0.0:
			_apply_cushion_or_fallback(puck, Vector3(0.0, 0.0, 1.0))
	elif puck.global_position.z > max_z:
		puck.global_position.z = max_z
		if puck.velocity.z > 0.0:
			_apply_cushion_or_fallback(puck, Vector3(0.0, 0.0, -1.0))


func _apply_cushion_or_fallback(puck: BasePuck, inward_normal: Vector3) -> void:
	_resolve_references()
	var cushion: CushionBlock = battlefield.get_cushion_block_for_normal(puck.global_position, inward_normal) if battlefield != null else null
	puck.record_collision("cushion", "", cushion)
	if unit_information_manager != null:
		unit_information_manager.handle_puck_cushion_collision(puck)
	if cushion != null:
		cushion.apply_cushion_impact(puck, inward_normal)
		return
	var v_in := Vector3(puck.velocity.x, 0.0, puck.velocity.z)
	var v_dot_n := v_in.dot(inward_normal)
	if v_dot_n < 0.0:
		var v_perp := v_dot_n * inward_normal
		var v_parallel := v_in - v_perp
		var v_out := 0.9 * v_parallel - puck.restitution * v_perp
		puck.velocity.x = v_out.x
		puck.velocity.z = v_out.z


func _is_puck_pocketed(puck: BasePuck) -> bool:
	if puck == null or puck.is_dead:
		return false
	if puck.is_falling_in_pocket:
		return true
	if puck.global_position.y < Battlefield.TABLE_TOP_Y - 0.15:
		return true
	return false


func _puck_floor_y(puck: BasePuck) -> float:
	var half_h := 0.25
	var col := puck.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null and col.shape is CylinderShape3D:
		half_h = (col.shape as CylinderShape3D).height * 0.5
	return Battlefield.TABLE_TOP_Y + half_h


func _on_puck_entered_pocket(puck: BasePuck) -> void:
	_resolve_references()
	if unit_information_manager != null:
		unit_information_manager.push_pocket_fall_damage_for_puck(puck)
		var uid := puck.get_unit_id() if puck != null else ""
		if not uid.is_empty():
			var u_do := unit_information_manager.get_unit(uid)
			if u_do != null and u_do.unit_kind != "boss":
				unit_information_manager.set_unit_pocketed(uid, true, maxi(1, u_do.next_action_turns))
	if timing_manager != null:
		timing_manager.record_settle_event({"type": "pocket", "puck": puck.get_unit_id()})


## Once all non-pocketed Pucks come to rest:
## - Surviving pocketed Boss Monster pucks respawn at a random empty, non-pocket Tile
##   inside the middle 80% of the Cue Table so the game can continue.
## - Surviving pocketed Enemy Adventurers stay pocketed (`is_pocketed = true`, keeping
##   their Action Countdown and Time Board Action Tag counts unchanged) and return
##   in Phase 4 of their next Action Time via `AutoFightManager`.
func _respawn_pocketed_pucks(pucks: Array[BasePuck]) -> void:
	if battlefield == null:
		return
	var blocks_root := battlefield.get_node_or_null("TableBlocks")
	if blocks_root == null:
		return
	var middle_half_x := Battlefield.TABLE_HALF_X * POCKET_RESPAWN_MIDDLE_RATIO
	var middle_half_z := Battlefield.TABLE_HALF_Z * POCKET_RESPAWN_MIDDLE_RATIO
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for puck in pucks:
		if puck == null or puck.is_dead or not _is_puck_pocketed(puck):
			continue
		if unit_information_manager != null:
			var uid := puck.get_unit_id()
			if not uid.is_empty():
				var u_do := unit_information_manager.get_unit(uid)
				if u_do != null:
					if u_do.unit_kind == "enemy_adventurer":
						# Adventurers stay off-table and return at their next Action Time!
						unit_information_manager.set_unit_pocketed(uid, true, maxi(1, u_do.next_action_turns))
						continue
					var lethal_boss := (u_do.unit_kind == "boss" and u_do.bars_remaining <= 1 and u_do.get_preview_ghost_hp() <= 0)
					var lethal_other := (u_do.unit_kind != "boss" and u_do.get_preview_ghost_hp() <= 0)
					if u_do.is_dead or lethal_boss or lethal_other:
						continue
		var middle_candidates: Array[TableBlock] = []
		var fallback_candidates: Array[TableBlock] = []
		for child in blocks_root.get_children():
			if not child is TableBlock:
				continue
			var blk := child as TableBlock
			if blk.is_pocket():
				continue
			var tile_world := battlefield.to_global(blk.position)
			if _is_tile_occupied(tile_world, puck, pucks):
				continue
			fallback_candidates.append(blk)
			if absf(blk.position.x) <= middle_half_x + 0.001 and absf(blk.position.z) <= middle_half_z + 0.001:
				middle_candidates.append(blk)

		var chosen_block: TableBlock = null
		if not middle_candidates.is_empty():
			chosen_block = middle_candidates[rng.randi_range(0, middle_candidates.size() - 1)]
		elif not fallback_candidates.is_empty():
			chosen_block = fallback_candidates[rng.randi_range(0, fallback_candidates.size() - 1)]

		if chosen_block != null:
			var target_world := battlefield.to_global(chosen_block.position)
			puck.reset_from_pocket_fall(Vector3(target_world.x, _puck_floor_y(puck), target_world.z))


func _is_tile_occupied(tile_world: Vector3, ignore_puck: BasePuck, pucks: Array[BasePuck]) -> bool:
	for other in pucks:
		if other == null or other == ignore_puck or other.is_dead or _is_puck_pocketed(other):
			continue
		var min_sep := maxf(ignore_puck.radius, 0.4) + maxf(other.radius, 0.4)
		var d := Vector2(other.global_position.x - tile_world.x, other.global_position.z - tile_world.z).length()
		if d < min_sep:
			return true
	return false


func _get_pucks() -> Array[BasePuck]:
	var list: Array[BasePuck] = []
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is BasePuck and is_instance_valid(child):
				list.append(child as BasePuck)
		if not list.is_empty():
			return list
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("pucks"):
			if node is BasePuck and is_instance_valid(node):
				list.append(node as BasePuck)
	return list
