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

@export var block_number: int = 1

@export var block_type: BlockType = BlockType.GRASS_DARK:
	set(value):
		block_type = value
		_apply_block_type()

@export var friction_factor: float = 1.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst != null and mesh_inst.material_override == null and block_type != BlockType.POCKET:
		_apply_block_type()


func set_block_type(new_type: BlockType) -> void:
	block_type = new_type


func is_pocket() -> bool:
	return block_type == BlockType.POCKET


func _apply_block_type() -> void:
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	var pocket_rim := get_node_or_null("PocketVisual") as Node3D

	match block_type:
		BlockType.GRASS_DARK:
			friction_factor = 1.0
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_grass_material(TEX_GRASS_DARK, Color(0.92, 0.96, 0.92, 1.0))
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.GRASS_LIGHT:
			friction_factor = 1.0
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_grass_material(TEX_GRASS_LIGHT, Color(0.96, 1.0, 0.94, 1.0))
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.POCKET:
			friction_factor = 0.0
			if col_shape != null:
				col_shape.disabled = true
			if mesh_inst != null:
				mesh_inst.visible = false
			if pocket_rim != null:
				pocket_rim.visible = true

		BlockType.STONE:
			friction_factor = 0.75
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_solid_material(Color(0.45, 0.44, 0.42, 1.0), 0.85)
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.MUD:
			friction_factor = 2.0
			if col_shape != null:
				col_shape.disabled = false
			if mesh_inst != null:
				mesh_inst.visible = true
				mesh_inst.material_override = _make_solid_material(Color(0.32, 0.22, 0.13, 1.0), 0.95)
			if pocket_rim != null:
				pocket_rim.visible = false

		BlockType.ICE:
			friction_factor = 0.2
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

