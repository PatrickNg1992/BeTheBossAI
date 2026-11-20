class_name CueShotManager
extends Node

## Manages Drag-and-Shot input, 0.5-slot Energy quantization (1.0..9.0),
## live TimeBoard Energy consume/over-drag preview, 3D arrowed aiming line at
## Y = 1.55 with swept Boss-radius first-rebound and struck-puck arrows,
## cancellation sound, and mass-dependent Impulse launch (J = k * E).
## Strictly gated to Play Time (and all pucks at rest) via TimingManager signals.

signal drag_updated(required_energy: float, shot_direction: Vector3, in_deadzone: bool, overdragged: bool)
signal shot_cancelled()
signal shot_launched(spent_energy: float, shot_direction: Vector3)

const MIN_SHOT_ENERGY := 1.0
const MAX_SHOT_ENERGY := 9.0
const ENERGY_STEP := 0.5
const TABLE_PLANE_Y := 1.5
const AIM_LINE_Y := 1.55

@export var deadzone_radius: float = 0.65
@export var drag_distance_per_energy: float = 1.0
@export var boss_click_radius: float = 1.25
@export var impulse_per_energy: float = 7.2
@export var aim_length_per_impulse: float = 0.45
@export var post_hit_length_per_speed: float = 0.50
@export var aim_valid_color: Color = Color(1.0, 0.88, 0.28, 0.95)
@export var aim_struck_puck_color: Color = Color(0.28, 0.88, 1.0, 0.95)
@export var aim_invalid_color: Color = Color(0.95, 0.20, 0.18, 0.95)

var battlefield: Battlefield = null
var timing_manager: TimingManager = null
var velocity_manager: PuckVelocityManager = null
var time_board: TimeBoard = null
var boss_puck: Node3D = null
var cancel_sound_play_count: int = 0

var _in_play_time: bool = false
var _clock_paused: bool = false
var _dragging: bool = false
var _remote_aiming: bool = false
var _remote_aim_origin: Vector3 = Vector3.ZERO
var _remote_overdragged: bool = false
var _remote_player_seat: String = ""
var _in_deadzone: bool = true
var _required_energy: float = 0.0
var _shot_direction: Vector3 = Vector3.ZERO
var _aim_line_state: Dictionary = {}

var _aim_mesh_instance: MeshInstance3D = null
var _aim_immediate_mesh: ImmediateMesh = null
var _aim_material: StandardMaterial3D = null
var _cancel_audio: AudioStreamPlayer = null


func _ready() -> void:
	_reset_aim_line_state()
	_resolve_references()
	_bind_timing_signals()
	_setup_aim_visuals()
	_setup_cancel_audio()


func _exit_tree() -> void:
	if _aim_mesh_instance != null and is_instance_valid(_aim_mesh_instance):
		_aim_mesh_instance.queue_free()
	_aim_mesh_instance = null


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
	if velocity_manager == null and parent != null:
		velocity_manager = parent.get_node_or_null("PuckVelocityManager") as PuckVelocityManager
	if velocity_manager == null and is_inside_tree():
		velocity_manager = get_tree().get_first_node_in_group("puck_velocity_manager") as PuckVelocityManager
	if time_board == null and parent != null:
		time_board = parent.get_node_or_null("%TimeBoard") as TimeBoard
		if time_board == null:
			time_board = parent.get_node_or_null("Canvas/TimeBoard") as TimeBoard
	if boss_puck == null and parent != null:
		boss_puck = parent.get_node_or_null("Player") as Node3D
	if boss_puck == null and is_inside_tree():
		boss_puck = get_tree().get_first_node_in_group("player") as Node3D


func _bind_timing_signals() -> void:
	if timing_manager == null:
		return
	if not timing_manager.timing_changed.is_connected(_on_timing_changed):
		timing_manager.timing_changed.connect(_on_timing_changed)
	if not timing_manager.pause_changed.is_connected(_on_pause_changed):
		timing_manager.pause_changed.connect(_on_pause_changed)
	_in_play_time = timing_manager.get_current_timing() == TimingManager.TIMING_PLAY
	_clock_paused = timing_manager.is_paused()


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	_in_play_time = new_timing == TimingManager.TIMING_PLAY
	if not _in_play_time:
		if _dragging:
			cancel_drag(false)
		elif _remote_aiming:
			apply_synced_aiming({"active": false})


func _on_pause_changed(paused: bool) -> void:
	_clock_paused = paused
	if _clock_paused and _dragging:
		cancel_drag(false)


func can_aim() -> bool:
	_resolve_references()
	if timing_manager != null:
		_in_play_time = timing_manager.get_current_timing() == TimingManager.TIMING_PLAY
		_clock_paused = timing_manager.is_paused()
	if not _in_play_time or _clock_paused:
		return false
	var parent := get_parent()
	if parent != null and parent.has_method("get_local_role") and "active_player" in parent:
		var my_role := str(parent.call("get_local_role"))
		var act := str(parent.get("active_player"))
		if my_role != "a" and my_role != "b":
			return false
		if not act.is_empty() and act != my_role:
			return false
	if velocity_manager != null and not velocity_manager.are_all_pucks_at_rest():
		return false
	return true


func is_dragging() -> bool:
	return _dragging


func is_in_deadzone() -> bool:
	return _in_deadzone


func is_overdragged() -> bool:
	if timing_manager == null:
		return false
	return _required_energy > _get_owned_energy() + 0.0001


func _get_owned_energy() -> float:
	if timing_manager == null:
		return 0.0
	var seat := _get_aiming_seat()
	return timing_manager.get_player_energy(seat)


func _get_aiming_seat() -> String:
	var parent := get_parent()
	if parent != null and parent.has_method("get_local_role"):
		var role := str(parent.call("get_local_role"))
		if role == "a" or role == "b":
			return role
	if time_board != null and time_board.has_method("get_perspective_role"):
		var p_role := str(time_board.get_perspective_role())
		if p_role == "a" or p_role == "b":
			return p_role
	return "a"


func get_required_energy() -> float:
	return _required_energy


func get_shot_direction() -> Vector3:
	return _shot_direction


func get_selected_impulse() -> float:
	if _in_deadzone or _required_energy < MIN_SHOT_ENERGY:
		return 0.0
	return impulse_per_energy * _required_energy


func get_aim_line_state() -> Dictionary:
	return _aim_line_state.duplicate(true)


func begin_drag(world_point: Vector3) -> bool:
	if not can_aim():
		return false
	var origin := _boss_origin()
	var flat_offset := Vector3(world_point.x - origin.x, 0.0, world_point.z - origin.z)
	if flat_offset.length() > boss_click_radius:
		return false
	_dragging = true
	_remote_aiming = false
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3(0.0, 0.0, -1.0)
	_update_board_preview(0.0)
	_update_aim_line_visuals()
	_notify_host_aim_update(true, MpTransport.UNRELIABLE_ORDERED)
	return true


func update_drag(world_point: Vector3) -> void:
	if not _dragging or not can_aim():
		return
	var origin := _boss_origin()
	var drag_vec := Vector3(world_point.x - origin.x, 0.0, world_point.z - origin.z)
	var dist := drag_vec.length()
	if dist > 0.0001:
		_shot_direction = (-drag_vec / dist).normalized()
	else:
		_shot_direction = Vector3(0.0, 0.0, -1.0)
	if dist <= deadzone_radius or dist <= 0.0001:
		_in_deadzone = true
		_required_energy = 0.0
		_update_board_preview(0.0, "", true)
		_update_aim_line_visuals()
		_notify_host_aim_update(true, MpTransport.UNRELIABLE_ORDERED)
		drag_updated.emit(0.0, Vector3.ZERO, true, false)
		return
	_in_deadzone = false
	var raw_units := (dist - deadzone_radius) / maxf(drag_distance_per_energy, 0.0001)
	var quantized := MIN_SHOT_ENERGY + floorf(raw_units / ENERGY_STEP + 0.0001) * ENERGY_STEP
	_required_energy = clampf(snappedf(quantized, ENERGY_STEP), MIN_SHOT_ENERGY, MAX_SHOT_ENERGY)
	_update_board_preview(_required_energy)
	_update_aim_line_visuals()
	_notify_host_aim_update(true, MpTransport.UNRELIABLE_ORDERED)
	drag_updated.emit(_required_energy, _shot_direction, false, is_overdragged())


func release_drag() -> bool:
	if not _dragging:
		return false
	if not can_aim() or _in_deadzone or is_overdragged() or _required_energy < MIN_SHOT_ENERGY:
		cancel_drag(true)
		return false
	var spent := _required_energy
	var dir := _shot_direction
	var impulse_mag := impulse_per_energy * spent
	_dragging = false
	_remote_aiming = false
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3.ZERO
	_update_board_preview(0.0)
	_hide_aim_line_visuals()
	var parent := get_parent()
	if parent != null and parent.has_method("action_cue_shot"):
		parent.call("action_cue_shot", dir, spent)
	else:
		_notify_host_aim_update(false, MpTransport.RELIABLE)
		if boss_puck is BasePuck:
			(boss_puck as BasePuck).apply_impulse(dir * impulse_mag)
		if timing_manager != null:
			var seat := _get_aiming_seat()
			if seat == "b":
				timing_manager.consume_player_energy("b", spent)
				timing_manager.fire_cue_shot(0.0)
			else:
				timing_manager.fire_cue_shot(spent)
	shot_launched.emit(spent, dir)
	return true


func cancel_drag(play_sound: bool = true) -> void:
	var was_dragging := _dragging
	_dragging = false
	_remote_aiming = false
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3.ZERO
	_update_board_preview(0.0)
	_hide_aim_line_visuals()
	if was_dragging:
		_notify_host_aim_update(false, MpTransport.RELIABLE)
		if play_sound:
			_play_cancel_sound()
		shot_cancelled.emit()


func _notify_host_aim_update(active: bool, transfer_mode: int) -> void:
	var parent := get_parent()
	if parent == null or not parent.has_method("action_aim_update"):
		return
	var payload := {
		"active": active,
		"player_seat": _get_aiming_seat(),
		"aim_origin": _boss_origin(),
		"aim_direction": _shot_direction,
		"energy_cost": _required_energy if active else 0.0,
		"in_deadzone": _in_deadzone if active else false,
		"over_dragged": is_overdragged() if active else false,
	}
	parent.call("action_aim_update", payload, transfer_mode)


## Renders or clears the live 3D aiming line and Time Board Energy cost preview
## received from the Host's `sync_aiming()` broadcast.
func apply_synced_aiming(payload: Dictionary) -> void:
	var active := bool(payload.get("active", false))
	if not active:
		if not _dragging:
			_remote_aiming = false
			_in_deadzone = true
			_required_energy = 0.0
			_shot_direction = Vector3.ZERO
			_update_board_preview(0.0)
			_hide_aim_line_visuals()
		return
	if _dragging:
		# Local active_player is already rendering their own drag in real time.
		return
	_remote_aiming = true
	_remote_player_seat = str(payload.get("player_seat", "a"))
	_remote_aim_origin = payload.get("aim_origin", _boss_origin()) as Vector3
	_shot_direction = payload.get("aim_direction", Vector3(0.0, 0.0, -1.0)) as Vector3
	_required_energy = float(payload.get("energy_cost", 0.0))
	_in_deadzone = bool(payload.get("in_deadzone", _required_energy < MIN_SHOT_ENERGY))
	_remote_overdragged = bool(payload.get("over_dragged", false))
	_update_board_preview(_required_energy, _remote_player_seat, _in_deadzone)
	_update_aim_line_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if not can_aim():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _try_begin_drag_from_screen(mb.position):
					return
			elif _dragging:
				release_drag()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and _dragging:
			cancel_drag(true)
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var hit := _raycast_table_plane(mm.position)
		if hit.get("valid", false):
			update_drag(hit["point"])


func _try_begin_drag_from_screen(screen_pos: Vector2) -> bool:
	var origin := _boss_origin()
	var hit_boss := _raycast_horizontal_plane(screen_pos, origin.y)
	if hit_boss.get("valid", false):
		if begin_drag(hit_boss["point"]):
			return true
	var hit_table := _raycast_table_plane(screen_pos)
	if hit_table.get("valid", false):
		if begin_drag(hit_table["point"]):
			return true
	return false


func _raycast_table_plane(screen_pos: Vector2) -> Dictionary:
	return _raycast_horizontal_plane(screen_pos, TABLE_PLANE_Y)


func _raycast_horizontal_plane(screen_pos: Vector2, plane_y: float) -> Dictionary:
	var viewport := get_viewport()
	if viewport == null:
		return {"valid": false}
	var camera := viewport.get_camera_3d()
	if camera == null:
		return {"valid": false}
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return {"valid": false}
	var t := (plane_y - from.y) / dir.y
	if t < 0.0:
		return {"valid": false}
	return {"valid": true, "point": from + dir * t}


func _boss_origin() -> Vector3:
	if boss_puck != null and is_instance_valid(boss_puck):
		return boss_puck.global_position
	return Vector3.ZERO


func _boss_radius() -> float:
	if boss_puck is BasePuck:
		return maxf((boss_puck as BasePuck).radius, 0.2)
	return 0.75


func _boss_mass() -> float:
	if boss_puck is BasePuck:
		return maxf((boss_puck as BasePuck).mass, 0.1)
	return 3.0


func _boss_restitution() -> float:
	if boss_puck is BasePuck:
		return clampf((boss_puck as BasePuck).restitution, 0.0, 1.0)
	return 0.85


func _update_board_preview(cost: float, player_seat: String = "", in_deadzone: bool = false) -> void:
	if time_board != null and is_instance_valid(time_board):
		var seat := player_seat if not player_seat.is_empty() else _get_aiming_seat()
		time_board.set_preview_cost(cost, seat, in_deadzone)


func _setup_aim_visuals() -> void:
	_aim_immediate_mesh = ImmediateMesh.new()
	_aim_material = StandardMaterial3D.new()
	_aim_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aim_material.vertex_color_use_as_albedo = true
	_aim_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aim_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_aim_mesh_instance = MeshInstance3D.new()
	_aim_mesh_instance.name = "AimingLine3D"
	_aim_mesh_instance.mesh = _aim_immediate_mesh
	_aim_mesh_instance.material_override = _aim_material
	_aim_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aim_mesh_instance.visible = false
	var parent := get_parent()
	if parent is Node3D:
		parent.call_deferred("add_child", _aim_mesh_instance)
	else:
		add_child(_aim_mesh_instance)


## Sweeps the Boss Monster's radius R_boss along `dir` up to `max_reach` and
## finds the earliest Cushion or Puck hit, computing v1f and v2f using the
## ticket-03 collision equations.
func _predict_first_hit(origin: Vector3, dir: Vector3, max_reach: float, impulse_val: float) -> Dictionary:
	var r_boss := _boss_radius()
	var m_boss := _boss_mass()
	var e_boss := _boss_restitution()
	var v0 := dir * (impulse_val / m_boss)
	var start_xz := Vector2(origin.x, origin.z)
	var dir_xz := Vector2(dir.x, dir.z).normalized()

	var best_dist := max_reach
	var hit_type := "none"
	var hit_puck: BasePuck = null
	var hit_cushion_normal := Vector3.ZERO

	# 1. Check swept circle against all other Pucks
	for puck in _get_other_pucks():
		var r_other := maxf(puck.radius, 0.2)
		var combined_r := r_boss + r_other
		var to_other := Vector2(puck.global_position.x, puck.global_position.z) - start_xz
		var proj := to_other.dot(dir_xz)
		if proj <= 0.0:
			continue
		var perp_sq := to_other.length_squared() - proj * proj
		var r_sq := combined_r * combined_r
		if perp_sq >= r_sq:
			continue
		var thc := sqrt(maxf(0.0, r_sq - perp_sq))
		var t_hit := proj - thc
		if t_hit >= 0.0 and t_hit <= best_dist + 0.0001:
			best_dist = t_hit
			hit_type = "puck"
			hit_puck = puck
			hit_cushion_normal = Vector3.ZERO

	# 2. Check swept circle against Cushion inner planes (x = +- (15 - R_boss), z = +- (10 - R_boss))
	var max_x := Battlefield.TABLE_HALF_X - r_boss
	var max_z := Battlefield.TABLE_HALF_Z - r_boss
	if dir_xz.x > 0.0001:
		var tx := (max_x - start_xz.x) / dir_xz.x
		if tx >= 0.0 and tx < best_dist - 0.0001:
			best_dist = tx
			hit_type = "cushion"
			hit_puck = null
			hit_cushion_normal = Vector3(-1.0, 0.0, 0.0)
	elif dir_xz.x < -0.0001:
		var tx := (-max_x - start_xz.x) / dir_xz.x
		if tx >= 0.0 and tx < best_dist - 0.0001:
			best_dist = tx
			hit_type = "cushion"
			hit_puck = null
			hit_cushion_normal = Vector3(1.0, 0.0, 0.0)

	if dir_xz.y > 0.0001:
		var tz := (max_z - start_xz.y) / dir_xz.y
		if tz >= 0.0 and tz < best_dist - 0.0001:
			best_dist = tz
			hit_type = "cushion"
			hit_puck = null
			hit_cushion_normal = Vector3(0.0, 0.0, -1.0)
	elif dir_xz.y < -0.0001:
		var tz := (-max_z - start_xz.y) / dir_xz.y
		if tz >= 0.0 and tz < best_dist - 0.0001:
			best_dist = tz
			hit_type = "cushion"
			hit_puck = null
			hit_cushion_normal = Vector3(0.0, 0.0, 1.0)

	var contact_center := Vector3(
		origin.x + dir.x * best_dist,
		AIM_LINE_Y,
		origin.z + dir.z * best_dist
	)

	if hit_type == "puck" and hit_puck != null:
		var p2_pos := Vector3(hit_puck.global_position.x, AIM_LINE_Y, hit_puck.global_position.z)
		var n := (contact_center - p2_pos)
		n.y = 0.0
		n = n.normalized() if n.length_squared() > 0.0001 else -dir
		var v_rel := v0.dot(n)
		var e := clampf(minf(e_boss, hit_puck.restitution), 0.0, 1.0)
		var inv_m1 := 1.0 / m_boss
		var inv_m2 := 1.0 / maxf(hit_puck.mass, 0.1)
		var j_mag := -(1.0 + e) * v_rel / (inv_m1 + inv_m2)
		var v1f := v0 + n * (j_mag * inv_m1)
		var v2f := -n * (j_mag * inv_m2)
		return {
			"hit_type": "puck",
			"primary_length": best_dist,
			"has_contact_ring": true,
			"contact_center": contact_center,
			"contact_ring_radius": r_boss,
			"v1f": v1f,
			"v2f": v2f,
			"rebound_length": v1f.length() * post_hit_length_per_speed,
			"has_struck_puck_arrow": v2f.length() > 0.001,
			"struck_puck_center": p2_pos,
			"struck_puck_length": v2f.length() * post_hit_length_per_speed,
		}
	elif hit_type == "cushion":
		var v1f := Vector3.ZERO
		if battlefield != null:
			var cush := battlefield.get_cushion_block_for_normal(contact_center, hit_cushion_normal)
			if cush != null:
				v1f = cush.compute_rebound_velocity(v0, hit_cushion_normal)
		if v1f.length_squared() <= 0.0001:
			var v_dot_n := v0.dot(hit_cushion_normal)
			var v_perp := v_dot_n * hit_cushion_normal
			var v_par := v0 - v_perp
			v1f = 0.9 * v_par - e_boss * v_perp
		return {
			"hit_type": "cushion",
			"primary_length": best_dist,
			"has_contact_ring": true,
			"contact_center": contact_center,
			"contact_ring_radius": r_boss,
			"v1f": v1f,
			"v2f": Vector3.ZERO,
			"rebound_length": v1f.length() * post_hit_length_per_speed,
			"has_struck_puck_arrow": false,
			"struck_puck_center": Vector3.ZERO,
			"struck_puck_length": 0.0,
		}

	return {
		"hit_type": "none",
		"primary_length": max_reach,
		"has_contact_ring": false,
		"contact_center": contact_center,
		"contact_ring_radius": r_boss,
		"v1f": Vector3.ZERO,
		"v2f": Vector3.ZERO,
		"rebound_length": 0.0,
		"has_struck_puck_arrow": false,
		"struck_puck_center": Vector3.ZERO,
		"struck_puck_length": 0.0,
	}


func _get_other_pucks() -> Array[BasePuck]:
	var list: Array[BasePuck] = []
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is BasePuck and child != boss_puck and is_instance_valid(child) and not (child as BasePuck).is_dead:
				list.append(child as BasePuck)
		if not list.is_empty():
			return list
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("pucks"):
			if node is BasePuck and node != boss_puck and is_instance_valid(node) and not (node as BasePuck).is_dead:
				list.append(node as BasePuck)
	return list


func _update_aim_line_visuals() -> void:
	_resolve_references()
	var is_active_aim := _dragging or _remote_aiming
	var is_over := _remote_overdragged if _remote_aiming else is_overdragged()
	var is_red := _in_deadzone or is_over
	var impulse_val := get_selected_impulse()
	var max_reach := impulse_val * aim_length_per_impulse if not _in_deadzone else deadzone_radius * 1.35
	var dir := _shot_direction if _shot_direction.length_squared() > 0.0001 else Vector3(0.0, 0.0, -1.0)
	var origin := _remote_aim_origin if _remote_aiming else _boss_origin()

	var pred: Dictionary
	if _in_deadzone or impulse_val <= 0.0001:
		pred = {
			"hit_type": "none",
			"primary_length": max_reach,
			"has_contact_ring": false,
			"contact_center": Vector3(origin.x, AIM_LINE_Y, origin.z) + dir * max_reach,
			"contact_ring_radius": _boss_radius(),
			"v1f": Vector3.ZERO,
			"v2f": Vector3.ZERO,
			"rebound_length": 0.0,
			"has_struck_puck_arrow": false,
			"struck_puck_center": Vector3.ZERO,
			"struck_puck_length": 0.0,
		}
	else:
		pred = _predict_first_hit(origin, dir, max_reach, impulse_val)

	var primary_col := aim_invalid_color if is_red else aim_valid_color
	var struck_col := aim_invalid_color if is_red else aim_struck_puck_color

	_aim_line_state = {
		"visible": is_active_aim,
		"y": AIM_LINE_Y,
		"length": max_reach,
		"primary_length": pred["primary_length"],
		"impulse": impulse_val,
		"direction": dir,
		"is_invalid_red": is_red,
		"hit_type": pred["hit_type"],
		"has_contact_ring": pred["has_contact_ring"],
		"contact_center": pred["contact_center"],
		"contact_ring_radius": pred["contact_ring_radius"],
		"v1f": pred["v1f"],
		"v2f": pred["v2f"],
		"rebound_length": pred["rebound_length"],
		"has_struck_puck_arrow": pred["has_struck_puck_arrow"],
		"struck_puck_center": pred["struck_puck_center"],
		"struck_puck_length": pred["struck_puck_length"],
		"primary_color": primary_col,
		"struck_puck_color": struck_col,
	}

	if _aim_immediate_mesh == null or _aim_mesh_instance == null:
		return
	_aim_immediate_mesh.clear_surfaces()
	if not is_active_aim or max_reach <= 0.01:
		_aim_mesh_instance.visible = false
		return
	_aim_mesh_instance.visible = true

	var start := Vector3(origin.x, AIM_LINE_Y, origin.z)
	var primary_len: float = pred["primary_length"]

	_aim_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Primary aiming arrow (or line to contact center)
	if pred["has_contact_ring"]:
		_draw_segment_3d(start, start + dir * primary_len, 0.08, primary_col)
		_draw_ring_3d(pred["contact_center"], pred["contact_ring_radius"], 0.06, primary_col)
		var v1f: Vector3 = pred["v1f"]
		var reb_len: float = pred["rebound_length"]
		if v1f.length_squared() > 0.0001 and reb_len > 0.05:
			_draw_arrow_3d(pred["contact_center"], v1f.normalized(), reb_len, 0.075, primary_col)
		if pred["has_struck_puck_arrow"]:
			var v2f: Vector3 = pred["v2f"]
			var sp_len: float = pred["struck_puck_length"]
			if v2f.length_squared() > 0.0001 and sp_len > 0.05:
				_draw_arrow_3d(pred["struck_puck_center"], v2f.normalized(), sp_len, 0.075, struck_col)
	else:
		_draw_arrow_3d(start, dir, primary_len, 0.09, primary_col)

	_aim_immediate_mesh.surface_end()


func _draw_arrow_3d(start: Vector3, dir: Vector3, length: float, shaft_half_w: float, col: Color) -> void:
	if length <= 0.02:
		return
	var end := start + dir * length
	var right := Vector3(-dir.z, 0.0, dir.x).normalized()
	var head_len := minf(0.50, length * 0.38)
	var head_half_w := shaft_half_w * 2.8
	var shaft_end := end - dir * head_len

	_draw_segment_3d(start, shaft_end, shaft_half_w, col)

	_aim_immediate_mesh.surface_set_color(col)
	var h_left := shaft_end - right * head_half_w
	var h_right := shaft_end + right * head_half_w
	_aim_immediate_mesh.surface_add_vertex(h_left)
	_aim_immediate_mesh.surface_add_vertex(end)
	_aim_immediate_mesh.surface_add_vertex(h_right)


func _draw_segment_3d(start: Vector3, end: Vector3, half_w: float, col: Color) -> void:
	var seg := end - start
	seg.y = 0.0
	if seg.length_squared() <= 0.0001:
		return
	var dir := seg.normalized()
	var right := Vector3(-dir.z, 0.0, dir.x)
	_aim_immediate_mesh.surface_set_color(col)
	var s_tl := end - right * half_w
	var s_tr := end + right * half_w
	var s_bl := start - right * half_w
	var s_br := start + right * half_w
	_aim_immediate_mesh.surface_add_vertex(s_bl)
	_aim_immediate_mesh.surface_add_vertex(s_tl)
	_aim_immediate_mesh.surface_add_vertex(s_tr)
	_aim_immediate_mesh.surface_add_vertex(s_bl)
	_aim_immediate_mesh.surface_add_vertex(s_tr)
	_aim_immediate_mesh.surface_add_vertex(s_br)


func _draw_ring_3d(center: Vector3, radius: float, thickness: float, col: Color, segments: int = 24) -> void:
	var inner_r := maxf(0.05, radius - thickness * 0.5)
	var outer_r := radius + thickness * 0.5
	_aim_immediate_mesh.surface_set_color(col)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var p0_in := center + d0 * inner_r
		var p0_out := center + d0 * outer_r
		var p1_in := center + d1 * inner_r
		var p1_out := center + d1 * outer_r
		_aim_immediate_mesh.surface_add_vertex(p0_in)
		_aim_immediate_mesh.surface_add_vertex(p0_out)
		_aim_immediate_mesh.surface_add_vertex(p1_out)
		_aim_immediate_mesh.surface_add_vertex(p0_in)
		_aim_immediate_mesh.surface_add_vertex(p1_out)
		_aim_immediate_mesh.surface_add_vertex(p1_in)


func _reset_aim_line_state() -> void:
	_aim_line_state = {
		"visible": false,
		"y": AIM_LINE_Y,
		"length": 0.0,
		"primary_length": 0.0,
		"impulse": 0.0,
		"direction": Vector3.ZERO,
		"is_invalid_red": false,
		"hit_type": "none",
		"has_contact_ring": false,
		"contact_center": Vector3.ZERO,
		"contact_ring_radius": 0.0,
		"v1f": Vector3.ZERO,
		"v2f": Vector3.ZERO,
		"rebound_length": 0.0,
		"has_struck_puck_arrow": false,
		"struck_puck_center": Vector3.ZERO,
		"struck_puck_length": 0.0,
		"primary_color": aim_valid_color,
		"struck_puck_color": aim_struck_puck_color,
	}


func _hide_aim_line_visuals() -> void:
	_reset_aim_line_state()
	if _aim_immediate_mesh != null:
		_aim_immediate_mesh.clear_surfaces()
	if _aim_mesh_instance != null:
		_aim_mesh_instance.visible = false


func _setup_cancel_audio() -> void:
	_cancel_audio = AudioStreamPlayer.new()
	_cancel_audio.name = "CancelSoundPlayer"
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.15
	_cancel_audio.stream = gen
	add_child(_cancel_audio)


func _play_cancel_sound() -> void:
	cancel_sound_play_count += 1
	if _cancel_audio == null or not is_inside_tree():
		return
	_cancel_audio.play()
	var playback := _cancel_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := mini(playback.get_frames_available(), 2200)
	for i in range(frames):
		var t := float(i) / 22050.0
		var freq := lerpf(320.0, 170.0, float(i) / float(maxi(frames, 1)))
		var env := (1.0 - float(i) / float(maxi(frames, 1))) * 0.25
		var sample := sin(TAU * freq * t) * env
		playback.push_frame(Vector2(sample, sample))
