@tool
class_name TableBlock
extends StaticBody3D

## A single 2x3x2 block of the Cue Table floor.
## Each block has a unique block_number (1..150) and a swappable block_type.

enum BlockType {
	GRASS_DARK = 0,
	GRASS_LIGHT = 1,
	POCKET = 2,
	STONE = 3,
	MUD = 4,
	ICE = 5,
}

const BLOCK_SIZE := Vector3(2.0, 3.0, 2.0)

const TEX_GRASS_DARK: Texture2D = preload("res://src/resource/battlefield/grass_dark.png")
const TEX_GRASS_LIGHT: Texture2D = preload("res://src/resource/battlefield/grass_light.png")
const TEX_POCKET_SWIRL: Texture2D = preload("res://src/resource/battlefield/pocket_swirl.png")

const POCKET_CAPTURE_RATIO := 0.75
const POCKET_DECELERATION := 28.0
const POCKET_PULL_SPEED := 6.0
const POCKET_Y_DROP := 0.3

const SWIRL_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec2 v_local_xz;

void vertex() {
	// BoxMesh size is 2x3x2, so VERTEX.xz is in [-1.0, 1.0]; normalize to [-0.5, 0.5]
	v_local_xz = VERTEX.xz * 0.5;
}

void fragment() {
	vec2 p = v_local_xz;
	float r = length(p);
	// Clockwise swirl rotation when viewed from above (+Y looking down -Y)
	float a = atan(p.y, p.x) + TIME * 3.0 + r * 18.0;
	float arms = 0.5 + 0.5 * sin(a * 4.0);
	float ring = smoothstep(0.68, 0.08, r);
	float core = smoothstep(0.16, 0.0, r);
	vec3 dark_abyss = vec3(0.02, 0.015, 0.035);
	vec3 swirl_col = vec3(0.28, 0.18, 0.44);
	vec3 glow_col = vec3(0.56, 0.38, 0.82);
	vec3 edge_col = vec3(0.05, 0.05, 0.08);
	float arm_factor = pow(arms, 2.0) * ring * (1.0 - core);
	vec3 col = mix(dark_abyss, swirl_col, arm_factor * 0.9);
	col = mix(col, glow_col, smoothstep(0.50, 0.92, arm_factor));
	col = mix(edge_col, col, smoothstep(0.72, 0.42, r));
	col = mix(col, vec3(0.01, 0.01, 0.02), core);
	ALBEDO = col;
}
"""

var _swirl_shader_mat: ShaderMaterial = null

@export var block_number: int = 1

@export var block_type: BlockType = BlockType.GRASS_DARK:
	set(value):
		block_type = value
		_apply_block_type()

@export var friction_factor: float = 1.0
@export var base_deceleration: float = 1.2
@export var stop_speed_threshold: float = 0.002


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_apply_block_type()


func set_block_type(new_type: BlockType) -> void:
	block_type = new_type


func is_pocket() -> bool:
	return block_type == BlockType.POCKET


## Returns true when `world_pos` is within the inner 3/4 rectangle length of
## this block (`|dx| <= 0.75 * half_width` and `|dz| <= 0.75 * half_depth`).
func is_within_pocket_capture_zone(world_pos: Vector3) -> bool:
	var local_pos := to_local(world_pos)
	var half_x := BLOCK_SIZE.x * 0.5 * POCKET_CAPTURE_RATIO
	var half_z := BLOCK_SIZE.z * 0.5 * POCKET_CAPTURE_RATIO
	return absf(local_pos.x) <= half_x + 0.0001 and absf(local_pos.z) <= half_z + 0.0001


## Special Pocket Area floor effect: when a puck's center reaches the 3/4
## rectangle capture zone of the pocket block, it dramatically decelerates
## horizontally, invalidates its collider, and begins falling + rotating into
## the black swirl.
func apply_pocket_effect(puck: BasePuck, dt: float, fast_play_ratio: float = 1.0) -> void:
	if puck == null or puck.is_dead:
		return
	var eff_dt := dt * maxf(fast_play_ratio, 0.0)
	if not puck.is_falling_in_pocket:
		if not is_within_pocket_capture_zone(puck.global_position):
			apply_standard_friction(puck, dt, fast_play_ratio, 1.0)
			return
		puck.begin_pocket_fall(global_position)

	# Dramatic horizontal deceleration + gentle pull toward swirl center while falling
	apply_standard_friction(puck, dt, fast_play_ratio, POCKET_DECELERATION / maxf(base_deceleration, 0.001))
	var to_center := Vector3(
		global_position.x - puck.global_position.x,
		0.0,
		global_position.z - puck.global_position.z
	)
	if to_center.length() > 0.05:
		var pull_step := minf(to_center.length(), POCKET_PULL_SPEED * eff_dt)
		puck.global_position.x += to_center.normalized().x * pull_step
		puck.global_position.z += to_center.normalized().z * pull_step


## Extendable ground-effect calculation: returns the horizontal velocity change
## over dt (scaled by fast_play_ratio). In the normal case, mass cancels out
## (F_friction = -mu * m * v_hat -> a = F / m = -base_deceleration * friction_factor * v_hat),
## decelerating at -1.2 unit/sec^2 on standard grass blocks and clamping to
## Vector3.ZERO below stop_speed_threshold so friction never reverses direction.
func calculate_ground_velocity_delta(puck: BasePuck, dt: float, fast_play_ratio: float = 1.0) -> Vector3:
	var eff_dt := dt * maxf(fast_play_ratio, 0.0)
	if puck == null or eff_dt <= 0.0 or is_pocket():
		return Vector3.ZERO
	var horiz := Vector3(puck.velocity.x, 0.0, puck.velocity.z)
	var speed := horiz.length()
	if speed <= 0.0001:
		return Vector3.ZERO
	var decel := base_deceleration * friction_factor * eff_dt
	if speed <= decel or (speed - decel) < stop_speed_threshold:
		return -horiz
	return -horiz.normalized() * decel


## Computes the standard ground friction Force vector:
##   F_friction = -(base_deceleration * factor * mass) * v_hat
func calculate_standard_friction_force(puck: BasePuck, custom_friction_factor: float = -1.0) -> Vector3:
	if puck == null or is_pocket():
		return Vector3.ZERO
	var horiz := Vector3(puck.velocity.x, 0.0, puck.velocity.z)
	if horiz.length_squared() <= 0.000001:
		return Vector3.ZERO
	var factor := friction_factor if custom_friction_factor < 0.0 else custom_friction_factor
	return -horiz.normalized() * (base_deceleration * factor * puck.mass)


## Computes the continuous ground friction Force vector (F = -m * a * v_hat).
func calculate_ground_force(puck: BasePuck) -> Vector3:
	return calculate_standard_friction_force(puck)


## Reusable helper that applies standard ground friction (with optional custom
## friction factor) to `puck` and clamps below `stop_speed_threshold`.
## Custom block effects in `apply_ground_effect()` can call this directly or
## combine it with additional forces.
func apply_standard_friction(
	puck: BasePuck,
	dt: float,
	fast_play_ratio: float = 1.0,
	custom_friction_factor: float = -1.0
) -> void:
	if puck == null:
		return
	var force := calculate_standard_friction_force(puck, custom_friction_factor)
	puck.apply_force(force, dt, fast_play_ratio)
	if Vector2(puck.velocity.x, puck.velocity.z).length() < stop_speed_threshold:
		puck.velocity.x = 0.0
		puck.velocity.z = 0.0


## Extendable ground-effect entry point called each 20 Hz velocity tick.
## By default delegates to `apply_standard_friction()`; Pocket blocks run
## `apply_pocket_effect()`.
func apply_ground_effect(puck: BasePuck, dt: float, fast_play_ratio: float = 1.0) -> void:
	if is_pocket():
		apply_pocket_effect(puck, dt, fast_play_ratio)
		return
	apply_standard_friction(puck, dt, fast_play_ratio)



func _apply_block_type() -> void:
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	var pocket_rim := get_node_or_null("PocketVisual") as Node3D

	match block_type:
		BlockType.GRASS_DARK:
			friction_factor = 1.0
			_set_vertical_offset(col_shape, mesh_inst, 0.0)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_grass_material(TEX_GRASS_DARK, Color(0.92, 0.96, 0.92, 1.0))
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.GRASS_LIGHT:
			friction_factor = 1.0
			_set_vertical_offset(col_shape, mesh_inst, 0.0)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_grass_material(TEX_GRASS_LIGHT, Color(0.96, 1.0, 0.94, 1.0))
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.POCKET:
			friction_factor = 1.0
			_set_vertical_offset(col_shape, mesh_inst, -POCKET_Y_DROP)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_swirl_material()
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.STONE:
			friction_factor = 0.75
			_set_vertical_offset(col_shape, mesh_inst, 0.0)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_solid_material(Color(0.45, 0.44, 0.42, 1.0), 0.85)
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.MUD:
			friction_factor = 2.0
			_set_vertical_offset(col_shape, mesh_inst, 0.0)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_solid_material(Color(0.32, 0.22, 0.13, 1.0), 0.95)
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.ICE:
			friction_factor = 0.2
			_set_vertical_offset(col_shape, mesh_inst, 0.0)
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_solid_material(Color(0.62, 0.84, 0.95, 1.0), 0.15)
			if pocket_rim != null:
				pocket_rim.visible = false


func _make_grass_material(tex: Texture2D, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = tint
	mat.roughness = 0.88
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _make_solid_material(col: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	return mat


func _set_vertical_offset(col_shape: CollisionShape3D, mesh_inst: MeshInstance3D, y_offset: float) -> void:
	if col_shape != null:
		col_shape.position.y = y_offset
	if mesh_inst != null:
		mesh_inst.position.y = y_offset


func _make_swirl_material() -> Material:
	if _swirl_shader_mat == null:
		var shader := Shader.new()
		shader.code = SWIRL_SHADER_CODE
		_swirl_shader_mat = ShaderMaterial.new()
		_swirl_shader_mat.shader = shader
	return _swirl_shader_mat


