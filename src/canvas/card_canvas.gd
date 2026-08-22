extends CanvasLayer

const CARD_SCENE := preload("res://src/cards/card.tscn")
const BAR_WIDTH := 80.0
const BAR_HEIGHT := 10.0
const BAR_Y_OFFSET := 2.8
const DEBUG_SHOW_DECK := true


@onready var canvas: CanvasLayer = %Canvas
@onready var hand_container: HBoxContainer = %HandContainer
@onready var card_manager: CardManager = %CardManager
# CardPileContainer
@onready var deck_button: Button = %CardPileContainer/DeckButton as Button
@onready var discard_button: Button = %CardPileContainer/DiscardButton as Button
@onready var casting_area: Panel = %CardPileContainer/CastingArea as Panel
@onready var casting_card_container: PanelContainer = %CardPileContainer/CastingArea/DisplayContainer as PanelContainer
@onready var casting_cd: Label = %CardPileContainer/CastingArea/CastingCD as Label
# windows
@onready var discard_window: Panel = $"DiscardWindow" as Panel
@onready var discard_list: VBoxContainer = $"DiscardWindow/DiscardScroll/DiscardList" as VBoxContainer
@onready var deck_window: Panel = $"DeckWindow" as Panel
@onready var deck_list: VBoxContainer = $"DeckWindow/DeckScroll/DeckList" as VBoxContainer

var _card_nodes: Array = []
var _selected_index: int = -1
var _selected_card_cast_pos: Vector3 = Vector3.ZERO
var _casting_card: BaseCardInfo = null
var _casting_cd_time: float = 0.0
var _casting_node: PanelContainer = null

func _ready() -> void:
	card_manager.hand_updated.connect(_on_hand_updated)
	card_manager.casting_card_updated.connect(_on_casting_card_updated)
	card_manager.deck_count_changed.connect(_on_deck_count_changed)
	card_manager.discard_count_changed.connect(_on_discard_count_changed)
	card_manager.card_played.connect(_on_card_played)
	# Init UI from current state
	_on_hand_updated(card_manager.get_hand())
	_on_deck_count_changed(card_manager.get_deck_count())
	_on_discard_count_changed(card_manager.get_discard_count())
	# Button signals
	discard_button.pressed.connect(_on_discard_button_pressed)
	$"DiscardWindow/DiscardCloseButton".pressed.connect(_on_discard_close_pressed)
	if DEBUG_SHOW_DECK:
		deck_button.pressed.connect(_on_deck_button_pressed)
		$"DeckWindow/DeckCloseButton".pressed.connect(_on_deck_close_pressed)
	# Localization
	$"DiscardWindow/DiscardTitle".text = Loc.t("discard_pile")
	$"DiscardWindow/DiscardCloseButton".text = Loc.t("close")
	$"DeckWindow/DeckTitle".text = Loc.t("deck_debug")
	$"DeckWindow/DeckCloseButton".text = Loc.t("close")

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	_update_casting_area(delta)



# --- Card System ---

func _on_hand_updated(cards: Array[BaseCardInfo]) -> void:
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


func _on_casting_card_updated(card: BaseCardInfo) -> void:
	_casting_card = card
	_update_casting_container(card)
	if (_casting_card != null):
		_casting_cd_time = _casting_card.cd
		casting_cd.text = "%.1fs" % _casting_cd_time
		casting_cd.visible = true
	else:
		casting_cd.visible = false

func _update_casting_container(card: BaseCardInfo) -> void:
	if _casting_node:
		_casting_node.queue_free()
		_casting_node = null
	if card:
		var card_node := CARD_SCENE.instantiate() as PanelContainer
		card_node.setup(card)
		casting_card_container.add_child(card_node)
		_casting_node = card_node


func _on_card_clicked(card_node: PanelContainer) -> void:
	var idx: int = _card_nodes.find(card_node)
	if idx == -1:
		return

	if _selected_index == idx:
		# Click same card ??deselect
		_deselect_all()
	else:
		# Select this card, deselect previous
		_deselect_all()
		_selected_index = idx
		card_node.set_selected(true)

func _input(event: InputEvent) -> void:
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
	_play_chosen_card(_selected_index, _selected_card_cast_pos)

# user click to use the card
func _play_chosen_card(idx: int, _cast_pos: Vector3) -> void:
	if (card_manager.get_casting_card() != null):
		canvas.show_warning("Cannot cast a card while another is casting.")
		return

	card_manager.play_card(idx)
	print("Card cast at: ", _cast_pos)

func _on_card_played(_card_data: BaseCardInfo) -> void:
	# Card effects ignored for now
	_deselect_all()

# count down the CD and discard the casting card if time is up
func _update_casting_area(delta: float) -> void:
	if _casting_cd_time <= 0.0:
		return
	_casting_cd_time -= delta
	casting_cd.text = "%.1fs" % maxf(_casting_cd_time, 0.0)
	if _casting_cd_time <= 0.0:
		card_manager.discard_casting_card()

func _deselect_all() -> void:
	if _selected_index >= 0 and _selected_index < _card_nodes.size():
		var node := _card_nodes[_selected_index] as PanelContainer
		if is_instance_valid(node):
			node.set_selected(false)
	_selected_index = -1

func _on_deck_count_changed(count: int) -> void:
	if deck_button:
		deck_button.text = Loc.t("deck_btn", {"count": count})
	if deck_window.visible:
		_populate_card_list(deck_list, card_manager.get_deck())

func _on_discard_count_changed(count: int) -> void:
	if discard_button:
		discard_button.text = Loc.t("discard_btn", {"count": count})
	if discard_window.visible:
		_populate_card_list(discard_list, card_manager.get_discard())

func _on_discard_button_pressed() -> void:
	discard_window.visible = not discard_window.visible
	if discard_window.visible:
		_populate_card_list(discard_list, card_manager.get_discard())

func _on_discard_close_pressed() -> void:
	discard_window.visible = false

func _on_deck_button_pressed() -> void:
	deck_window.visible = not deck_window.visible
	if deck_window.visible:
		_populate_card_list(deck_list, card_manager.get_deck())

func _on_deck_close_pressed() -> void:
	deck_window.visible = false

func _populate_card_list(list_container: VBoxContainer, cards: Array[BaseCardInfo]) -> void:
	for child in list_container.get_children():
		child.queue_free()
	var copy := cards.duplicate()
	copy.reverse()
	for card in copy:
		var label := Label.new()
		label.text = "[%s] %s" % [Loc.t_card_type(card.card_type), card.card_name]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", card.color)
		label.custom_minimum_size = Vector2(260, 22)
		list_container.add_child(label)
