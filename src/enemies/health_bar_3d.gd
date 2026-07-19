class_name HealthBar3D
extends Node3D

@export var bar_width: float = 1.2
@export var bar_height: float = 0.15
@export var y_offset: float = 2.5

var _background: MeshInstance3D
var _fill: MeshInstance3D
var _character: CharacterBase

func _ready() -> void:
	_character = get_parent() as CharacterBase
	if not _character:
		return
	_character.health_changed.connect(_on_health_changed)
	_character.died.connect(_on_died)
	_build_bar()

func _build_bar() -> void:
	# Background (dark gray)
	_background = MeshInstance3D.new()
	_background.mesh = _create_quad(bar_width, bar_height, Color(0.2, 0.2, 0.2, 0.9))
	_background.position = Vector3(0, y_offset, 0)
	add_child(_background)

	# Fill (green)
	_fill = MeshInstance3D.new()
	_fill.mesh = _create_quad(bar_width, bar_height, Color(0.2, 0.9, 0.2, 0.95))
	_fill.position = Vector3(0, y_offset, 0.01)
	add_child(_fill)

	_on_health_changed(_character.current_hp, _character.max_hp)

func _create_quad(w: float, h: float, color: Color) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var half_w := w / 2.0
	var half_h := h / 2.0

	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-half_w, -half_h, 0),
		Vector3(half_w, -half_h, 0),
		Vector3(half_w, half_h, 0),
		Vector3(-half_w, half_h, 0),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1),
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mesh.surface_set_material(0, mat)

	return mesh

func _on_health_changed(current: int, maximum: int) -> void:
	var ratio := float(current) / float(maximum)
	var fill_w := bar_width * ratio
	_fill.mesh = _create_quad(fill_w, bar_height, _get_health_color(ratio))
	# Shift fill so it shrinks from left
	_fill.position.x = -((bar_width - fill_w) / 2.0)

func _get_health_color(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0.2, 0.9, 0.2, 0.95)
	elif ratio > 0.3:
		return Color(0.9, 0.8, 0.1, 0.95)
	else:
		return Color(0.9, 0.2, 0.1, 0.95)

func _on_died() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(_character) or _character.is_dead:
		visible = false
		return
	# Billboard: face the camera
	var camera := get_viewport().get_camera_3d()
	if camera:
		look_at(camera.global_position, Vector3.UP)
