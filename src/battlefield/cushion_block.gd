@tool
class_name CushionBlock
extends StaticBody3D

## A single 2-unit segment of the Cue Table Cushion rail (or 2x2 corner post).
## Each cushion block has a unique cushion_number (1..54) and a swappable cushion_type.
## Includes parameters and helper for the dedicated cushion rebound equation:
##   v1f = (1 - fc) * (v1 - (v1 . n) * n) - e * (v1 . n) * n

enum CushionType {
	WOOD_DARK = 0,
	WOOD_LIGHT = 1,
	GRASS_DARK = 2,
	GRASS_LIGHT = 3,
	CORNER_DARK = 4,
	CORNER_LIGHT = 5,
}

const TEX_WOOD_DARK: Texture2D = preload("res://src/resource/battlefield/wood_dark.png")
const TEX_WOOD_LIGHT: Texture2D = preload("res://src/resource/battlefield/wood_light.png")
const TEX_GRASS_DARK: Texture2D = preload("res://src/resource/battlefield/grass_dark.png")
const TEX_GRASS_LIGHT: Texture2D = preload("res://src/resource/battlefield/grass_light.png")

@export var cushion_number: int = 1

@export var cushion_type: CushionType = CushionType.WOOD_DARK:
	set(value):
		cushion_type = value
		_apply_cushion_type()

## Normalised inward perpendicular direction pointing into the table floor.
@export var inward_normal: Vector3 = Vector3.ZERO

## Collision energy restitution factor (e) in the cushion rebound equation.
@export var restitution: float = 0.85

## Cushion parallel friction factor (fc) in the cushion rebound equation.
@export var cushion_friction: float = 0.10


func _ready() -> void:
	collision_layer = 3
	collision_mask = 0
	var wood_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if wood_mesh != null and wood_mesh.material_override == null:
		_apply_cushion_type()


func set_cushion_type(new_type: CushionType) -> void:
	cushion_type = new_type


## Dedicated cushion rebound equation from collisionSystem.md:
##   v1f = (1 - fc) * (v1 - (v1 . n) * n) - e * (v1 . n) * n
func compute_rebound_velocity(incident_velocity: Vector3, normal_override: Vector3 = Vector3.ZERO) -> Vector3:
	var n := normal_override.normalized() if normal_override.length_squared() > 0.0001 else inward_normal.normalized()
	if n.length_squared() <= 0.0001:
		return -incident_velocity * restitution
	var v_dot_n := incident_velocity.dot(n)
	var v_perp := v_dot_n * n
	var v_parallel := incident_velocity - v_perp
	return (1.0 - cushion_friction) * v_parallel - restitution * v_perp


## Extendable Cushion impact function: takes `(puck: BasePuck, normal: Vector3)`
## and returns the velocity delta `v1f - v1` (mass-independent in the normal
## case) when the puck is approaching the Cushion (`v1 . n < 0`).
func calculate_cushion_impact(puck: BasePuck, normal_override: Vector3 = Vector3.ZERO) -> Vector3:
	if puck == null or puck.is_dead:
		return Vector3.ZERO
	var n := normal_override.normalized() if normal_override.length_squared() > 0.0001 else inward_normal.normalized()
	if n.length_squared() <= 0.0001:
		return Vector3.ZERO
	var v_in := Vector3(puck.velocity.x, 0.0, puck.velocity.z)
	if v_in.dot(n) >= -0.0001:
		return Vector3.ZERO
	var v_out := compute_rebound_velocity(v_in, n)
	return v_out - v_in


## Applies the Cushion impact velocity change directly to `puck`.
func apply_cushion_impact(puck: BasePuck, normal_override: Vector3 = Vector3.ZERO) -> void:
	if puck == null or puck.is_dead:
		return
	var dv := calculate_cushion_impact(puck, normal_override)
	puck.velocity.x += dv.x
	puck.velocity.z += dv.z



func _apply_cushion_type() -> void:
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null:
		col_shape.disabled = false

	var wood_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	var grass_bumper := get_node_or_null("GrassBumper") as MeshInstance3D

	match cushion_type:
		CushionType.WOOD_DARK:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_WOOD_DARK, Color(0.95, 0.90, 0.85, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = true
				grass_bumper.material_override = _make_textured_material(TEX_GRASS_DARK, Color(0.88, 0.95, 0.86, 1.0))

		CushionType.WOOD_LIGHT:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_WOOD_LIGHT, Color(1.0, 0.96, 0.90, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = true
				grass_bumper.material_override = _make_textured_material(TEX_GRASS_LIGHT, Color(0.92, 0.98, 0.90, 1.0))

		CushionType.GRASS_DARK:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_GRASS_DARK, Color(0.85, 0.94, 0.85, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = true
				grass_bumper.material_override = _make_textured_material(TEX_WOOD_DARK, Color(0.95, 0.90, 0.85, 1.0))

		CushionType.GRASS_LIGHT:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_GRASS_LIGHT, Color(0.92, 1.0, 0.90, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = true
				grass_bumper.material_override = _make_textured_material(TEX_WOOD_LIGHT, Color(1.0, 0.96, 0.90, 1.0))

		CushionType.CORNER_DARK:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_WOOD_DARK, Color(0.82, 0.76, 0.70, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = false

		CushionType.CORNER_LIGHT:
			if wood_mesh != null:
				wood_mesh.material_override = _make_textured_material(TEX_WOOD_LIGHT, Color(0.94, 0.88, 0.80, 1.0))
			if grass_bumper != null:
				grass_bumper.visible = false


func _make_textured_material(tex: Texture2D, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = tint
	mat.roughness = 0.82
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat

