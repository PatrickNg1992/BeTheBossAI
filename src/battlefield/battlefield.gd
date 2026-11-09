class_name Battlefield
extends Node3D

## Cue Table controller.
## All table blocks (TableBlock_1..TableBlock_150), cushion blocks (Cushion_1..Cushion_54),
## and medieval corner flags (CornerFlag_1..CornerFlag_4) are hardcoded in cue_table.tscn
## so every block can be inspected and customized in the editor or swapped at runtime.

const TABLE_WIDTH: float = 30.0
const TABLE_DEPTH: float = 20.0
const TABLE_HEIGHT: float = 3.0
const TILE_SIZE: float = 2.0
const TILE_COLS: int = 15
const TILE_ROWS: int = 10
const TABLE_BLOCK_COUNT: int = TILE_COLS * TILE_ROWS

const CUSHION_WIDTH: float = 2.0
const CUSHION_HEIGHT_ABOVE: float = 2.0
const CUSHION_SEGMENT: float = 2.0
const CUSHION_BLOCK_COUNT: int = 54

const TABLE_HALF_X: float = TABLE_WIDTH / 2.0
const TABLE_HALF_Z: float = TABLE_DEPTH / 2.0
const TABLE_TOP_Y: float = TABLE_HEIGHT / 2.0

const POCKET_BLOCK_NUMBERS: Array[int] = [1, 15, 136, 150]

## Spatial location index mapping `Vector2i(x, z)` integer floor coordinates
## (`int(floor(local_x)), int(floor(local_z))`) to the `TableBlock` covering
## that 1x1 cell. Built at startup to allow O(1) lookup and arbitrary/special
## rectangular table shapes.
var _block_location_index: Dictionary = {}


func _ready() -> void:
	add_to_group("cue_table")
	build_location_index()


## Builds the `Vector2i(x, z) -> TableBlock` location index from all child
## `TableBlock` nodes under `TableBlocks`, using each block's rectangular
## XZ footprint.
func build_location_index() -> void:
	_block_location_index.clear()
	var blocks_root := get_node_or_null("TableBlocks")
	if blocks_root == null:
		return
	for child in blocks_root.get_children():
		if not child is TableBlock:
			continue
		var block := child as TableBlock
		var size := _get_block_xz_size(block)
		var min_x := int(roundf(block.position.x - size.x * 0.5))
		var max_x := int(roundf(block.position.x + size.x * 0.5))
		var min_z := int(roundf(block.position.z - size.y * 0.5))
		var max_z := int(roundf(block.position.z + size.y * 0.5))
		for ix in range(min_x, max_x):
			for iz in range(min_z, max_z):
				_block_location_index[Vector2i(ix, iz)] = block


func _get_block_xz_size(block: TableBlock) -> Vector2:
	var col := block.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null and col.shape is BoxShape3D:
		var box := col.shape as BoxShape3D
		return Vector2(box.size.x * block.scale.x, box.size.z * block.scale.z)
	return Vector2(TableBlock.BLOCK_SIZE.x * block.scale.x, TableBlock.BLOCK_SIZE.z * block.scale.z)


func get_table_block_at_xz(ix: int, iz: int) -> TableBlock:
	if _block_location_index.is_empty():
		build_location_index()
	return _block_location_index.get(Vector2i(ix, iz), null) as TableBlock


func get_table_block(block_number: int) -> TableBlock:
	if block_number < 1 or block_number > TABLE_BLOCK_COUNT:
		return null
	return get_node_or_null("TableBlocks/TableBlock_%d" % block_number) as TableBlock


func set_table_block_type(block_number: int, new_type: TableBlock.BlockType) -> void:
	var block := get_table_block(block_number)
	if block != null:
		block.set_block_type(new_type)


func swap_table_block_types(block_number_a: int, block_number_b: int) -> void:
	var block_a := get_table_block(block_number_a)
	var block_b := get_table_block(block_number_b)
	if block_a == null or block_b == null:
		return
	var type_a := block_a.block_type
	block_a.set_block_type(block_b.block_type)
	block_b.set_block_type(type_a)


func get_table_block_at_grid(row: int, col: int) -> TableBlock:
	if row < 0 or row >= TILE_ROWS or col < 0 or col >= TILE_COLS:
		return null
	var block_number: int = row * TILE_COLS + col + 1
	return get_table_block(block_number)


func get_table_block_at_world(world_pos: Vector3) -> TableBlock:
	var local_pos := to_local(world_pos)
	var ix := int(floor(local_pos.x))
	var iz := int(floor(local_pos.z))
	return get_table_block_at_xz(ix, iz)


func is_pocket_at_world(world_pos: Vector3) -> bool:
	var block := get_table_block_at_world(world_pos)
	return block != null and block.is_pocket()


func get_cushion_block(cushion_number: int) -> CushionBlock:
	if cushion_number < 1 or cushion_number > CUSHION_BLOCK_COUNT:
		return null
	return get_node_or_null("Cushions/Cushion_%d" % cushion_number) as CushionBlock


func set_cushion_block_type(cushion_number: int, new_type: CushionBlock.CushionType) -> void:
	var cushion := get_cushion_block(cushion_number)
	if cushion != null:
		cushion.set_cushion_type(new_type)


func swap_cushion_block_types(cushion_number_a: int, cushion_number_b: int) -> void:
	var cushion_a := get_cushion_block(cushion_number_a)
	var cushion_b := get_cushion_block(cushion_number_b)
	if cushion_a == null or cushion_b == null:
		return
	var type_a := cushion_a.cushion_type
	cushion_a.set_cushion_type(cushion_b.cushion_type)
	cushion_b.set_cushion_type(type_a)


func get_corner_flag(flag_number: int) -> Node3D:
	if flag_number < 1 or flag_number > 4:
		return null
	return get_node_or_null("Decorations/CornerFlag_%d" % flag_number) as Node3D
