extends CanvasLayer

const CARD_SCENE := preload("res://src/cards/card.tscn")
const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const BAR_Y_OFFSET := 2.8
const DEBUG_SHOW_DECK := true

@onready var player_health_bar: ProgressBar = %PlayerHealthBar
@onready var player_health_label: Label = %PlayerHealthLabel
@onready var player_bar_count_label: Label = %PlayerBarCountLabel as Label
@onready var health_bar_container: Control = %HealthBarContainer as Control
@onready var player_hp_bg: ColorRect = %HealthBarContainer/PlayerHealthBg as ColorRect
@onready var player_hp_damage: ColorRect = %HealthBarContainer/PlayerHealthDamage as ColorRect
@onready var player_hp_fill: ColorRect = %HealthBarContainer/PlayerHealthFill as ColorRect
@onready var enemy_bars_container: Control = %EnemyHealthBars
@onready var left_unit_panel: PanelContainer = %LeftUnitPanel
@onready var left_unit_list: VBoxContainer = %LeftUnitList
@onready var right_unit_panel: PanelContainer = %RightUnitPanel
@onready var right_unit_list: VBoxContainer = %RightUnitList

var _enemy_bars: Dictionary = {}
var _unit_side_cards: Dictionary = {}
var _prev_player_hp: int = 100
var _player_max_hp: int = 100
var _hide_enemy_bars: bool = false

func _ready() -> void:
	_setup_side_panels()
	_setup_player_health_bar()
	if health_bar_container:
		health_bar_container.resized.connect(func() -> void: _set_hp_fill(_prev_player_hp, _player_max_hp))
	_bind_timing_signals()


func _setup_side_panels() -> void:
	if left_unit_panel != null:
		var left_box := StyleBoxFlat.new()
		left_box.bg_color = Color(0.08, 0.07, 0.06, 0.42)
		left_box.border_color = Color(0.46, 0.34, 0.20, 0.55)
		left_box.set_border_width_all(2)
		left_box.set_corner_radius_all(12)
		# Extra left margin compensates for anchor_left = -0.024 (~36px off-screen)
		# so unit information stays well inside the visible screen edge.
		left_box.content_margin_left = 48.0
		left_box.content_margin_right = 10.0
		left_box.content_margin_top = 10.0
		left_box.content_margin_bottom = 10.0
		left_unit_panel.add_theme_stylebox_override("panel", left_box)
	if right_unit_panel != null:
		var right_box := StyleBoxFlat.new()
		right_box.bg_color = Color(0.08, 0.07, 0.06, 0.42)
		right_box.border_color = Color(0.46, 0.34, 0.20, 0.55)
		right_box.set_border_width_all(2)
		right_box.set_corner_radius_all(12)
		# Extra right margin compensates for anchor_right = 1.024 (~36px off-screen)
		# so unit information stays well inside the visible screen edge.
		right_box.content_margin_left = 10.0
		right_box.content_margin_right = 48.0
		right_box.content_margin_top = 10.0
		right_box.content_margin_bottom = 10.0
		right_unit_panel.add_theme_stylebox_override("panel", right_box)


func _bind_timing_signals() -> void:
	var tm := _find_timing_manager()
	if tm == null:
		return
	if not tm.timing_changed.is_connected(_on_timing_changed):
		tm.timing_changed.connect(_on_timing_changed)
	_hide_enemy_bars_by_timing(tm.get_current_timing())


func _find_timing_manager() -> TimingManager:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("TimingManager") as TimingManager
		if sibling != null:
			return sibling
	if is_inside_tree():
		return get_tree().get_first_node_in_group("timing_manager") as TimingManager
	return null


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	_hide_enemy_bars_by_timing(new_timing)


func _hide_enemy_bars_by_timing(timing: String) -> void:
	_set_enemy_bars_hidden(timing == TimingManager.TIMING_PUCK_PUCK or timing == TimingManager.TIMING_PLAY)

func _set_enemy_bars_hidden(hidden: bool) -> void:
	_hide_enemy_bars = hidden
	if enemy_bars_container != null:
		enemy_bars_container.visible = not hidden


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or _hide_enemy_bars:
		return

	# Update existing bar positions
	var to_remove: Array = []
	for enemy in _enemy_bars:
		if not is_instance_valid(enemy) or enemy.is_dead:
			to_remove.append(enemy)
		else:
			var bar_data: Dictionary = _enemy_bars[enemy]
			var world_pos: Vector3 = enemy.global_position + Vector3(0, BAR_Y_OFFSET, 0)
			if camera.is_position_behind(world_pos):
				for node in bar_data.values():
					(node as Control).visible = false
				continue
			var screen_pos := camera.unproject_position(world_pos)
			position_bar_widget(bar_data, screen_pos)

	_scan_for_new_enemies()

func position_bar_widget(bar_data: Dictionary, screen_pos: Vector2) -> void:
	var bg := bar_data["background"] as ColorRect
	var fill := bar_data["fill"] as ColorRect
	var label := bar_data["label"] as Label
	bg.visible = true
	fill.visible = true
	label.visible = true
	var x := screen_pos.x - BAR_WIDTH / 2.0
	var y := screen_pos.y
	bg.position = Vector2(x, y)
	fill.position = Vector2(x, y)
	label.position = Vector2(x, y + BAR_HEIGHT + 2)

func _scan_for_new_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyAdventurer and not enemy in _enemy_bars and not (enemy as EnemyAdventurer).is_dead:
			_create_enemy_bar(enemy)

func _create_enemy_bar(enemy: EnemyAdventurer) -> void:
	var bar_data := {}
	_enemy_bars[enemy] = bar_data

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.15, 0.85)
	bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	enemy_bars_container.add_child(bg)
	bar_data["background"] = bg

	var fill := ColorRect.new()
	fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	enemy_bars_container.add_child(fill)
	bar_data["fill"] = fill

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(BAR_WIDTH, 14)
	label.text = "%d/%d" % [enemy.current_hp, enemy.max_hp]
	enemy_bars_container.add_child(label)
	bar_data["label"] = label

	_bar_set_color(fill, float(enemy.current_hp) / float(enemy.max_hp))

	enemy.health_changed.connect(_on_enemy_health_changed.bind(enemy))
	enemy.died.connect(_on_enemy_died.bind(enemy))
	_create_unit_side_card(enemy)

func _on_enemy_health_changed(current: int, maximum: int, enemy: EnemyAdventurer) -> void:
	if enemy in _unit_side_cards:
		var side_label := _unit_side_cards[enemy].get("hp_label") as Label
		if side_label != null:
			side_label.text = "HP: %d/%d" % [current, maximum]
	if not enemy in _enemy_bars:
		return
	var bar_data: Dictionary = _enemy_bars[enemy]
	var ratio := float(current) / float(maximum)
	var fill := bar_data["fill"] as ColorRect
	fill.size.x = BAR_WIDTH * ratio
	var label := bar_data["label"] as Label
	label.text = "%d/%d" % [current, maximum]
	_bar_set_color(fill, ratio)

func _on_enemy_died(enemy: EnemyAdventurer) -> void:
	_remove_enemy_bar(enemy)
	if enemy in _unit_side_cards:
		var card_node := _unit_side_cards[enemy].get("panel") as Control
		if is_instance_valid(card_node):
			card_node.queue_free()
		_unit_side_cards.erase(enemy)


func _create_unit_side_card(enemy: EnemyAdventurer) -> void:
	if left_unit_list == null or right_unit_list == null:
		return
	var target_list := left_unit_list if left_unit_list.get_child_count() <= right_unit_list.get_child_count() else right_unit_list
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.11, 0.10, 0.62)
	box.border_color = EnemyAdventurer.CLASS_CONFIG[enemy.adventurer_class]["color"]
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", box)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = enemy.name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 0.76, 1.0))
	vbox.add_child(name_lbl)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP: %d/%d" % [enemy.current_hp, enemy.max_hp]
	hp_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hp_lbl)

	target_list.add_child(card)
	_unit_side_cards[enemy] = {"panel": card, "hp_label": hp_lbl}

func _remove_enemy_bar(enemy: EnemyAdventurer) -> void:
	if not enemy in _enemy_bars:
		return
	var bar_data: Dictionary = _enemy_bars[enemy]
	for node in bar_data.values():
		(node as Control).queue_free()
	_enemy_bars.erase(enemy)

func _bar_set_color(fill: ColorRect, ratio: float) -> void:
	if ratio > 0.6:
		fill.color = Color(0.25, 0.85, 0.25, 0.9)
	elif ratio > 0.3:
		fill.color = Color(0.9, 0.8, 0.15, 0.9)
	else:
		fill.color = Color(0.9, 0.2, 0.15, 0.9)


# --- Player Health ---

const HP_BAR_WIDTH := 200.0

func _setup_player_health_bar() -> void:
	var player := get_tree().get_first_node_in_group("player") as BaseBossMonster
	if not player:
		return
	player.health_changed.connect(_on_player_health_changed)
	player.bars_changed.connect(_on_player_bars_changed)
	player.bar_broken.connect(_on_player_bar_broken)
	player.died.connect(_on_player_died)
	_set_hp_fill(player.current_hp, player.max_hp)
	_on_player_bars_changed(player.bars_remaining, player.current_hp, player.bar_max_hp)

func _get_hp_bar_width() -> float:
	if health_bar_container != null and health_bar_container.size.x > 10.0:
		return health_bar_container.size.x
	return HP_BAR_WIDTH

func _set_hp_fill(current: int, maximum: int) -> void:
	_player_max_hp = maxi(maximum, 1)
	var w: float = _get_hp_bar_width() * float(current) / float(_player_max_hp)
	if player_hp_fill:
		player_hp_fill.offset_right = w

func _on_player_health_changed(current: int, maximum: int) -> void:
	if current < _prev_player_hp:
		var old_right: float = _get_hp_bar_width() * float(_prev_player_hp) / float(maxi(maximum, 1))
		_set_hp_fill(current, maximum)
		_flash_damage(old_right)
	else:
		_set_hp_fill(current, maximum)
	_prev_player_hp = current

func _on_player_bars_changed(bars: int, current: int, maximum: int) -> void:
	if player_health_label:
		player_health_label.text = Loc.t("hp_format", {"hp": current, "max": maximum})
	if player_bar_count_label:
		player_bar_count_label.text = Loc.t("bar_count", {"count": bars})

func _on_player_bar_broken(_bars_remaining: int) -> void:
	_flash_bar_break()

func _flash_damage(old_right: float) -> void:
	if not player_hp_damage or not player_hp_fill:
		return
	player_hp_damage.visible = true
	player_hp_damage.offset_left = player_hp_fill.offset_right
	player_hp_damage.offset_right = old_right
	var tween := create_tween()
	tween.tween_property(player_hp_damage, "offset_right", player_hp_fill.offset_right, 0.5)
	tween.tween_callback(func(): player_hp_damage.visible = false)

func _flash_bar_break() -> void:
	if not player_hp_damage:
		return
	player_hp_damage.visible = true
	player_hp_damage.offset_left = 0
	player_hp_damage.offset_right = _get_hp_bar_width()
	player_hp_damage.color = Color(0.9, 0.15, 0.15, 0.8)

	
	if health_bar_container:
		var orig_pos: Vector2 = health_bar_container.position
		# Shake animation: 5 quick jitters then back to origin
		var shake := create_tween()
		for i in 5:
			var off := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
			shake.tween_property(health_bar_container, "position", orig_pos + off, 0.05)
		shake.tween_property(health_bar_container, "position", orig_pos, 0.05)
	# Color fade on the damage bar
	# var fade := create_tween()
	# fade.tween_property(player_hp_damage, "color:a", 0.0, 0.5)

func _on_player_died() -> void:
	if player_health_label:
		player_health_label.text = Loc.t("defeated")
		
		
func show_warning(message: String) -> void:
	# 1. Instantiate a Label in memory
	var label := Label.new()
	label.text = message
	
	# 2. Position it at the top-center of the screen
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 50)
	
	# 3. Optional styling (Yellow text + bold shadow)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 22)
	
	add_child(label)
	
	# 4. Animate fade-in -> hold -> fade-out -> auto-delete
	label.modulate.a = 0.0 # Start invisible
	
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)  # Fade in (0.2s)
	tween.tween_interval(1.5)                            # Stay on screen (1.5s)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)  # Fade out (0.5s)
	tween.tween_callback(label.queue_free)               # Clean up RAM
