class_name BasePuck
extends CharacterBody3D

signal health_changed(current_hp: int, max_hp: int)
signal died()

const TABLE_GRAVITY: float = 25.0

@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var attack_damage: int = 10
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.0
@export var mass: float = 1.0
@export var radius: float = 0.5
@export var restitution: float = 0.85

var current_hp: int
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
		half_h = (col_shape.shape as CylinderShape3D).height * 0.5 + 0.03
	var is_boss_mark := (_reference_mark == "Ω" or _reference_mark == "Ψ" or self is BaseBossMonster)
	_ref_mark_label_3d.font_size = 112 if is_boss_mark else 74
	_ref_mark_label_3d.pixel_size = 0.0095 if is_boss_mark else 0.0085
	_ref_mark_label_3d.outline_size = 0
	_ref_mark_label_3d.position = Vector3(0.0, half_h, 0.0)
	_ref_mark_label_3d.text = _reference_mark
	_ref_mark_label_3d.modulate = _reference_mark_color
	_ref_mark_label_3d.visible = true


func _ready() -> void:
	add_to_group("pucks")
	current_hp = max_hp
	collision_mask = 3
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		radius = (col_shape.shape as CylinderShape3D).radius
	if not _reference_mark.is_empty():
		_update_reference_mark_3d()
	if _slot_color != Color(0.5, 0.5, 0.5, 1.0):
		_apply_slot_color_to_mesh()


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


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		die()


func heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func die() -> void:
	is_dead = true
	died.emit()
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()


func can_attack() -> bool:
	return _attack_timer <= 0.0 and not is_dead


func perform_attack(target: BasePuck) -> void:
	if not can_attack():
		return
	_attack_timer = attack_cooldown
	target.take_damage(attack_damage)


func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
