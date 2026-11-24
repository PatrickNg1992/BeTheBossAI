class_name BasePuck
extends CharacterBody3D

signal health_changed(current_hp: int, max_hp: int)
signal died()

const TABLE_GRAVITY: float = PhysicsConstant.TABLE_GRAVITY

@export var move_speed: float = 3.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.0
@export var mass: float = 1.0
@export var radius: float = 0.5
@export var restitution: float = PhysicsConstant.DEFAULT_PUCK_RESTITUTION

var is_dead: bool = false
var is_falling_in_pocket: bool = false
var _pocket_center: Vector3 = Vector3.ZERO
var _pocket_fall_elapsed: float = 0.0
var _pocket_tilt_axis: Vector3 = Vector3(1.0, 0.0, 0.0)
var _attack_timer: float = 0.0
var _unit_id: String = ""
var _reference_mark: String = ""
var _reference_mark_color: Color = Color(0.95, 0.85, 0.35, 1.0)
var _slot_color: Color = Color(0.5, 0.5, 0.5, 1.0)
var _ref_mark_label_3d: Label3D = null
var _has_team2_stripe: bool = false
var _team_x_stripe_mode: int = 0 # 0 = none (Boss), 1 = Team 1 White 4-side X stripe, 2 = Team 2 Black 4-side X stripe
var _free_slot_x_mode: int = 0 # 0 = none, 5 or 6 = Free/Extra grey circle behind Reference Mark letter (8-ball style)
var _stripes_root_3d: Node3D = null
var _is_highlighted: bool = false
var _highlight_ring_3d: MeshInstance3D = null
var _highlight_timer_token: int = 0
var collision_history: Array[Dictionary] = []
var _last_recorded_collision_puck: BasePuck = null


func record_collision(kind: String, target_unit_id: String = "", target_object: Variant = null) -> void:
	collision_history.append({
		"kind": kind,
		"target_unit_id": target_unit_id,
		"object": target_object,
	})


func get_collision_history() -> Array[Dictionary]:
	return collision_history.duplicate(true)


func clear_collision_history() -> void:
	collision_history.clear()
	_last_recorded_collision_puck = null


func is_first_puck_hit_in_turn(other_puck: BasePuck = null, other_unit_id: String = "") -> bool:
	var first_puck_entry: Dictionary = {}
	var puck_hit_count := 0
	for entry in collision_history:
		if str(entry.get("kind", "")) == "puck":
			puck_hit_count += 1
			if puck_hit_count == 1:
				first_puck_entry = entry
	if puck_hit_count == 0:
		return true
	if puck_hit_count != 1:
		return false
	if other_puck != null and first_puck_entry.get("object", null) == other_puck:
		return true
	if not other_unit_id.is_empty() and str(first_puck_entry.get("target_unit_id", "")) == other_unit_id:
		return true
	return false


func set_unit_id(uid: String) -> void:
	_unit_id = uid


func get_unit_id() -> String:
	return _unit_id


func set_reference_mark(mark: String, mark_color: Color = _reference_mark_color) -> void:
	_reference_mark = mark
	_reference_mark_color = mark_color
	_update_reference_mark_3d()


func get_reference_mark() -> String:
	return _reference_mark


func get_reference_mark_color() -> Color:
	return _reference_mark_color


func set_slot_color(col: Color) -> void:
	_slot_color = col
	_apply_slot_color_to_mesh()


func get_slot_color() -> Color:
	return _slot_color


func configure_puck_stripes(has_team2_stripe: bool, free_slot_x_mode: int = 0, team_x_mode: int = -1) -> void:
	_has_team2_stripe = has_team2_stripe
	_free_slot_x_mode = free_slot_x_mode
	if team_x_mode >= 0:
		_team_x_stripe_mode = team_x_mode
	else:
		_team_x_stripe_mode = 2 if has_team2_stripe else 1
	_update_puck_stripes_3d()


func has_team2_stripe() -> bool:
	return _has_team2_stripe


func get_team_x_stripe_mode() -> int:
	return _team_x_stripe_mode


func get_free_slot_x_mode() -> int:
	return _free_slot_x_mode


func has_free_slot_center_circle() -> bool:
	return _free_slot_x_mode == 5 or _free_slot_x_mode == 6


func flash_highlight(duration_sec: float = 1.0) -> void:
	_highlight_timer_token += 1
	var token := _highlight_timer_token
	set_highlighted(true)
	if is_inside_tree() and duration_sec > 0.0:
		get_tree().create_timer(duration_sec).timeout.connect(func() -> void:
			if is_instance_valid(self) and _highlight_timer_token == token:
				set_highlighted(false)
		)


func set_highlighted(highlighted: bool) -> void:
	_is_highlighted = highlighted
	_update_highlight_ring_3d()


func is_highlighted() -> bool:
	return _is_highlighted


func _update_highlight_ring_3d() -> void:
	if not _is_highlighted:
		if _highlight_ring_3d != null and is_instance_valid(_highlight_ring_3d):
			_highlight_ring_3d.visible = false
		return
	if _highlight_ring_3d == null or not is_instance_valid(_highlight_ring_3d):
		_highlight_ring_3d = get_node_or_null("HoverHighlightRing3D") as MeshInstance3D
		if _highlight_ring_3d == null:
			_highlight_ring_3d = MeshInstance3D.new()
			_highlight_ring_3d.name = "HoverHighlightRing3D"
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = Color(1.0, 0.94, 0.32, 0.96)
			ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_highlight_ring_3d.material_override = ring_mat
			add_child(_highlight_ring_3d)
	var cyl_r := maxf(radius, 0.5)
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		cyl_r = (col_shape.shape as CylinderShape3D).radius
	var torus := TorusMesh.new()
	torus.inner_radius = cyl_r + 0.04
	torus.outer_radius = cyl_r + 0.16
	_highlight_ring_3d.mesh = torus
	_highlight_ring_3d.position = Vector3(0.0, 0.02, 0.0)
	_highlight_ring_3d.visible = true


func _update_puck_stripes_3d() -> void:
	if _stripes_root_3d != null and is_instance_valid(_stripes_root_3d):
		remove_child(_stripes_root_3d)
		_stripes_root_3d.queue_free()
		_stripes_root_3d = null
	if _team_x_stripe_mode == 0 and _free_slot_x_mode == 0:
		return

	_stripes_root_3d = Node3D.new()
	_stripes_root_3d.name = "PuckStripes3D"
	add_child(_stripes_root_3d)

	var cyl_h := 0.35
	var cyl_r := maxf(radius, 0.5)
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		cyl_h = (col_shape.shape as CylinderShape3D).height
		cyl_r = (col_shape.shape as CylinderShape3D).radius

	var top_y := cyl_h * 0.5 + 0.015
	var tick_len := cyl_r * 0.36
	var tick_radial_center := cyl_r - tick_len * 0.5 + 0.015
	var tick_width := 0.145

	# 1. Team 4-sided X stripe (45, 135, 225, 315 deg):
	#    Team 1 (_team_x_stripe_mode == 1) = White 4-sided X stripe
	#    Team 2 (_team_x_stripe_mode == 2) = Black 4-sided X stripe
	if _team_x_stripe_mode == 1 or _team_x_stripe_mode == 2:
		var x_mat := StandardMaterial3D.new()
		if _team_x_stripe_mode == 1:
			x_mat.albedo_color = Color(0.98, 0.98, 0.99, 1.0)
		else:
			x_mat.albedo_color = Color(0.05, 0.04, 0.05, 1.0)
		x_mat.roughness = 0.25
		x_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for angle_deg in [45.0, 135.0, 225.0, 315.0]:
			_add_stripe_tick(_stripes_root_3d, angle_deg, tick_radial_center, top_y, cyl_h, tick_len, tick_width, x_mat)

	# 2. Free-position 8-ball style white circle behind the Reference Mark letter (slots 5 and 6: F/f and E/e)
	if has_free_slot_center_circle():
		var disc_mesh := CylinderMesh.new()
		var disc_r := cyl_r * 0.56
		disc_mesh.top_radius = disc_r
		disc_mesh.bottom_radius = disc_r
		disc_mesh.height = 0.022
		var disc_mat := StandardMaterial3D.new()
		disc_mat.albedo_color = Color(0.98, 0.98, 0.99, 1.0)
		disc_mat.roughness = 0.25
		disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var disc_inst := MeshInstance3D.new()
		disc_inst.name = "FreePositionCenterCircle3D"
		disc_inst.mesh = disc_mesh
		disc_inst.material_override = disc_mat
		disc_inst.position = Vector3(0.0, cyl_h * 0.5 + 0.014, 0.0)
		_stripes_root_3d.add_child(disc_inst)


func _add_stripe_tick(
	parent_node: Node3D,
	angle_deg: float,
	radial_center: float,
	top_y: float,
	cyl_h: float,
	tick_len: float,
	tick_width: float,
	mat: StandardMaterial3D
) -> void:
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(0.0, angle_deg, 0.0)
	parent_node.add_child(pivot)

	# Top surface radial stripe tick
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(tick_len, 0.025, tick_width)
	var top_inst := MeshInstance3D.new()
	top_inst.mesh = top_mesh
	top_inst.material_override = mat
	top_inst.position = Vector3(radial_center, top_y, 0.0)
	pivot.add_child(top_inst)

	# Outer cylinder wall vertical stripe tick
	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(0.045, cyl_h + 0.015, tick_width)
	var side_inst := MeshInstance3D.new()
	side_inst.mesh = side_mesh
	side_inst.material_override = mat
	side_inst.position = Vector3(radial_center + tick_len * 0.5, 0.0, 0.0)
	pivot.add_child(side_inst)


func _apply_slot_color_to_mesh() -> void:
	var mesh_node := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node == null:
		mesh_node = get_node_or_null("PuckMesh") as MeshInstance3D
	if mesh_node == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _slot_color
	mat.roughness = 0.55
	mat.metallic = 0.15
	mesh_node.material_override = mat


func _update_reference_mark_3d() -> void:
	if _reference_mark.is_empty():
		if _ref_mark_label_3d != null and is_instance_valid(_ref_mark_label_3d):
			_ref_mark_label_3d.visible = false
		return
	if _ref_mark_label_3d == null or not is_instance_valid(_ref_mark_label_3d):
		_ref_mark_label_3d = get_node_or_null("ReferenceMark3D") as Label3D
		if _ref_mark_label_3d == null:
			_ref_mark_label_3d = Label3D.new()
			_ref_mark_label_3d.name = "ReferenceMark3D"
			_ref_mark_label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			_ref_mark_label_3d.no_depth_test = false
			_ref_mark_label_3d.shaded = false
			_ref_mark_label_3d.double_sided = true
			_ref_mark_label_3d.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			add_child(_ref_mark_label_3d)
	var half_h := 0.22
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		half_h = (col_shape.shape as CylinderShape3D).height * 0.5 + 0.035
	var is_boss_mark := (_reference_mark == "Ω" or _reference_mark == "Ψ" or self is BaseBossMonster)
	var bold_font := SystemFont.new()
	bold_font.font_weight = 800
	_ref_mark_label_3d.font = bold_font
	_ref_mark_label_3d.font_size = 110 if is_boss_mark else 82
	_ref_mark_label_3d.pixel_size = 0.0092 if is_boss_mark else 0.0082
	# Same-color subtle stroke makes the letter extra bold without any white/contrasting halo
	_ref_mark_label_3d.outline_size = 6
	_ref_mark_label_3d.outline_modulate = _reference_mark_color
	_ref_mark_label_3d.position = Vector3(0.0, half_h, 0.0)
	_ref_mark_label_3d.text = _reference_mark
	_ref_mark_label_3d.modulate = _reference_mark_color
	_ref_mark_label_3d.visible = true


func _ready() -> void:
	add_to_group("pucks")
	collision_mask = 3
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		radius = (col_shape.shape as CylinderShape3D).radius
	if not _reference_mark.is_empty():
		_update_reference_mark_3d()
	if _slot_color != Color(0.5, 0.5, 0.5, 1.0):
		_apply_slot_color_to_mesh()
	if _team_x_stripe_mode != 0 or _free_slot_x_mode != 0:
		_update_puck_stripes_3d()


func apply_impulse(impulse: Vector3) -> void:
	if is_dead:
		return
	var safe_mass := maxf(mass, 0.0001)
	velocity.x += impulse.x / safe_mass
	velocity.z += impulse.z / safe_mass


## Continuous force application over dt, scaled by fast_play_ratio:
##   dv = (F / m) * (dt * fast_play_ratio)
func apply_force(force: Vector3, dt: float, fast_play_ratio: float = 1.0) -> void:
	if is_dead or dt <= 0.0:
		return
	var safe_mass := maxf(mass, 0.0001)
	var eff_dt := dt * maxf(fast_play_ratio, 0.0)
	var before := Vector2(velocity.x, velocity.z)
	var dv := Vector2(force.x / safe_mass, force.z / safe_mass) * eff_dt
	var after := before + dv
	# If force acts opposite current motion and would reverse direction, clamp to zero
	if before.length_squared() > 0.000001 and before.dot(dv) < 0.0 and before.dot(after) <= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = after.x
		velocity.z = after.y


## Calculates the next position from current velocity over dt, scaled by fast_play_ratio:
##   p_next = p + v * (dt * fast_play_ratio)
func calculate_position(dt: float, fast_play_ratio: float = 1.0) -> Vector3:
	if is_dead or dt <= 0.0:
		return global_position
	var eff_dt := dt * maxf(fast_play_ratio, 0.0)
	return global_position + Vector3(velocity.x * eff_dt, velocity.y * eff_dt, velocity.z * eff_dt)


func apply_table_physics(delta: float) -> void:
	if is_falling_in_pocket:
		velocity.y -= TABLE_GRAVITY * delta
		_update_pocket_fall_rotation(delta)
		return
	collision_layer = 1
	collision_mask = 3
	if not is_on_floor():
		velocity.y -= TABLE_GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


## Begins falling into a Pocket Area swirl: invalidates the puck's collider so
## it passes through the solid floor block, dramatically decelerates horizontal
## velocity, initiates downward fall, and sets up the tilt axis so the side
## nearest the pocket center dips first before spinning clockwise.
func begin_pocket_fall(pocket_world_center: Vector3) -> void:
	if is_falling_in_pocket or is_dead:
		return
	is_falling_in_pocket = true
	_pocket_center = pocket_world_center
	_pocket_fall_elapsed = 0.0
	var to_center := Vector3(
		pocket_world_center.x - global_position.x,
		0.0,
		pocket_world_center.z - global_position.z
	)
	if to_center.length_squared() <= 0.0001:
		var vel_xz := Vector3(velocity.x, 0.0, velocity.z)
		to_center = vel_xz.normalized() if vel_xz.length_squared() > 0.0001 else Vector3(1.0, 0.0, 0.0)
	else:
		to_center = to_center.normalized()
	# Horizontal axis perpendicular to `to_center` such that a positive rotation
	# around `_pocket_tilt_axis` tips the side facing `to_center` downward (-Y):
	#   axis = UP x to_center = (to_center.z, 0, -to_center.x)
	_pocket_tilt_axis = Vector3(to_center.z, 0.0, -to_center.x).normalized()

	# Disable collider so the puck falls straight through the floor block
	collision_layer = 0
	collision_mask = 0
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null:
		col_shape.disabled = true

	# Immediate dramatic horizontal speed drop + initial downward velocity
	velocity.x *= 0.25
	velocity.z *= 0.25
	if velocity.y > -3.5:
		velocity.y = -3.5


## Resets pocket fall state and re-enables the puck's collider and upright transform.
func reset_from_pocket_fall(spawn_pos: Vector3) -> void:
	is_falling_in_pocket = false
	_pocket_fall_elapsed = 0.0
	global_position = spawn_pos
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	collision_layer = 1
	collision_mask = 3
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null:
		col_shape.disabled = false


func _update_pocket_fall_rotation(delta: float) -> void:
	_pocket_fall_elapsed += delta
	# Vertical tilt only: the side nearest the pocket center dips first as the puck falls
	var tilt_angle := minf(_pocket_fall_elapsed * 6.5, deg_to_rad(75.0))
	basis = Basis(_pocket_tilt_axis, tilt_angle)


func _find_unit_information_manager() -> Node:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("UnitInformationManager")
		if sibling != null:
			return sibling
	if is_inside_tree():
		return get_tree().get_first_node_in_group("unit_information_manager")
	return null


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var uim := _find_unit_information_manager()
	if uim != null and not _unit_id.is_empty() and uim.has_method("apply_direct_damage"):
		uim.call("apply_direct_damage", _unit_id, amount)


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var uim := _find_unit_information_manager()
	if uim != null and not _unit_id.is_empty() and uim.has_method("heal_unit"):
		uim.call("heal_unit", _unit_id, amount)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(self):
			queue_free()


func can_attack() -> bool:
	return _attack_timer <= 0.0 and not is_dead


func perform_attack(target: BasePuck) -> void:
	if not can_attack() or target == null:
		return
	_attack_timer = attack_cooldown
	var dmg := 10
	var uim := _find_unit_information_manager()
	if uim != null and not _unit_id.is_empty() and uim.has_method("get_unit"):
		var my_do = uim.call("get_unit", _unit_id)
		if my_do != null:
			dmg = int(my_do.power)
	target.take_damage(dmg)


func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
