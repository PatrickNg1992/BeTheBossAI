extends StaticBody3D
class_name Battlefield


const TABLE_SIZE: float = 20.0
const TABLE_HEIGHT: float = 3.0
const TILE_SIZE: float = 2.0
const TILE_COUNT: int = 10
const CUSHION_WIDTH: float = 2.0
const CUSHION_HEIGHT_ABOVE: float = 2.0
const CUSHION_SEGMENT: float = 2.0
const TABLE_HALF: float = TABLE_SIZE / 2.0
const TABLE_TOP_Y: float = TABLE_HEIGHT / 2.0

const TILE_GREEN: Color = Color(0.2, 0.6, 0.25, 1)
const TILE_LIGHT_GREEN: Color = Color(0.35, 0.75, 0.4, 1)
const CUSHION_BROWN: Color = Color(0.45, 0.3, 0.15, 1)
const CUSHION_LIGHT_BROWN: Color = Color(0.6, 0.45, 0.25, 1)
const POCKET_COLOR_A: Color = Color(0.08, 0.06, 0.04, 1)
const POCKET_COLOR_B: Color = Color(0.04, 0.06, 0.08, 1)


func _ready() -> void:
	_generate_tiles()
	_generate_cushions()
	_generate_pockets()


func _generate_tiles() -> void:
	for row: int in TILE_COUNT:
		for col: int in TILE_COUNT:
			if _is_pocket_tile(row, col):
				continue
			var tile: MeshInstance3D = MeshInstance3D.new()
			tile.name = "Tile_%d_%d" % [row, col]
			var mesh: BoxMesh = BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.06, TILE_SIZE)
			tile.mesh = mesh
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			if (row + col) % 2 == 0:
				mat.albedo_color = TILE_GREEN
			else:
				mat.albedo_color = TILE_LIGHT_GREEN
			tile.material_override = mat
			var x: float = -TABLE_HALF + TILE_SIZE / 2.0 + col * TILE_SIZE
			var z: float = -TABLE_HALF + TILE_SIZE / 2.0 + row * TILE_SIZE
			tile.transform.origin = Vector3(x, TABLE_TOP_Y + 0.03, z)
			add_child(tile)


func _is_pocket_tile(row: int, col: int) -> bool:
	if row == 0 and col == 0:
		return true
	if row == 0 and col == TILE_COUNT - 1:
		return true
	if row == TILE_COUNT - 1 and col == 0:
		return true
	if row == TILE_COUNT - 1 and col == TILE_COUNT - 1:
		return true
	return false


func _generate_cushions() -> void:
	var y: float = TABLE_TOP_Y + CUSHION_HEIGHT_ABOVE / 2.0
	var outer: float = TABLE_HALF + CUSHION_WIDTH / 2.0
	# Top (negative Z)
	_generate_cushion_rail(
		Vector3(0, y, -outer),
		Vector3(TABLE_SIZE, CUSHION_HEIGHT_ABOVE, CUSHION_WIDTH),
		true, true
	)
	# Bottom (positive Z)
	_generate_cushion_rail(
		Vector3(0, y, outer),
		Vector3(TABLE_SIZE, CUSHION_HEIGHT_ABOVE, CUSHION_WIDTH),
		true, false
	)
	# Left (negative X)
	_generate_cushion_rail(
		Vector3(-outer, y, 0),
		Vector3(CUSHION_WIDTH, CUSHION_HEIGHT_ABOVE, TABLE_SIZE),
		false, true
	)
	# Right (positive X)
	_generate_cushion_rail(
		Vector3(outer, y, 0),
		Vector3(CUSHION_WIDTH, CUSHION_HEIGHT_ABOVE, TABLE_SIZE),
		false, false
	)
	_generate_corner_cushions()


func _generate_cushion_rail(center: Vector3, size: Vector3, along_x: bool, flip_color: bool) -> void:
	var segment_count: int = int(TABLE_SIZE / CUSHION_SEGMENT)
	for i: int in segment_count:
		var seg_center: Vector3 = center
		var seg_size: Vector3 = size
		var half_len: float = (segment_count * CUSHION_SEGMENT) / 2.0
		var offset: float = -half_len + CUSHION_SEGMENT / 2.0 + i * CUSHION_SEGMENT

		if along_x:
			seg_center.x += offset
			seg_size.x = CUSHION_SEGMENT
		else:
			seg_center.z += offset
			seg_size.z = CUSHION_SEGMENT

		var seg: MeshInstance3D = MeshInstance3D.new()
		seg.name = "CushionSeg_%d" % i
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = seg_size
		seg.mesh = mesh
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		var is_brown: bool = (i % 2 == 0) != flip_color
		if is_brown:
			mat.albedo_color = CUSHION_BROWN
		else:
			mat.albedo_color = CUSHION_LIGHT_BROWN
		seg.material_override = mat
		seg.transform.origin = seg_center
		add_child(seg)


func _generate_corner_cushions() -> void:
	var y: float = TABLE_TOP_Y + CUSHION_HEIGHT_ABOVE / 2.0
	var corner_offset: float = TABLE_HALF + CUSHION_WIDTH / 2.0

	var corners: Array[Vector3] = [
		Vector3(-corner_offset, y, -corner_offset),
		Vector3(corner_offset, y, -corner_offset),
		Vector3(-corner_offset, y, corner_offset),
		Vector3(corner_offset, y, corner_offset),
	]

	for i: int in corners.size():
		var corner: MeshInstance3D = MeshInstance3D.new()
		corner.name = "CornerCushion_%d" % i
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(CUSHION_WIDTH, CUSHION_HEIGHT_ABOVE, CUSHION_WIDTH)
		corner.mesh = mesh
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if i == 1 or i == 2:
			mat.albedo_color = CUSHION_LIGHT_BROWN
		else:
			mat.albedo_color = CUSHION_BROWN
		corner.material_override = mat
		corner.transform.origin = corners[i]
		add_child(corner)


func _generate_pockets() -> void:
	var pocket_size: float = TILE_SIZE
	var half: float = TABLE_HALF - TILE_SIZE / 2.0

	var corners: Array[Vector3] = [
		Vector3(-half, TABLE_TOP_Y + 0.035, -half),
		Vector3(half, TABLE_TOP_Y + 0.035, -half),
		Vector3(-half, TABLE_TOP_Y + 0.035, half),
		Vector3(half, TABLE_TOP_Y + 0.035, half),
	]

	for i: int in corners.size():
		var pocket: MeshInstance3D = MeshInstance3D.new()
		pocket.name = "Pocket_%d" % i
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(pocket_size, 0.08, pocket_size)
		pocket.mesh = mesh
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if i == 1 or i == 2:
			mat.albedo_color = POCKET_COLOR_B
		else:
			mat.albedo_color = POCKET_COLOR_A
		pocket.material_override = mat
		pocket.transform.origin = corners[i]
		add_child(pocket)
