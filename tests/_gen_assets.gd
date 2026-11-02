extends Node

## One-off asset generator for the Time Board's medieval theme.
## Writes PNGs into res://src/resource/battlefield/ and quits.
## Delete after use; regenerate by running this scene again.

const OUT := "res://src/resource/battlefield/"


func _ready() -> void:
	_make_wood_panel()
	_make_arrow("arrow_down.png", true)
	_make_arrow("arrow_up.png", false)
	_make_goal_flag()
	_make_sword()
	_make_grass_tile("grass_dark.png", Color(0.18, 0.46, 0.19), Color(0.12, 0.33, 0.13), 101)
	_make_grass_tile("grass_light.png", Color(0.28, 0.58, 0.26), Color(0.20, 0.44, 0.19), 202)
	_make_wood_cushion("wood_dark.png", Color(0.38, 0.24, 0.12), Color(0.22, 0.14, 0.07), 303)
	_make_wood_cushion("wood_light.png", Color(0.52, 0.35, 0.18), Color(0.32, 0.21, 0.10), 404)
	_build_cue_table_scene()
	print("ASSETS_DONE")
	var tree := Engine.get_main_loop() as SceneTree
	tree.quit(0)


func _save(img: Image, name: String) -> void:
	var err := img.save_png(OUT + name)
	print("save ", name, " -> ", err)


## 256x96 wooden plank panel with a darker frame border (9-patch friendly).
func _make_wood_panel() -> void:
	var w := 256
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plank_h := 24
	var plank_tint: Array[float] = []
	for i in range(h / plank_h + 1):
		plank_tint.append(rng.randf_range(-0.05, 0.05))
	for y in range(h):
		for x in range(w):
			var plank := y / plank_h
			var n := noise.get_noise_2d(float(x) * 0.6, float(plank) * 3.0) * 0.5 + 0.5
			var grain := noise.get_noise_2d(float(x) * 0.15, float(y) * 1.4) * 0.12
			var c := Color(0.42, 0.29, 0.15)
			c = c.lightened((n - 0.5) * 0.25 + grain + plank_tint[plank])
			# plank seams
			if y % plank_h == 0:
				c = Color(0.2, 0.13, 0.07)
			# frame border
			if x < 6 or x >= w - 6 or y < 6 or y >= h - 6:
				c = Color(0.24, 0.16, 0.09)
			if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
				c = Color(0.15, 0.1, 0.06)
			img.set_pixel(x, y, c)
	_save(img, "wood_panel.png")


## Chunky pennant arrow, 32x18: shaft + triangle head. Bone white.
func _make_arrow(name: String, down: bool) -> void:
	var w := 32
	var h := 18
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bone := Color(0.9, 0.86, 0.72, 1)
	var shade := Color(0.55, 0.5, 0.4, 1)
	for y in range(h):
		for x in range(w):
			var yy := y if down else h - 1 - y
			var inside := false
			if yy < 6 and x >= w / 2 - 2 and x <= w / 2 + 2:
				inside = true  # shaft
			elif yy >= 5:
				# triangle widening towards the base at yy=5, tip at yy=h-1
				var t := float(yy - 5) / float(h - 6)
				var half := lerpf(w * 0.42, 0.0, t)
				if abs(x - (w - 1) / 2.0) <= half:
					inside = true
			if inside:
				var edge: bool = yy >= 5 and abs(abs(x - (w - 1) / 2.0) - lerpf(w * 0.42, 0.0, float(yy - 5) / float(h - 6))) < 1.0
				img.set_pixel(x, y, shade if edge else bone)
	_save(img, name)


## 28x36 flag-on-pole goal marker: brown pole, red pennant.
func _make_goal_flag() -> void:
	var w := 28
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pole := Color(0.3, 0.2, 0.11, 1)
	var red := Color(0.72, 0.16, 0.14, 1)
	var dark_red := Color(0.5, 0.1, 0.09, 1)
	for y in range(h):
		for x in range(w):
			if x >= 4 and x <= 5 and y >= 1:
				img.set_pixel(x, y, pole)
			# pennant: triangle from (6,2) to (25,8) to (6,14)
			if y >= 2 and y <= 14 and x >= 6:
				var t := float(y - 2) / 12.0
				var reach := lerpf(19.0, 0.0, abs(t - 0.45) * 2.0)
				if x - 6 <= reach:
					img.set_pixel(x, y, dark_red if y >= 13 else red)
	_save(img, "goal_flag.png")


## 22x22 sword icon: steel blade, iron crossguard, brown grip.
func _make_sword() -> void:
	var w := 22
	var h := 22
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var steel := Color(0.78, 0.8, 0.85, 1)
	var steel_edge := Color(0.55, 0.57, 0.62, 1)
	var iron := Color(0.35, 0.32, 0.3, 1)
	var grip := Color(0.4, 0.26, 0.14, 1)
	for y in range(h):
		for x in range(w):
			# blade: y 1..13, centered at x=11, 3px wide tapering to tip
			if y >= 1 and y <= 13:
				var half := 1.0 if y > 2 else 0.0
				if abs(x - 11) <= half:
					img.set_pixel(x, y, steel if x == 11 else steel_edge)
			# crossguard
			if y >= 14 and y <= 15 and x >= 6 and x <= 16:
				img.set_pixel(x, y, iron)
			# grip
			if y >= 16 and y <= 19 and x >= 10 and x <= 12:
				img.set_pixel(x, y, grip)
			# pommel
			if y >= 20 and y <= 21 and x >= 10 and x <= 12:
				img.set_pixel(x, y, iron)
	_save(img, "sword.png")


## 64x64 medieval turf/grass tile texture with subtle blades and mossy edge trim.
func _make_grass_tile(name: String, base_col: Color, border_col: Color, seed_val: int) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = seed_val
	noise.frequency = 0.14
	var detail := FastNoiseLite.new()
	detail.noise_type = FastNoiseLite.TYPE_CELLULAR
	detail.seed = seed_val + 17
	detail.frequency = 0.22
	for y in range(s):
		for x in range(s):
			var n := noise.get_noise_2d(float(x), float(y)) * 0.12
			var d := detail.get_noise_2d(float(x) * 1.5, float(y) * 0.7) * 0.08
			var c := base_col.lightened(n + d)
			# Subtle grass blade tufts
			if ((x * 7 + y * 13 + seed_val) % 29 == 0) and y > 3 and y < s - 3:
				c = c.lightened(0.10)
			# Soft bevel / turf border
			if x < 2 or x >= s - 2 or y < 2 or y >= s - 2:
				c = border_col
			elif x == 2 or x == s - 3 or y == 2 or y == s - 3:
				c = base_col.darkened(0.12)
			img.set_pixel(x, y, c)
	_save(img, name)


## 64x64 medieval oak timber texture with wood grain, iron band, and rivets.
func _make_wood_cushion(name: String, base_col: Color, trim_col: Color, seed_val: int) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = seed_val
	noise.frequency = 0.10
	var iron := Color(0.26, 0.25, 0.28, 1.0)
	var rivet := Color(0.52, 0.50, 0.44, 1.0)
	for y in range(s):
		for x in range(s):
			var grain := noise.get_noise_2d(float(x) * 0.35, float(y) * 1.8) * 0.14
			var plank := (y / 16)
			var plank_shift := float((plank * 37) % 11 - 5) * 0.012
			var c := base_col.lightened(grain + plank_shift)
			if y % 16 == 0:
				c = trim_col
			# Iron reinforcement edge band
			if x < 3 or x >= s - 3 or y < 3 or y >= s - 3:
				c = trim_col
			if (x >= 4 and x <= 6) or (x >= s - 7 and x <= s - 5):
				if y >= 4 and y <= 6 or y >= s - 7 and y <= s - 5:
					c = rivet
				elif y == 4 or y == s - 5:
					c = iron
			img.set_pixel(x, y, c)
	_save(img, name)


func _build_cue_table_scene() -> void:
	var battlefield_script := load("res://src/battlefield/battlefield.gd") as Script
	var table_block_script := load("res://src/battlefield/table_block.gd") as Script
	var cushion_block_script := load("res://src/battlefield/cushion_block.gd") as Script

	var root := Node3D.new()
	root.name = "Battlefield"
	root.set_script(battlefield_script)

	var table_blocks_root := Node3D.new()
	table_blocks_root.name = "TableBlocks"
	root.add_child(table_blocks_root)
	table_blocks_root.owner = root

	var cushions_root := Node3D.new()
	cushions_root.name = "Cushions"
	root.add_child(cushions_root)
	cushions_root.owner = root

	var decorations_root := Node3D.new()
	decorations_root.name = "Decorations"
	root.add_child(decorations_root)
	decorations_root.owner = root

	# Shared resources for TableBlocks
	var block_box_shape := BoxShape3D.new()
	block_box_shape.size = Vector3(2.0, 3.0, 2.0)

	var block_box_mesh := BoxMesh.new()
	block_box_mesh.size = Vector3(2.0, 3.0, 2.0)

	var pit_floor_mesh := CylinderMesh.new()
	pit_floor_mesh.top_radius = 0.92
	pit_floor_mesh.bottom_radius = 0.92
	pit_floor_mesh.height = 0.12

	var pit_rim_mesh := TorusMesh.new()
	pit_rim_mesh.inner_radius = 0.72
	pit_rim_mesh.outer_radius = 0.98

	var pit_floor_mat := StandardMaterial3D.new()
	pit_floor_mat.albedo_color = Color(0.04, 0.03, 0.03, 1.0)
	pit_floor_mat.roughness = 0.95

	var pit_rim_mat := StandardMaterial3D.new()
	pit_rim_mat.albedo_color = Color(0.24, 0.22, 0.20, 1.0)
	pit_rim_mat.metallic = 0.35
	pit_rim_mat.roughness = 0.7

	var pocket_numbers := [1, 15, 136, 150]

	for row: int in range(10):
		for col: int in range(15):
			var num: int = row * 15 + col + 1
			var block := StaticBody3D.new()
			block.name = "TableBlock_%d" % num
			block.set_script(table_block_script)
			var x: float = -15.0 + 1.0 + col * 2.0
			var z: float = -10.0 + 1.0 + row * 2.0
			block.position = Vector3(x, 0.0, z)
			block.collision_layer = 1
			block.collision_mask = 0

			var col_node := CollisionShape3D.new()
			col_node.name = "CollisionShape3D"
			col_node.shape = block_box_shape
			block.add_child(col_node)

			var mesh_node := MeshInstance3D.new()
			mesh_node.name = "MeshInstance3D"
			mesh_node.mesh = block_box_mesh
			block.add_child(mesh_node)

			var pocket_vis := Node3D.new()
			pocket_vis.name = "PocketVisual"
			block.add_child(pocket_vis)

			var pit_floor := MeshInstance3D.new()
			pit_floor.name = "PitFloor"
			pit_floor.mesh = pit_floor_mesh
			pit_floor.material_override = pit_floor_mat
			pit_floor.position = Vector3(0.0, -1.2, 0.0)
			pocket_vis.add_child(pit_floor)

			var pit_rim := MeshInstance3D.new()
			pit_rim.name = "PitRim"
			pit_rim.mesh = pit_rim_mesh
			pit_rim.material_override = pit_rim_mat
			pit_rim.position = Vector3(0.0, 1.44, 0.0)
			pocket_vis.add_child(pit_rim)

			table_blocks_root.add_child(block)
			block.owner = root
			col_node.owner = root
			mesh_node.owner = root
			pocket_vis.owner = root
			pit_floor.owner = root
			pit_rim.owner = root

			block.set("block_number", num)
			if num in pocket_numbers:
				block.set("block_type", 2) # POCKET
			elif (row + col) % 2 == 0:
				block.set("block_type", 0) # GRASS_DARK
			else:
				block.set("block_type", 1) # GRASS_LIGHT

	# Shared resources for Cushions
	var cushion_box_shape := BoxShape3D.new()
	cushion_box_shape.size = Vector3(2.0, 5.0, 2.0)

	var cushion_box_mesh := BoxMesh.new()
	cushion_box_mesh.size = Vector3(2.0, 5.0, 2.0)

	var bumper_mesh_x := BoxMesh.new()
	bumper_mesh_x.size = Vector3(2.0, 1.6, 0.26)

	var bumper_mesh_z := BoxMesh.new()
	bumper_mesh_z.size = Vector3(0.26, 1.6, 2.0)

	var cushion_idx: int = 1
	# Top rail (1..15) at z = -11.0
	for i: int in range(15):
		var x: float = -14.0 + i * 2.0
		var ctype: int = 0 if (i % 2 == 1) else 1
		_add_hardcoded_cushion(
			root, cushions_root, cushion_block_script,
			cushion_idx, Vector3(x, 1.0, -11.0), Vector3(0, 0, 1),
			ctype, cushion_box_shape, cushion_box_mesh, bumper_mesh_x, Vector3(0, 1.25, 0.92)
		)
		cushion_idx += 1

	# Bottom rail (16..30) at z = +11.0
	for i: int in range(15):
		var x: float = -14.0 + i * 2.0
		var ctype: int = 0 if (i % 2 == 0) else 1
		_add_hardcoded_cushion(
			root, cushions_root, cushion_block_script,
			cushion_idx, Vector3(x, 1.0, 11.0), Vector3(0, 0, -1),
			ctype, cushion_box_shape, cushion_box_mesh, bumper_mesh_x, Vector3(0, 1.25, -0.92)
		)
		cushion_idx += 1

	# Left rail (31..40) at x = -16.0
	for i: int in range(10):
		var z: float = -9.0 + i * 2.0
		var ctype: int = 0 if (i % 2 == 1) else 1
		_add_hardcoded_cushion(
			root, cushions_root, cushion_block_script,
			cushion_idx, Vector3(-16.0, 1.0, z), Vector3(1, 0, 0),
			ctype, cushion_box_shape, cushion_box_mesh, bumper_mesh_z, Vector3(0.92, 1.25, 0)
		)
		cushion_idx += 1

	# Right rail (41..50) at x = +16.0
	for i: int in range(10):
		var z: float = -9.0 + i * 2.0
		var ctype: int = 0 if (i % 2 == 0) else 1
		_add_hardcoded_cushion(
			root, cushions_root, cushion_block_script,
			cushion_idx, Vector3(16.0, 1.0, z), Vector3(-1, 0, 0),
			ctype, cushion_box_shape, cushion_box_mesh, bumper_mesh_z, Vector3(-0.92, 1.25, 0)
		)
		cushion_idx += 1

	# 4 Corner Cushions (51..54)
	var corner_defs := [
		{"pos": Vector3(-16.0, 1.0, -11.0), "norm": Vector3(1, 0, 1).normalized(), "type": 4},
		{"pos": Vector3(16.0, 1.0, -11.0), "norm": Vector3(-1, 0, 1).normalized(), "type": 5},
		{"pos": Vector3(-16.0, 1.0, 11.0), "norm": Vector3(1, 0, -1).normalized(), "type": 5},
		{"pos": Vector3(16.0, 1.0, 11.0), "norm": Vector3(-1, 0, -1).normalized(), "type": 4},
	]
	for cdef in corner_defs:
		_add_hardcoded_cushion(
			root, cushions_root, cushion_block_script,
			cushion_idx, cdef["pos"], cdef["norm"],
			cdef["type"], cushion_box_shape, cushion_box_mesh, bumper_mesh_x, Vector3.ZERO
		)
		cushion_idx += 1

	# 4 Medieval Corner Flags on the 4 corners
	_build_corner_flags(root, decorations_root)

	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	print("pack cue_table.tscn -> ", pack_err)
	var save_err := ResourceSaver.save(packed, "res://src/battlefield/cue_table.tscn")
	print("save cue_table.tscn -> ", save_err)
	root.free()


func _add_hardcoded_cushion(
	root: Node3D,
	parent: Node3D,
	script: Script,
	num: int,
	pos: Vector3,
	inward_norm: Vector3,
	ctype: int,
	box_shape: BoxShape3D,
	box_mesh: BoxMesh,
	bumper_mesh: BoxMesh,
	bumper_pos: Vector3
) -> void:
	var cushion := StaticBody3D.new()
	cushion.name = "Cushion_%d" % num
	cushion.set_script(script)
	cushion.position = pos
	cushion.collision_layer = 3
	cushion.collision_mask = 0

	var col_node := CollisionShape3D.new()
	col_node.name = "CollisionShape3D"
	col_node.shape = box_shape
	cushion.add_child(col_node)

	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "MeshInstance3D"
	mesh_node.mesh = box_mesh
	cushion.add_child(mesh_node)

	var grass_bumper := MeshInstance3D.new()
	grass_bumper.name = "GrassBumper"
	grass_bumper.mesh = bumper_mesh
	grass_bumper.position = bumper_pos
	cushion.add_child(grass_bumper)

	parent.add_child(cushion)
	cushion.owner = root
	col_node.owner = root
	mesh_node.owner = root
	grass_bumper.owner = root

	cushion.set("cushion_number", num)
	cushion.set("inward_normal", inward_norm)
	cushion.set("cushion_type", ctype)


func _build_corner_flags(root: Node3D, decorations_root: Node3D) -> void:
	var battlement_mesh := BoxMesh.new()
	battlement_mesh.size = Vector3(2.35, 0.36, 2.35)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.32, 0.30, 0.28, 1.0)
	stone_mat.roughness = 0.85

	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.10
	pole_mesh.bottom_radius = 0.14
	pole_mesh.height = 4.2

	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.28, 0.18, 0.10, 1.0)
	pole_mat.roughness = 0.75

	var finial_mesh := SphereMesh.new()
	finial_mesh.radius = 0.24
	finial_mesh.height = 0.48

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.92, 0.76, 0.22, 1.0)
	gold_mat.metallic = 0.65
	gold_mat.roughness = 0.3

	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(1.8, 1.0, 0.08)

	var banner_tip_mesh := PrismMesh.new()
	banner_tip_mesh.size = Vector3(1.0, 0.9, 0.08)

	var red_banner_mat := StandardMaterial3D.new()
	red_banner_mat.albedo_color = Color(0.76, 0.14, 0.14, 1.0)
	red_banner_mat.roughness = 0.6

	var blue_banner_mat := StandardMaterial3D.new()
	blue_banner_mat.albedo_color = Color(0.16, 0.32, 0.74, 1.0)
	blue_banner_mat.roughness = 0.6

	var corner_positions: Array[Vector3] = [
		Vector3(-16.0, 3.5, -11.0),
		Vector3(16.0, 3.5, -11.0),
		Vector3(-16.0, 3.5, 11.0),
		Vector3(16.0, 3.5, 11.0),
	]

	for i: int in range(4):
		var flag_root := Node3D.new()
		flag_root.name = "CornerFlag_%d" % (i + 1)
		flag_root.position = corner_positions[i]
		decorations_root.add_child(flag_root)
		flag_root.owner = root

		var base_cap := MeshInstance3D.new()
		base_cap.name = "BattlementCap"
		base_cap.mesh = battlement_mesh
		base_cap.material_override = stone_mat
		base_cap.position = Vector3(0.0, 0.18, 0.0)
		flag_root.add_child(base_cap)
		base_cap.owner = root

		var pole := MeshInstance3D.new()
		pole.name = "FlagPole"
		pole.mesh = pole_mesh
		pole.material_override = pole_mat
		pole.position = Vector3(0.0, 2.1, 0.0)
		flag_root.add_child(pole)
		pole.owner = root

		var finial := MeshInstance3D.new()
		finial.name = "GoldFinial"
		finial.mesh = finial_mesh
		finial.material_override = gold_mat
		finial.position = Vector3(0.0, 4.3, 0.0)
		flag_root.add_child(finial)
		finial.owner = root

		var banner_mat := red_banner_mat if (i == 0 or i == 3) else blue_banner_mat
		var dir_sign: float = 1.0 if (i % 2 == 0) else -1.0

		var banner := MeshInstance3D.new()
		banner.name = "HeraldicBanner"
		banner.mesh = banner_mesh
		banner.material_override = banner_mat
		banner.position = Vector3(dir_sign * 0.95, 3.45, 0.0)
		flag_root.add_child(banner)
		banner.owner = root

		var trim := MeshInstance3D.new()
		trim.name = "GoldCrest"
		trim.mesh = banner_tip_mesh
		trim.material_override = gold_mat
		trim.position = Vector3(dir_sign * 0.85, 3.45, 0.02)
		trim.rotation_degrees = Vector3(0.0, 0.0, -90.0 * dir_sign)
		flag_root.add_child(trim)
		trim.owner = root


