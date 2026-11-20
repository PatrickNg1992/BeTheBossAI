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
	_make_double_arrow()
	_make_puck_puck_banner()
	_make_pocket_swirl()
	_make_grass_tile("grass_dark.png", Color(0.18, 0.46, 0.19), Color(0.12, 0.33, 0.13), 101)
	_make_grass_tile("grass_light.png", Color(0.28, 0.58, 0.26), Color(0.20, 0.44, 0.19), 202)
	_make_wood_cushion("wood_dark.png", Color(0.38, 0.24, 0.12), Color(0.22, 0.14, 0.07), 303)
	_make_wood_cushion("wood_light.png", Color(0.52, 0.35, 0.18), Color(0.32, 0.21, 0.10), 404)
	_make_unit_avatars_and_class_marks()
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


## 22x18 double right-arrow (fast-forward) icon in gold/bone.
func _make_double_arrow() -> void:
	var w := 22
	var h := 18
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.96, 0.84, 0.42, 1.0)
	var shade := Color(0.68, 0.52, 0.20, 1.0)
	var cy := (h - 1) / 2.0
	for y in range(h):
		var dy := absf(float(y) - cy)
		if dy > 6.0:
			continue
		var reach := int(roundf(6.0 - dy))
		for x in range(2, 2 + reach + 1):
			var is_edge := (x == 2 or x == 2 + reach)
			img.set_pixel(x, y, shade if is_edge else gold)
		for x in range(11, 11 + reach + 1):
			var is_edge := (x == 11 or x == 11 + reach)
			img.set_pixel(x, y, shade if is_edge else gold)
	_save(img, "double_arrow.png")


## 480x84 medieval crimson-and-gold ribbon banner image for "Puck-puck Time!".
func _make_puck_puck_banner() -> void:
	var w := 480
	var h := 84
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 777
	noise.frequency = 0.06
	var cy := (h - 1) / 2.0
	for y in range(h):
		var dy := absf(float(y) - cy)
		if dy > 36.0:
			continue
		# Swallowtail ribbon notch on left and right ends
		var indent := int(roundf((36.0 - dy) * 0.78))
		var left_x := 6 + indent
		var right_x := w - 7 - indent
		for x in range(left_x, right_x + 1):
			var edge_dist_x := mini(x - left_x, right_x - x)
			var edge_dist_y := 36.0 - dy
			var n := noise.get_noise_2d(float(x) * 0.5, float(y) * 1.2) * 0.06
			var col := Color(0.58, 0.12, 0.11, 0.96).lightened(n + (1.0 - dy / 36.0) * 0.10)
			# Outer dark iron/shadow trim
			if edge_dist_y < 2.0 or edge_dist_x < 2:
				col = Color(0.18, 0.10, 0.06, 0.98)
			# Gold outer border and inner filigree line
			elif edge_dist_y < 5.0 or edge_dist_x < 5:
				col = Color(0.95, 0.76, 0.24, 1.0)
			elif (edge_dist_y >= 7.0 and edge_dist_y < 8.5) or (edge_dist_x >= 8 and edge_dist_x <= 9):
				col = Color(0.82, 0.62, 0.18, 0.90)
			img.set_pixel(x, y, col)
	# Gold diamond emblems near both ends
	for cx in [58, w - 59]:
		for y in range(int(cy) - 10, int(cy) + 11):
			for x in range(cx - 10, cx + 11):
				var md: float = absf(float(x - cx)) + absf(float(y) - cy)
				if md <= 9.0:
					img.set_pixel(x, y, Color(0.98, 0.84, 0.32, 1.0) if md <= 6.0 else Color(0.35, 0.20, 0.08, 1.0))
	_save(img, "puck_puck_banner.png")


## 64x64 black-hole clockwise swirl tile texture for Pocket Area floor blocks.
func _make_pocket_swirl() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var cx := (s - 1) / 2.0
	var cy := (s - 1) / 2.0
	var max_r := s * 0.48
	var outer_grass := Color(0.14, 0.32, 0.15, 1.0)
	var abyss_black := Color(0.02, 0.02, 0.03, 1.0)
	var swirl_arm := Color(0.24, 0.18, 0.36, 1.0)
	var swirl_glow := Color(0.45, 0.32, 0.62, 1.0)
	for y in range(s):
		for x in range(s):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var r := sqrt(dx * dx + dy * dy)
			var norm_r := clampf(r / max_r, 0.0, 1.4)
			if norm_r >= 1.0:
				var border := outer_grass.darkened(0.25) if (x < 2 or x >= s - 2 or y < 2 or y >= s - 2) else outer_grass
				img.set_pixel(x, y, border)
				continue
			# Clockwise spiral arms: angle + k * ln(r)
			var angle := atan2(dy, dx)
			var spiral_phase := angle * 4.0 + (1.0 - norm_r) * 14.0
			var arm := 0.5 + 0.5 * sin(spiral_phase)
			var c := abyss_black
			if norm_r > 0.16:
				var arm_strength := pow(arm, 2.2) * (1.0 - absf(norm_r - 0.52) * 1.35)
				arm_strength = clampf(arm_strength, 0.0, 1.0)
				c = abyss_black.lerp(swirl_arm, arm_strength * 0.85)
				if arm_strength > 0.65:
					c = c.lerp(swirl_glow, (arm_strength - 0.65) * 1.8)
				if norm_r > 0.82:
					var edge_t := (norm_r - 0.82) / 0.18
					c = c.lerp(outer_grass.darkened(0.35), edge_t)
			img.set_pixel(x, y, c)
	_save(img, "pocket_swirl.png")





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


func _fill_circle(img: Image, cx: float, cy: float, r: float, col: Color, outline_col: Color = Color(0, 0, 0, 0), outline_w: float = 0.0) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var min_x := maxi(0, int(floor(cx - r - outline_w - 1)))
	var max_x := mini(w - 1, int(ceil(cx + r + outline_w + 1)))
	var min_y := maxi(0, int(floor(cy - r - outline_w - 1)))
	var max_y := mini(h - 1, int(ceil(cy + r + outline_w + 1)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d := Vector2(float(x) - cx, float(y) - cy).length()
			if d <= r:
				img.set_pixel(x, y, col)
			elif outline_w > 0.0 and d <= r + outline_w:
				img.set_pixel(x, y, outline_col)


func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color, outline_col: Color = Color(0, 0, 0, 0), outline_w: float = 0.0) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var nx := (float(x) - cx) / maxf(rx, 0.1)
			var ny := (float(y) - cy) / maxf(ry, 0.1)
			var d := sqrt(nx * nx + ny * ny)
			if d <= 1.0:
				img.set_pixel(x, y, col)
			elif outline_w > 0.0 and d <= 1.0 + outline_w / minf(rx, ry):
				img.set_pixel(x, y, outline_col)


func _fill_rect_outlined(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color, outline_col: Color = Color(0.10, 0.07, 0.05, 1.0), bw: int = 1) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, y0), mini(h, y0 + rh)):
		for x in range(maxi(0, x0), mini(w, x0 + rw)):
			var is_b := (x < x0 + bw or x >= x0 + rw - bw or y < y0 + bw or y >= y0 + rh - bw)
			img.set_pixel(x, y, outline_col if is_b and bw > 0 else col)


func _make_unit_avatars_and_class_marks() -> void:
	_make_avatar_boss_dragon()
	_make_avatar_knight()
	_make_avatar_knight_variant("avatar_knight_2.png", Color(0.88, 0.22, 0.20), Color(0.72, 0.76, 0.84), true)
	_make_avatar_knight_variant("avatar_knight_3.png", Color(0.95, 0.78, 0.22), Color(0.54, 0.58, 0.66), false)
	_make_avatar_warrior()
	_make_avatar_warrior_variant("avatar_warrior_2.png", Color(0.18, 0.16, 0.15), Color(0.86, 0.66, 0.48), true)
	_make_avatar_warrior_variant("avatar_warrior_3.png", Color(0.82, 0.68, 0.24), Color(0.92, 0.72, 0.56), false)
	_make_avatar_ranger()
	_make_avatar_ranger_variant("avatar_ranger_2.png", Color(0.44, 0.28, 0.14), Color(0.92, 0.24, 0.20), true)
	_make_avatar_ranger_variant("avatar_ranger_3.png", Color(0.18, 0.36, 0.32), Color(0.32, 0.86, 0.94), false)
	_make_avatar_mage()
	_make_avatar_mage_variant("avatar_mage_2.png", Color(0.68, 0.16, 0.22), Color(1.0, 0.78, 0.22), true)
	_make_avatar_mage_variant("avatar_mage_3.png", Color(0.16, 0.38, 0.68), Color(0.62, 0.96, 0.76), false)
	_make_avatar_minion()
	_make_class_mark_icons()


func _paint_avatar_backdrop(img: Image, bg_top: Color, bg_bot: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		var t := float(y) / float(maxi(h - 1, 1))
		var base := bg_top.lerp(bg_bot, t)
		for x in range(w):
			# Subtle radial vignette
			var dx := (float(x) - w * 0.5) / (w * 0.5)
			var dy := (float(y) - h * 0.5) / (h * 0.5)
			var vig := clampf(1.0 - (dx * dx + dy * dy) * 0.25, 0.65, 1.0)
			img.set_pixel(x, y, Color(base.r * vig, base.g * vig, base.b * vig, 1.0))


## 96x64 Cartoon Fire Dragon Boss Monster avatar: volcanic flame backdrop,
## curving golden horns, large crimson dragon head filling the frame, glowing amber eyes, and fire breath.
func _make_avatar_boss_dragon() -> void:
	var w := 96
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.32, 0.08, 0.05), Color(0.14, 0.03, 0.03))
	var outline := Color(0.10, 0.04, 0.03, 1.0)

	# Glowing background flames
	_fill_circle(img, 14, 42, 18, Color(0.95, 0.35, 0.08, 0.85))
	_fill_circle(img, 82, 40, 18, Color(0.95, 0.42, 0.10, 0.85))
	_fill_circle(img, 48, 32, 28, Color(0.98, 0.65, 0.14, 0.85))

	# Large curving golden horns (left and right)
	for i in range(20):
		var t := float(i) / 19.0
		var lx := 28.0 - t * 22.0
		var ly := 22.0 - sin(t * 2.1) * 17.0
		var rx := 68.0 + t * 22.0
		var ry := 22.0 - sin(t * 2.1) * 17.0
		var hr := lerpf(6.5, 2.2, t)
		var hcol := Color(0.96, 0.80, 0.28).lerp(Color(0.58, 0.38, 0.12), t * 0.6)
		_fill_circle(img, lx, ly, hr, hcol, outline, 1.8)
		_fill_circle(img, rx, ry, hr, hcol, outline, 1.8)

	# Large Dragon head & snout (cartoon bold crimson with dark outline, filling the frame)
	_fill_ellipse(img, 48, 29, 25, 19, Color(0.78, 0.14, 0.12), outline, 2.2)
	_fill_ellipse(img, 48, 41, 20, 14, Color(0.88, 0.20, 0.15), outline, 2.2)
	# Golden under-jaw / chest scales
	_fill_ellipse(img, 48, 53, 16, 9, Color(0.96, 0.74, 0.24), outline, 1.8)

	# Fierce glowing yellow-orange eyes + slit pupils
	_fill_ellipse(img, 36, 27, 6.8, 4.6, Color(1.0, 0.88, 0.18), outline, 1.6)
	_fill_ellipse(img, 60, 27, 6.8, 4.6, Color(1.0, 0.88, 0.18), outline, 1.6)
	_fill_ellipse(img, 37, 27, 2.0, 3.8, Color(0.15, 0.03, 0.02))
	_fill_ellipse(img, 59, 27, 2.0, 3.8, Color(0.15, 0.03, 0.02))

	# Nostrils + white fangs + fire breath wisps
	_fill_circle(img, 42, 40, 2.5, outline)
	_fill_circle(img, 54, 40, 2.5, outline)
	_fill_circle(img, 36, 50, 3.2, Color(0.98, 0.96, 0.90), outline, 1.2)
	_fill_circle(img, 60, 50, 3.2, Color(0.98, 0.96, 0.90), outline, 1.2)
	_fill_circle(img, 20, 51, 7.0, Color(1.0, 0.55, 0.12), Color(0.95, 0.22, 0.06), 1.8)
	_fill_circle(img, 76, 51, 7.0, Color(1.0, 0.55, 0.12), Color(0.95, 0.22, 0.06), 1.8)
	_save(img, "avatar_boss_dragon.png")


## 64x64 Cartoon Knight avatar: royal blue crest plume, silver great-helm with gold cross visor.
func _make_avatar_knight() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.14, 0.22, 0.44), Color(0.07, 0.10, 0.22))
	var outline := Color(0.08, 0.08, 0.12, 1.0)

	# Blue feather plume on top
	_fill_ellipse(img, 32, 12, 12, 7, Color(0.22, 0.52, 0.96), outline, 2.0)
	# Pauldrons / shoulders
	_fill_ellipse(img, 32, 54, 22, 11, Color(0.62, 0.68, 0.78), outline, 2.0)
	# Silver steel great-helm dome
	_fill_ellipse(img, 32, 33, 16, 18, Color(0.78, 0.83, 0.90), outline, 2.0)
	# Faceplate shading
	_fill_rect_outlined(img, 18, 30, 28, 18, Color(0.68, 0.73, 0.82), outline, 2)
	# Gold vertical & horizontal cross trim on helm
	_fill_rect_outlined(img, 30, 18, 4, 30, Color(0.95, 0.78, 0.24), outline, 1)
	_fill_rect_outlined(img, 19, 29, 26, 5, Color(0.95, 0.78, 0.24), outline, 1)
	# Dark eye slits
	_fill_rect_outlined(img, 21, 30, 8, 3, outline, outline, 0)
	_fill_rect_outlined(img, 35, 30, 8, 3, outline, outline, 0)
	_save(img, "avatar_knight.png")


## 64x64 Cartoon Warrior avatar: crimson horned/crested iron helm, fierce brows, beard & broadsword.
func _make_avatar_warrior() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.42, 0.14, 0.12), Color(0.20, 0.06, 0.06))
	var outline := Color(0.10, 0.05, 0.04, 1.0)

	# Shoulders / fur cloak
	_fill_ellipse(img, 32, 54, 22, 11, Color(0.45, 0.24, 0.14), outline, 2.0)
	# Face (warm skin tone)
	_fill_circle(img, 32, 35, 14, Color(0.95, 0.74, 0.56), outline, 2.0)
	# Reddish-brown braided beard
	_fill_ellipse(img, 32, 46, 13, 8, Color(0.62, 0.24, 0.12), outline, 2.0)
	# Iron viking/barbarian helm + side wings/horns
	_fill_circle(img, 15, 22, 5, Color(0.92, 0.86, 0.72), outline, 1.8)
	_fill_circle(img, 49, 22, 5, Color(0.92, 0.86, 0.72), outline, 1.8)
	_fill_ellipse(img, 32, 22, 16, 10, Color(0.52, 0.54, 0.60), outline, 2.0)
	_fill_rect_outlined(img, 17, 25, 30, 5, Color(0.84, 0.22, 0.18), outline, 1)
	# Eyes
	_fill_circle(img, 26, 34, 2.2, outline)
	_fill_circle(img, 38, 34, 2.2, outline)
	_save(img, "avatar_warrior.png")


## 64x64 Cartoon Ranger avatar: forest hood with golden feather, keen eyes & leather cloak.
func _make_avatar_ranger() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.36, 0.32, 0.10), Color(0.16, 0.15, 0.05))
	var outline := Color(0.09, 0.08, 0.04, 1.0)

	# Cloak shoulders
	_fill_ellipse(img, 32, 54, 21, 11, Color(0.22, 0.48, 0.20), outline, 2.0)
	# Hood outer cowl
	_fill_ellipse(img, 32, 31, 18, 19, Color(0.28, 0.58, 0.24), outline, 2.0)
	# Face inside hood
	_fill_circle(img, 32, 35, 12, Color(0.95, 0.78, 0.60), outline, 1.8)
	# Golden feather tucked in hood cap
	_fill_ellipse(img, 45, 16, 4, 9, Color(0.98, 0.84, 0.22), outline, 1.5)
	# Keen emerald eyes + bandana mask
	_fill_circle(img, 27, 33, 2.3, Color(0.14, 0.45, 0.18), outline, 0.8)
	_fill_circle(img, 37, 33, 2.3, Color(0.14, 0.45, 0.18), outline, 0.8)
	_fill_ellipse(img, 32, 43, 11, 6, Color(0.46, 0.30, 0.16), outline, 1.5)
	_save(img, "avatar_ranger.png")


## 64x64 Cartoon Mage avatar: arcane purple pointed wizard hat with gold band, glowing eyes & staff orb.
func _make_avatar_mage() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.28, 0.12, 0.42), Color(0.12, 0.05, 0.20))
	var outline := Color(0.08, 0.04, 0.12, 1.0)

	# Purple arcane robes
	_fill_ellipse(img, 32, 54, 20, 11, Color(0.48, 0.20, 0.68), outline, 2.0)
	# Face & white sage beard
	_fill_circle(img, 32, 36, 12, Color(0.94, 0.78, 0.64), outline, 1.8)
	_fill_ellipse(img, 32, 46, 10, 8, Color(0.92, 0.92, 0.96), outline, 1.5)
	# Glowing cyan-gold arcane eyes
	_fill_circle(img, 27, 35, 2.5, Color(0.45, 0.92, 1.0), outline, 1.0)
	_fill_circle(img, 37, 35, 2.5, Color(0.45, 0.92, 1.0), outline, 1.0)
	# Pointed wizard hat cone + wide brim + gold buckle band
	for i in range(18):
		var t := float(i) / 17.0
		var hy := 25.0 - t * 18.0
		var hr := lerpf(13.0, 2.0, t)
		_fill_circle(img, 32.0 + t * 4.0, hy, hr, Color(0.54, 0.22, 0.76), outline, 1.5)
	_fill_ellipse(img, 32, 25, 21, 5, Color(0.46, 0.18, 0.66), outline, 2.0)
	_fill_rect_outlined(img, 21, 21, 22, 4, Color(0.96, 0.78, 0.24), outline, 1)
	_save(img, "avatar_mage.png")


func _make_avatar_knight_variant(fname: String, plume_col: Color, armor_col: Color, winged: bool) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.16, 0.24, 0.42), Color(0.08, 0.11, 0.20))
	var outline := Color(0.08, 0.08, 0.12, 1.0)
	if winged:
		_fill_ellipse(img, 14, 24, 5, 11, plume_col, outline, 1.8)
		_fill_ellipse(img, 50, 24, 5, 11, plume_col, outline, 1.8)
	else:
		_fill_circle(img, 32, 11, 8, plume_col, outline, 1.8)
	_fill_ellipse(img, 32, 54, 22, 11, armor_col.darkened(0.15), outline, 2.0)
	_fill_ellipse(img, 32, 34, 16, 17, armor_col, outline, 2.0)
	if winged:
		# T-visor barbute helm
		_fill_rect_outlined(img, 21, 28, 22, 4, outline, outline, 0)
		_fill_rect_outlined(img, 30, 28, 4, 16, outline, outline, 0)
	else:
		# Open visor paladin with glowing eyes & gold crown band
		_fill_rect_outlined(img, 18, 22, 28, 5, Color(0.96, 0.80, 0.24), outline, 1)
		_fill_ellipse(img, 32, 35, 11, 8, Color(0.95, 0.78, 0.62), outline, 1.5)
		_fill_circle(img, 27, 34, 2.2, outline)
		_fill_circle(img, 37, 34, 2.2, outline)
	_save(img, fname)


func _make_avatar_warrior_variant(fname: String, hair_col: Color, skin_col: Color, mohawk: bool) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.40, 0.16, 0.12), Color(0.18, 0.07, 0.05))
	var outline := Color(0.10, 0.05, 0.04, 1.0)
	_fill_ellipse(img, 32, 54, 22, 11, Color(0.42, 0.20, 0.14), outline, 2.0)
	_fill_circle(img, 32, 35, 14, skin_col, outline, 2.0)
	if mohawk:
		# Berserker crest & warpaint
		_fill_ellipse(img, 32, 14, 6, 10, Color(0.88, 0.18, 0.16), outline, 1.8)
		_fill_rect_outlined(img, 19, 32, 10, 3, Color(0.86, 0.18, 0.16), outline, 0)
		_fill_circle(img, 25, 34, 2.3, outline)
		_fill_circle(img, 39, 34, 2.3, outline)
		_fill_ellipse(img, 32, 46, 12, 7, hair_col, outline, 1.8)
	else:
		# Twin-braid valkyrie/gladiator with bronze circlet & eyepatch
		_fill_ellipse(img, 32, 24, 16, 9, hair_col, outline, 1.8)
		_fill_rect_outlined(img, 18, 25, 28, 4, Color(0.94, 0.74, 0.22), outline, 1)
		_fill_circle(img, 26, 34, 3.6, outline)
		_fill_circle(img, 38, 34, 2.3, outline)
	_save(img, fname)


func _make_avatar_ranger_variant(fname: String, hood_col: Color, accent_col: Color, wolf_pelt: bool) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.32, 0.30, 0.12), Color(0.15, 0.14, 0.06))
	var outline := Color(0.09, 0.08, 0.04, 1.0)
	_fill_ellipse(img, 32, 54, 21, 11, hood_col.darkened(0.18), outline, 2.0)
	if wolf_pelt:
		# Wolf-ear scout hood
		_fill_circle(img, 19, 17, 6, hood_col, outline, 1.8)
		_fill_circle(img, 45, 17, 6, hood_col, outline, 1.8)
	_fill_ellipse(img, 32, 32, 18, 18, hood_col, outline, 2.0)
	_fill_circle(img, 32, 36, 12, Color(0.94, 0.76, 0.58), outline, 1.8)
	_fill_rect_outlined(img, 19, 24, 26, 4, accent_col, outline, 1)
	_fill_circle(img, 27, 34, 2.3, outline)
	_fill_circle(img, 37, 34, 2.3, outline)
	_save(img, fname)


func _make_avatar_mage_variant(fname: String, robe_col: Color, eye_col: Color, horned_crown: bool) -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.26, 0.12, 0.38), Color(0.11, 0.05, 0.18))
	var outline := Color(0.08, 0.04, 0.12, 1.0)
	_fill_ellipse(img, 32, 54, 20, 11, robe_col.darkened(0.15), outline, 2.0)
	_fill_ellipse(img, 32, 33, 17, 18, robe_col, outline, 2.0)
	_fill_circle(img, 32, 36, 11, Color(0.92, 0.78, 0.66), outline, 1.8)
	_fill_circle(img, 27, 35, 2.6, eye_col, outline, 0.9)
	_fill_circle(img, 37, 35, 2.6, eye_col, outline, 0.9)
	if horned_crown:
		# Pyromancer golden diadem with ruby gem
		_fill_rect_outlined(img, 20, 22, 24, 5, Color(0.96, 0.80, 0.24), outline, 1)
		_fill_circle(img, 32, 23, 3.8, Color(0.95, 0.18, 0.22), outline, 1.0)
	else:
		# Mystic floating crystal halo
		_fill_circle(img, 32, 14, 5.0, eye_col, outline, 1.5)
	_save(img, fname)


## 64x64 Cartoon Minion (little fire imp/drake) avatar.
func _make_avatar_minion() -> void:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	_paint_avatar_backdrop(img, Color(0.24, 0.16, 0.12), Color(0.11, 0.07, 0.05))
	var outline := Color(0.08, 0.04, 0.03, 1.0)
	_fill_circle(img, 20, 20, 5, Color(0.85, 0.68, 0.25), outline, 1.5)
	_fill_circle(img, 44, 20, 5, Color(0.85, 0.68, 0.25), outline, 1.5)
	_fill_circle(img, 32, 34, 15, Color(0.76, 0.26, 0.16), outline, 2.0)
	_fill_circle(img, 26, 32, 3.2, Color(1.0, 0.86, 0.20), outline, 1.2)
	_fill_circle(img, 38, 32, 3.2, Color(1.0, 0.86, 0.20), outline, 1.2)
	_save(img, "avatar_minion.png")


## 24x24 Medieval Class Mark icons for upper-right of Enemy Adventurer Unit Displays:
## - Knight: Heraldic Blue-and-Gold Shield
## - Warrior: Crossed Broadsword
## - Ranger: Hunting Bow & Arrow
## - Mage: Arcane Staff / Crystal Star
func _make_class_mark_icons() -> void:
	var s := 24
	var outline := Color(0.08, 0.06, 0.05, 1.0)

	# 1. Knight Shield
	var img_k := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img_k.fill(Color(0, 0, 0, 0))
	_fill_ellipse(img_k, 12, 11, 8, 9, Color(0.24, 0.52, 0.94), Color(0.95, 0.78, 0.26), 2.0)
	_fill_rect_outlined(img_k, 11, 4, 2, 14, Color(0.96, 0.82, 0.30), outline, 0)
	_fill_rect_outlined(img_k, 6, 10, 12, 2, Color(0.96, 0.82, 0.30), outline, 0)
	_save(img_k, "class_knight.png")

	# 2. Warrior Broadsword
	var img_w := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img_w.fill(Color(0, 0, 0, 0))
	_fill_circle(img_w, 12, 12, 9, Color(0.78, 0.18, 0.16), Color(0.95, 0.76, 0.24), 1.5)
	_fill_rect_outlined(img_w, 11, 4, 3, 11, Color(0.92, 0.94, 0.98), outline, 0)
	_fill_rect_outlined(img_w, 7, 14, 11, 2, Color(0.96, 0.80, 0.26), outline, 0)
	_fill_rect_outlined(img_w, 11, 16, 3, 4, Color(0.45, 0.26, 0.12), outline, 0)
	_save(img_w, "class_warrior.png")

	# 3. Ranger Bow & Arrow
	var img_r := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img_r.fill(Color(0, 0, 0, 0))
	_fill_circle(img_r, 12, 12, 9, Color(0.22, 0.56, 0.22), Color(0.95, 0.82, 0.24), 1.5)
	_fill_rect_outlined(img_r, 11, 5, 2, 14, Color(0.96, 0.88, 0.38), outline, 0)
	_fill_circle(img_r, 12, 6, 2.5, Color(0.96, 0.96, 0.96))
	_save(img_r, "class_ranger.png")

	# 4. Mage Arcane Orb/Star
	var img_m := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img_m.fill(Color(0, 0, 0, 0))
	_fill_circle(img_m, 12, 12, 9, Color(0.52, 0.20, 0.78), Color(0.95, 0.78, 0.26), 1.5)
	_fill_circle(img_m, 12, 12, 4.5, Color(0.48, 0.94, 1.0), Color(1.0, 1.0, 1.0), 1.0)
	_save(img_m, "class_mage.png")



