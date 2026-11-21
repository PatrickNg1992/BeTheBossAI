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

var unit_information_board: UnitInformationBoard = null
var _prev_player_hp: int = 100
var _player_max_hp: int = 100

func _ready() -> void:
	_setup_side_panels()
	_setup_unit_information_board()
	_setup_player_health_bar()
	if health_bar_container:
		health_bar_container.resized.connect(func() -> void: _set_hp_fill(_prev_player_hp, _player_max_hp))
	if enemy_bars_container != null:
		enemy_bars_container.visible = false


func _setup_side_panels() -> void:
	if left_unit_panel != null:
		var left_box := StyleBoxFlat.new()
		left_box.bg_color = Color(0.08, 0.06, 0.05, 0.78)
		left_box.border_color = Color(0.72, 0.56, 0.24, 0.85)
		left_box.set_border_width_all(2)
		left_box.set_corner_radius_all(10)
		left_box.content_margin_left = 8.0
		left_box.content_margin_right = 8.0
		left_box.content_margin_top = 8.0
		left_box.content_margin_bottom = 8.0
		left_unit_panel.add_theme_stylebox_override("panel", left_box)
	if right_unit_panel != null:
		var right_box := StyleBoxFlat.new()
		right_box.bg_color = Color(0.08, 0.06, 0.05, 0.78)
		right_box.border_color = Color(0.72, 0.56, 0.24, 0.85)
		right_box.set_border_width_all(2)
		right_box.set_corner_radius_all(10)
		right_box.content_margin_left = 8.0
		right_box.content_margin_right = 8.0
		right_box.content_margin_top = 8.0
		right_box.content_margin_bottom = 8.0
		right_unit_panel.add_theme_stylebox_override("panel", right_box)


func _setup_unit_information_board() -> void:
	if unit_information_board == null:
		unit_information_board = UnitInformationBoard.new()
		unit_information_board.name = "UnitInformationBoard"
		add_child(unit_information_board)
	if left_unit_list != null and right_unit_list != null:
		unit_information_board.attach_to_containers(left_unit_list, right_unit_list)
	var uim := _find_unit_information_manager()
	if uim != null:
		unit_information_board.bind_manager(uim)
		if not uim.unit_updated.is_connected(_on_uim_unit_updated):
			uim.unit_updated.connect(_on_uim_unit_updated)


func _on_uim_unit_updated(u: UnitInformationDO) -> void:
	if u == null or u.unit_kind != "boss":
		return
	var local_role := unit_information_board.local_role if unit_information_board != null else "a"
	var hud_seat := "b" if local_role == "b" else "a"
	if u.owner_seat != hud_seat:
		return
	var ghost_hp := u.get_preview_ghost_hp()
	if ghost_hp < u.current_hp and player_hp_damage != null and player_hp_fill != null:
		var max_v := maxi(u.max_hp, 1)
		var cur_right := _get_hp_bar_width() * float(u.current_hp) / float(max_v)
		var ghost_right := _get_hp_bar_width() * float(ghost_hp) / float(max_v)
		player_hp_fill.offset_right = ghost_right
		player_hp_damage.visible = true
		player_hp_damage.offset_left = ghost_right
		player_hp_damage.offset_right = cur_right
		player_hp_damage.color = Color(0.95, 0.55, 0.16, 0.92)


func _find_unit_information_manager() -> UnitInformationManager:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("UnitInformationManager") as UnitInformationManager
		if sibling != null:
			return sibling
	if is_inside_tree():
		return get_tree().get_first_node_in_group("unit_information_manager") as UnitInformationManager
	return null


func set_local_role(role: String) -> void:
	if unit_information_board != null:
		unit_information_board.set_local_role(role)
	_setup_player_health_bar_for_role(role)


func _setup_player_health_bar_for_role(role: String) -> void:
	var uim := _find_unit_information_manager()
	if uim != null:
		var boss_id := "boss_b" if role == "b" and uim.get_unit("boss_b") != null else "boss_a"
		var boss_do := uim.get_unit(boss_id)
		if boss_do != null:
			_prev_player_hp = boss_do.current_hp
			_set_hp_fill(boss_do.current_hp, boss_do.max_hp)
			_on_player_bars_changed(boss_do.bars_remaining, boss_do.current_hp, boss_do.max_hp)
			return


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
	var uim := _find_unit_information_manager()
	if uim != null and not player.get_unit_id().is_empty():
		var boss_do := uim.get_unit(player.get_unit_id())
		if boss_do != null:
			_prev_player_hp = boss_do.current_hp
			_set_hp_fill(boss_do.current_hp, boss_do.max_hp)
			_on_player_bars_changed(boss_do.bars_remaining, boss_do.current_hp, boss_do.max_hp)

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
