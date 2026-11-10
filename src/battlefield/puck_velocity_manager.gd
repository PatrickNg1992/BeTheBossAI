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

const TICK_INTERVAL := 0.05
const STOP_SPEED_THRESHOLD := 0.002
const DEFAULT_DECELERATION := 1.2

var battlefield: Battlefield = null
var timing_manager: TimingManager = null

var _tick_accumulator: float = 0.0
var _in_puck_puck_time: bool = false
var _clock_paused: bool = false


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
	puck.apply_table_physics(eff_dt)
	if absf(puck.velocity.y) > 0.0001:
		puck.global_position.y += puck.velocity.y * eff_dt
		var table := battlefield
		var over_pocket := table != null and table.is_pocket_at_world(puck.global_position)
		var floor_y := _puck_floor_y(puck)
		if not over_pocket and puck.global_position.y <= floor_y and puck.velocity.y < 0.0:
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

	# 2. Ground Friction Forces
	for puck in pucks:
		if puck.is_dead or _is_puck_pocketed(puck):
			continue
		var horiz := Vector2(puck.velocity.x, puck.velocity.z)
		if horiz.length() <= 0.00001:
			puck.velocity.x = 0.0
			puck.velocity.z = 0.0
			continue
		var block: TableBlock = null
		if battlefield != null:
			block = battlefield.get_table_block_at_world(puck.global_position)
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
## simple swept/overlap check.
func _resolve_all_puck_collisions(pucks: Array[BasePuck], eff_dt: float) -> void:
	var count := pucks.size()
	for i in range(count):
		var p1 := pucks[i]
		if p1 == null or p1.is_dead:
			continue
		for j in range(i + 1, count):
			var p2 := pucks[j]
			if p2 == null or p2.is_dead:
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
	if p1 == null or p2 == null or p1.is_dead or p2.is_dead:
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
	return true


func are_all_pucks_at_rest() -> bool:
	for puck in _get_pucks():
		if puck.is_dead or _is_puck_pocketed(puck):
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
	if battlefield != null:
		var cushion := battlefield.get_cushion_block_for_normal(puck.global_position, inward_normal)
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
	if puck.global_position.y < Battlefield.TABLE_TOP_Y - 0.15:
		return true
	if battlefield != null and battlefield.is_pocket_at_world(puck.global_position):
		return true
	return false


func _puck_floor_y(puck: BasePuck) -> float:
	var half_h := 0.25
	var col := puck.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null and col.shape is CylinderShape3D:
		half_h = (col.shape as CylinderShape3D).height * 0.5
	return Battlefield.TABLE_TOP_Y + half_h


## Once all non-pocketed Pucks come to rest, respawns any Puck that fell into
## a Pocket Area at the nearest unoccupied non-pocket Tile.
func _respawn_pocketed_pucks(pucks: Array[BasePuck]) -> void:
	if battlefield == null:
		return
	for puck in pucks:
		if puck == null or puck.is_dead or not _is_puck_pocketed(puck):
			continue
		var best_block: TableBlock = null
		var best_dist_sq := INF
		var blocks_root := battlefield.get_node_or_null("TableBlocks")
		if blocks_root == null:
			continue
		for child in blocks_root.get_children():
			if not child is TableBlock:
				continue
			var blk := child as TableBlock
			if blk.is_pocket():
				continue
			var tile_world := battlefield.to_global(blk.position)
			if _is_tile_occupied(tile_world, puck, pucks):
				continue
			var dx := tile_world.x - puck.global_position.x
			var dz := tile_world.z - puck.global_position.z
			var d_sq := dx * dx + dz * dz
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_block = blk
		if best_block != null:
			var target_world := battlefield.to_global(best_block.position)
			puck.global_position = Vector3(target_world.x, _puck_floor_y(puck), target_world.z)
			puck.velocity = Vector3.ZERO
			puck.collision_mask = 3


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
