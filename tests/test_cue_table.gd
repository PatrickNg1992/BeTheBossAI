extends McpTestSuite

## Tests for the reconstructed Cue Table (cue_table.tscn + battlefield.gd):
## - Hardcoded numbered TableBlocks (1..150) and CushionBlocks (1..54) in scene
## - Block type customization and swapping for table and cushions
## - Collision bodies: table supports pucks, pockets allow pucks to fall,
##   cushions prevent pucks from leaving the table and provide the dedicated rebound equation
## - Medieval style elements (wooden/grass cushions, grass tiles, 4 corner flags)

const CUE_TABLE_SCENE := "res://src/battlefield/cue_table.tscn"
const DEMO_BATTLEFIELD_SCENE := "res://src/demo_bettlefield.tscn"

var _table: Battlefield = null


func suite_name() -> String:
	return "cue-table"


func setup() -> void:
	var packed := ResourceLoader.load(CUE_TABLE_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Cue Table scene failed to load")
	if packed == null:
		return
	_table = packed.instantiate() as Battlefield
	(Engine.get_main_loop() as SceneTree).root.add_child(_table)


func teardown() -> void:
	if is_instance_valid(_table):
		_table.get_parent().remove_child(_table)
		_table.queue_free()
	_table = null


func test_blocks_and_cushions_are_hardcoded_in_scene_with_numbers() -> void:
	var packed := ResourceLoader.load(CUE_TABLE_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "PackedScene must load")
	if packed == null:
		return
	# Inspect the unmounted instance BEFORE _ready() runs to verify nodes are hardcoded in .tscn
	var raw_instance := packed.instantiate() as Battlefield
	var blocks_root := raw_instance.get_node_or_null("TableBlocks")
	var cushions_root := raw_instance.get_node_or_null("Cushions")
	assert_true(blocks_root != null, "TableBlocks container exists in PackedScene before _ready")
	assert_true(cushions_root != null, "Cushions container exists in PackedScene before _ready")
	if blocks_root != null:
		assert_eq(blocks_root.get_child_count(), 150, "All 150 table blocks are hardcoded in scene")
	if cushions_root != null:
		assert_eq(cushions_root.get_child_count(), 54, "All 54 cushion blocks are hardcoded in scene")

	for i: int in range(1, 151):
		var blk := raw_instance.get_table_block(i)
		assert_true(blk != null, "TableBlock_%d exists" % i)
		if blk != null:
			assert_eq(blk.block_number, i, "TableBlock_%d has matching block_number" % i)

	for j: int in range(1, 55):
		var cush := raw_instance.get_cushion_block(j)
		assert_true(cush != null, "Cushion_%d exists" % j)
		if cush != null:
			assert_eq(cush.cushion_number, j, "Cushion_%d has matching cushion_number" % j)

	raw_instance.free()


func test_table_block_types_can_be_customized_and_swapped() -> void:
	if _table == null:
		return
	# Corner blocks 1, 15, 136, 150 default to POCKET
	for corner_id: int in [1, 15, 136, 150]:
		var corner_blk := _table.get_table_block(corner_id)
		assert_true(corner_blk != null and corner_blk.is_pocket(),
			"Corner block %d defaults to POCKET" % corner_id)

	# Customize block 25 to ICE and block 26 to MUD, then swap them
	_table.set_table_block_type(25, TableBlock.BlockType.ICE)
	_table.set_table_block_type(26, TableBlock.BlockType.MUD)
	assert_eq(_table.get_table_block(25).block_type, TableBlock.BlockType.ICE, "Block 25 set to ICE")
	assert_eq(_table.get_table_block(26).block_type, TableBlock.BlockType.MUD, "Block 26 set to MUD")
	assert_true(_table.get_table_block(25).friction_factor < _table.get_table_block(26).friction_factor,
		"ICE has lower friction than MUD")

	_table.swap_table_block_types(25, 26)
	assert_eq(_table.get_table_block(25).block_type, TableBlock.BlockType.MUD, "Block 25 swapped to MUD")
	assert_eq(_table.get_table_block(26).block_type, TableBlock.BlockType.ICE, "Block 26 swapped to ICE")


func test_table_and_pocket_collision_shapes() -> void:
	if _table == null:
		return
	var solid_block := _table.get_table_block(2)
	var pocket_block := _table.get_table_block(1)
	var solid_col := solid_block.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var pocket_col := pocket_block.get_node_or_null("CollisionShape3D") as CollisionShape3D

	assert_true(solid_col != null and not solid_col.disabled,
		"Solid table blocks have active CollisionShape3D to prevent pucks from falling")
	assert_true(pocket_col != null and pocket_col.disabled,
		"Pocket blocks disable floor CollisionShape3D so pucks can fall in")

	# Swapping a normal block to POCKET disables its floor collider
	_table.set_table_block_type(2, TableBlock.BlockType.POCKET)
	assert_true(solid_col.disabled, "Swapping block to POCKET disables floor collision")
	_table.set_table_block_type(2, TableBlock.BlockType.GRASS_LIGHT)
	assert_true(not solid_col.disabled, "Swapping block back to GRASS re-enables floor collision")


func test_cushions_have_collision_and_rebound_equation() -> void:
	if _table == null:
		return
	for j: int in range(1, 55):
		var cush := _table.get_cushion_block(j)
		var col := cush.get_node_or_null("CollisionShape3D") as CollisionShape3D
		assert_true(col != null and not col.disabled and col.shape is BoxShape3D,
			"Cushion_%d has an active BoxShape3D collider" % j)

	# Top cushion (Cushion_1) has inward normal (0, 0, 1)
	var top_cushion := _table.get_cushion_block(1)
	top_cushion.restitution = 0.8
	top_cushion.cushion_friction = 0.1
	var v_in := Vector3(10.0, 0.0, -5.0)
	var v_out := top_cushion.compute_rebound_velocity(v_in)
	# Parallel X: (1 - 0.1) * 10 = 9.0; Perpendicular Z: -0.8 * (-5.0) = +4.0
	assert_true(is_equal_approx(v_out.x, 9.0), "Parallel velocity scaled by (1 - fc)")
	assert_true(is_equal_approx(v_out.z, 4.0), "Perpendicular velocity reflected and scaled by e")


func test_medieval_style_wooden_and_grass_cushions_and_corner_flags() -> void:
	if _table == null:
		return
	# Verify all 4 medieval corner flags exist with pole, finial, and heraldic banner
	for f: int in range(1, 5):
		var flag := _table.get_corner_flag(f)
		assert_true(flag != null, "CornerFlag_%d exists" % f)
		if flag != null:
			assert_true(flag.get_node_or_null("FlagPole") != null, "CornerFlag_%d has FlagPole" % f)
			assert_true(flag.get_node_or_null("HeraldicBanner") != null, "CornerFlag_%d has HeraldicBanner" % f)

	# Verify cushion supports both wooden style and grass style
	var c1 := _table.get_cushion_block(1)
	assert_true(c1.get_node_or_null("GrassBumper") != null, "Cushion has grass style bumper trim")
	_table.set_cushion_block_type(1, CushionBlock.CushionType.GRASS_DARK)
	assert_eq(c1.cushion_type, CushionBlock.CushionType.GRASS_DARK, "Cushion switched to grass style")
	_table.set_cushion_block_type(1, CushionBlock.CushionType.WOOD_LIGHT)
	assert_eq(c1.cushion_type, CushionBlock.CushionType.WOOD_LIGHT, "Cushion switched to wooden style")
