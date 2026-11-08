class_name PuckVelocityManager
extends Node

## Central Battlefield Puck physics manager:
## - Advances moving Puck positions every frame (step_positions)
## - Recalculates velocity changes (ground Friction Forces, and in ticket 03
##   Puck/Cushion collisions) at 20 Hz (TICK_INTERVAL = 0.05s)
## - Detects when all Pucks come to rest during Puck-puck Time! and notifies
##   TimingManager.

signal all_pucks_at_rest()

const TICK_INTERVAL := 0.05
const STOP_SPEED_THRESHOLD := 0.002

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


func _process(delta: float) -> void:
	if _clock_paused or delta <= 0.0:
		return
	if timing_manager != null:
		_in_puck_puck_time = timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK
		if not _in_puck_puck_time:
			return
	var scale := timing_manager.get_effective_time_scale() if timing_manager != null else 1.0
	var scaled_dt := delta * scale
	step_positions(scaled_dt)
	# Step velocities at fixed intervals (20 Hz) to avoid framerate-dependent physics.
	_tick_accumulator += scaled_dt
	while _tick_accumulator >= TICK_INTERVAL - 0.00001:
		_tick_accumulator = maxf(_tick_accumulator - TICK_INTERVAL, 0.0)
		step_velocities(TICK_INTERVAL)
		if timing_manager != null and timing_manager.get_current_timing() != TimingManager.TIMING_PUCK_PUCK:
			break


func step_positions(delta: float) -> void:
	if delta <= 0.0:
		return
	for puck in _get_pucks():
		if puck.is_dead:
			continue
		var horiz_sq := puck.velocity.x * puck.velocity.x + puck.velocity.z * puck.velocity.z
		if horiz_sq > 0.000001:
			puck.global_position.x += puck.velocity.x * delta
			puck.global_position.z += puck.velocity.z * delta
			_clamp_inside_table_bounds(puck)
		puck.apply_table_physics(delta)
		if absf(puck.velocity.y) > 0.0001:
			puck.global_position.y += puck.velocity.y * delta
			var table := battlefield
			var over_pocket := table != null and table.is_pocket_at_world(puck.global_position)
			var floor_y := Battlefield.TABLE_TOP_Y + 0.25
			if not over_pocket and puck.global_position.y <= floor_y and puck.velocity.y < 0.0:
				puck.global_position.y = floor_y
				puck.velocity.y = 0.0


func step_velocities(tick_dt: float = TICK_INTERVAL) -> void:
	if tick_dt <= 0.0:
		return
	_resolve_references()
	for puck in _get_pucks():
		if puck.is_dead:
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
			block.apply_ground_effect(puck, tick_dt)
		else:
			var speed := horiz.length()
			if speed <= tick_dt or (speed - tick_dt) < STOP_SPEED_THRESHOLD:
				puck.velocity.x = 0.0
				puck.velocity.z = 0.0
			else:
				var dir := horiz.normalized()
				puck.velocity.x -= dir.x * tick_dt
				puck.velocity.z -= dir.y * tick_dt

	if are_all_pucks_at_rest():
		all_pucks_at_rest.emit()
		if timing_manager != null and timing_manager.get_current_timing() == TimingManager.TIMING_PUCK_PUCK:
			timing_manager.notify_all_pucks_at_rest()


func are_all_pucks_at_rest() -> bool:
	for puck in _get_pucks():
		if puck.is_dead:
			continue
		if Vector2(puck.velocity.x, puck.velocity.z).length() > STOP_SPEED_THRESHOLD:
			return false
	return true


func _clamp_inside_table_bounds(puck: BasePuck) -> void:
	var r := maxf(puck.radius, 0.2)
	var max_x := Battlefield.TABLE_HALF_X - r
	var max_z := Battlefield.TABLE_HALF_Z - r
	if puck.global_position.x < -max_x:
		puck.global_position.x = -max_x
		if puck.velocity.x < 0.0:
			puck.velocity.x = -puck.velocity.x * puck.restitution
	elif puck.global_position.x > max_x:
		puck.global_position.x = max_x
		if puck.velocity.x > 0.0:
			puck.velocity.x = -puck.velocity.x * puck.restitution
	if puck.global_position.z < -max_z:
		puck.global_position.z = -max_z
		if puck.velocity.z < 0.0:
			puck.velocity.z = -puck.velocity.z * puck.restitution
	elif puck.global_position.z > max_z:
		puck.global_position.z = max_z
		if puck.velocity.z > 0.0:
			puck.velocity.z = -puck.velocity.z * puck.restitution


func _get_pucks() -> Array[BasePuck]:
	var list: Array[BasePuck] = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("pucks"):
			if node is BasePuck and is_instance_valid(node):
				list.append(node as BasePuck)
		return list
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is BasePuck:
				list.append(child as BasePuck)
	return list
