extends CanvasLayer

const CARD_SCENE := preload("res://src/cards/card.tscn")
const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const BAR_Y_OFFSET := 2.8 # world units above enemy

var card_data := [
	{"title": "Fireball", "description": "Deals 10 fire damage to target enemy.", "color": Color(0.9, 0.2, 0.1)},
	{"title": "Heal", "description": "Restores 5 HP to the player.", "color": Color(0.1, 0.8, 0.2)},
	{"title": "Shield", "description": "Blocks the next incoming attack.", "color": Color(0.2, 0.4, 0.9)},
	{"title": "Lightning", "description": "Hits all enemies with chain lightning.", "color": Color(0.9, 0.8, 0.1)},
	{"title": "Ice Wall", "description": "Freezes target for 2 turns.", "color": Color(0.1, 0.8, 0.9)},
]

@onready var hand_container: HBoxContainer = %HandContainer
@onready var player_health_bar: ProgressBar = %PlayerHealthBar
@onready var player_health_label: Label = %PlayerHealthLabel
@onready var enemy_bars_container: Control = %EnemyHealthBars

var _enemy_bars: Dictionary = {}  # EnemyHero -> {background: ColorRect, fill: ColorRect, label: Label}

func _ready() -> void:
	_spawn_cards()
	_setup_player_health_bar()

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	# Update existing bar positions
	var to_remove: Array = []
	for enemy in _enemy_bars:
		if not is_instance_valid(enemy) or enemy.is_dead:
			to_remove.append(enemy)
		else:
			var bar_data: Dictionary = _enemy_bars[enemy]
			var world_pos: Vector3 = enemy.global_position + Vector3(0, BAR_Y_OFFSET, 0)
			# Only show bars that are in front of the camera
			if camera.is_position_behind(world_pos):
				for node in bar_data.values():
					(node as Control).visible = false
				continue
			var screen_pos := camera.unproject_position(world_pos)
			position_bar_widget(bar_data, screen_pos)

	# Clean up dead enemy bars
	# for e in to_remove:
	# 	_remove_enemy_bar(e)

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

func _setup_player_health_bar() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBase
	if not player:
		return
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.current_hp, player.max_hp)

func _scan_for_new_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyHero and not enemy in _enemy_bars and not (enemy as EnemyHero).is_dead:
			_create_enemy_bar(enemy)
		

func _create_enemy_bar(enemy: EnemyHero) -> void:
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

func _on_enemy_health_changed(current: int, maximum: int, enemy: EnemyHero) -> void:
	if not enemy in _enemy_bars:
		return
	var bar_data: Dictionary = _enemy_bars[enemy]
	var ratio := float(current) / float(maximum)
	var fill := bar_data["fill"] as ColorRect
	fill.size.x = BAR_WIDTH * ratio
	var label := bar_data["label"] as Label
	label.text = "%d/%d" % [current, maximum]
	_bar_set_color(fill, ratio)

func _on_enemy_died(enemy: EnemyHero) -> void:
	_remove_enemy_bar(enemy)

func _remove_enemy_bar(enemy: EnemyHero) -> void:
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

func _spawn_cards() -> void:
	for data in card_data:
		var card := CARD_SCENE.instantiate()
		card.card_title = data["title"]
		card.card_description = data["description"]
		card.card_color = data["color"]
		card.card_clicked.connect(_on_card_clicked)
		hand_container.add_child(card)

func _on_player_health_changed(current: int, maximum: int) -> void:
	if player_health_bar:
		player_health_bar.max_value = maximum
		player_health_bar.value = current
	if player_health_label:
		player_health_label.text = "HP: %d/%d" % [current, maximum]

func _on_player_died() -> void:
	if player_health_label:
		player_health_label.text = "DEFEATED"

func _on_card_clicked(card_name: String) -> void:
	print("Card played: ", card_name)
