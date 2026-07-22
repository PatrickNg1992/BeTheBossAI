extends CanvasLayer

const CARD_SCENE := preload("res://src/cards/card.tscn")
const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const BAR_Y_OFFSET := 2.8

@onready var hand_container: HBoxContainer = %HandContainer
@onready var player_health_bar: ProgressBar = %PlayerHealthBar
@onready var player_health_label: Label = %PlayerHealthLabel
@onready var enemy_bars_container: Control = %EnemyHealthBars
@onready var card_manager: CardManager = %CardManager
@onready var deck_count_label: Label = %DeckCountLabel
@onready var discard_count_label: Label = %DiscardCountLabel

var _enemy_bars: Dictionary = {}
var _card_nodes: Array = []
var _selected_index: int = -1
var _is_locked: bool = false
var _selected_card_cast_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	card_manager.hand_updated.connect(_on_hand_updated)
	card_manager.deck_count_changed.connect(_on_deck_count_changed)
	card_manager.discard_count_changed.connect(_on_discard_count_changed)
	card_manager.card_played.connect(_on_card_played)
	_setup_player_health_bar()
	# Init UI from current state
	_on_hand_updated(card_manager.get_hand())
	_on_deck_count_changed(card_manager.get_deck_count())
	_on_discard_count_changed(card_manager.get_discard_count())

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

# --- Card System ---

func _on_hand_updated(cards: Array) -> void:
	# Clear hand display
	for node in _card_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_card_nodes.clear()
	_deselect_all()

	# Rebuild from hand array
	for card_data in cards:
		var card := CARD_SCENE.instantiate()
		card.setup(card_data)
		card.card_clicked.connect(_on_card_clicked)
		hand_container.add_child(card)
		_card_nodes.append(card)

func _on_card_clicked(card_node: PanelContainer) -> void:
	if _is_locked:
		return
	var idx: int = _card_nodes.find(card_node)
	if idx == -1:
		return

	if _selected_index == idx:
		# Click same card — deselect
		_deselect_all()
	else:
		# Select this card, deselect previous
		_deselect_all()
		_selected_index = idx
		card_node.set_selected(true)

func _input(event: InputEvent) -> void:
	if _is_locked or _selected_index < 0:
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	# Don't process if click is on the hand area (UI handles it)
	if hand_container.get_global_rect().has_point(event.position):
		return
	# Raycast to find battlefield position
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var from: Vector3 = camera.project_ray_origin(event.position)
	var to: Vector3 = from + camera.project_ray_normal(event.position) * 1000.0
	var space_state := get_viewport().get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return
	# Play card at the hit position
	_selected_card_cast_pos = result["position"]
	var card_node: PanelContainer = _card_nodes[_selected_index] as PanelContainer
	_play_card(card_node, _selected_index, _selected_card_cast_pos)

func _play_card(card_node: PanelContainer, idx: int, _cast_pos: Vector3) -> void:
	_is_locked = true
	card_node.set_selected(true)
	card_node.set_locked(true)
	print("Card cast at: ", _cast_pos)
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(card_node):
		_is_locked = false
		return
	card_node.set_locked(false)
	_deselect_all()
	card_manager.play_card(idx)
	_is_locked = false

func _on_card_played(_card_data: Dictionary) -> void:
	# Card effects ignored for now
	_deselect_all()

func _deselect_all() -> void:
	if _selected_index >= 0 and _selected_index < _card_nodes.size():
		var node := _card_nodes[_selected_index] as PanelContainer
		if is_instance_valid(node):
			node.set_selected(false)
	_selected_index = -1

func _on_deck_count_changed(count: int) -> void:
	deck_count_label.text = "Deck: %d" % count

func _on_discard_count_changed(count: int) -> void:
	discard_count_label.text = "Discard: %d" % count

# --- Player Health ---

func _on_player_health_changed(current: int, maximum: int) -> void:
	if player_health_bar:
		player_health_bar.max_value = maximum
		player_health_bar.value = current
	if player_health_label:
		player_health_label.text = "HP: %d/%d" % [current, maximum]

func _on_player_died() -> void:
	if player_health_label:
		player_health_label.text = "DEFEATED"
