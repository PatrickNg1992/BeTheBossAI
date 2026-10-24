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
