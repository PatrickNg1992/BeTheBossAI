class_name CueShotManager
extends Node

## Manages Drag-and-Shot input, 0.5-slot Energy quantization (1.0..9.0),
## live TimeBoard Energy consume/over-drag preview, 3D arrowed aiming line at
## Y = 1.55, cancellation sound, and mass-dependent Impulse launch (J = k * E).
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
@export var impulse_per_energy: float = 6.0
@export var aim_length_per_impulse: float = 0.45
@export var aim_valid_color: Color = Color(1.0, 0.88, 0.28, 0.95)
@export var aim_invalid_color: Color = Color(0.95, 0.20, 0.18, 0.95)

var timing_manager: TimingManager = null
var velocity_manager: PuckVelocityManager = null
var time_board: TimeBoard = null
var boss_puck: Node3D = null
var cancel_sound_play_count: int = 0

var _in_play_time: bool = false
var _clock_paused: bool = false
var _dragging: bool = false
var _in_deadzone: bool = true
var _required_energy: float = 0.0
var _shot_direction: Vector3 = Vector3.ZERO
var _aim_line_state: Dictionary = {
	"visible": false,
	"y": AIM_LINE_Y,
	"length": 0.0,
	"impulse": 0.0,
	"direction": Vector3.ZERO,
	"is_invalid_red": false,
}

var _aim_mesh_instance: MeshInstance3D = null
var _aim_immediate_mesh: ImmediateMesh = null
var _aim_material: StandardMaterial3D = null
var _cancel_audio: AudioStreamPlayer = null


func _ready() -> void:
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
	if not _in_play_time and _dragging:
		cancel_drag(false)


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
	return _required_energy > timing_manager.get_energy() + 0.0001


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
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3(0.0, 0.0, -1.0)
	_update_board_preview(0.0)
	_update_aim_line_visuals()
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
		_update_board_preview(0.0)
		_update_aim_line_visuals()
		drag_updated.emit(0.0, Vector3.ZERO, true, false)
		return
	_in_deadzone = false
	var raw_units := (dist - deadzone_radius) / maxf(drag_distance_per_energy, 0.0001)
	var quantized := MIN_SHOT_ENERGY + floorf(raw_units / ENERGY_STEP + 0.0001) * ENERGY_STEP
	_required_energy = clampf(snappedf(quantized, ENERGY_STEP), MIN_SHOT_ENERGY, MAX_SHOT_ENERGY)
	_update_board_preview(_required_energy)
	_update_aim_line_visuals()
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
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3.ZERO
	_update_board_preview(0.0)
	_hide_aim_line_visuals()
	if boss_puck is BasePuck:
		(boss_puck as BasePuck).apply_impulse(dir * impulse_mag)
	if timing_manager != null:
		timing_manager.fire_cue_shot(spent)
	shot_launched.emit(spent, dir)
	return true


func cancel_drag(play_sound: bool = true) -> void:
	var was_dragging := _dragging
	_dragging = false
	_in_deadzone = true
	_required_energy = 0.0
	_shot_direction = Vector3.ZERO
	_update_board_preview(0.0)
	_hide_aim_line_visuals()
	if was_dragging:
		if play_sound:
			_play_cancel_sound()
		shot_cancelled.emit()


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


func _update_board_preview(cost: float) -> void:
	if time_board != null and is_instance_valid(time_board):
		time_board.set_preview_cost(cost)


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


func _update_aim_line_visuals() -> void:
	var is_red := _in_deadzone or is_overdragged()
	var impulse_val := get_selected_impulse()
	var line_len := impulse_val * aim_length_per_impulse if not _in_deadzone else deadzone_radius * 1.35
	var dir := _shot_direction if _shot_direction.length_squared() > 0.0001 else Vector3(0.0, 0.0, -1.0)
	_aim_line_state = {
		"visible": _dragging,
		"y": AIM_LINE_Y,
		"length": line_len,
		"impulse": impulse_val,
		"direction": dir,
		"is_invalid_red": is_red,
	}
	if _aim_immediate_mesh == null or _aim_mesh_instance == null:
		return
	_aim_immediate_mesh.clear_surfaces()
	if not _dragging or line_len <= 0.01:
		_aim_mesh_instance.visible = false
		return
	_aim_mesh_instance.visible = true
	var col := aim_invalid_color if is_red else aim_valid_color
	var origin := _boss_origin()
	var start := Vector3(origin.x, AIM_LINE_Y, origin.z)
	var end := start + dir * line_len
	var right := Vector3(-dir.z, 0.0, dir.x).normalized()

	var shaft_half_w := 0.09
	var head_len := minf(0.55, line_len * 0.38)
	var head_half_w := 0.26
	var shaft_end := end - dir * head_len

	_aim_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_aim_immediate_mesh.surface_set_color(col)

	# Shaft quad (2 triangles)
	var s_tl := shaft_end - right * shaft_half_w
	var s_tr := shaft_end + right * shaft_half_w
	var s_bl := start - right * shaft_half_w
	var s_br := start + right * shaft_half_w
	_aim_immediate_mesh.surface_add_vertex(s_bl)
	_aim_immediate_mesh.surface_add_vertex(s_tl)
	_aim_immediate_mesh.surface_add_vertex(s_tr)
	_aim_immediate_mesh.surface_add_vertex(s_bl)
	_aim_immediate_mesh.surface_add_vertex(s_tr)
	_aim_immediate_mesh.surface_add_vertex(s_br)

	# Arrowhead triangle
	var h_left := shaft_end - right * head_half_w
	var h_right := shaft_end + right * head_half_w
	_aim_immediate_mesh.surface_add_vertex(h_left)
	_aim_immediate_mesh.surface_add_vertex(end)
	_aim_immediate_mesh.surface_add_vertex(h_right)

	_aim_immediate_mesh.surface_end()


func _hide_aim_line_visuals() -> void:
	_aim_line_state = {
		"visible": false,
		"y": AIM_LINE_Y,
		"length": 0.0,
		"impulse": 0.0,
		"direction": Vector3.ZERO,
		"is_invalid_red": false,
	}
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
