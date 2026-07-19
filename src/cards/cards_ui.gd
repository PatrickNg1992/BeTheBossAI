extends CanvasLayer

const CARD_SCENE := preload("res://src/cards/card.tscn")

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

func _ready() -> void:
	_spawn_cards()
	_setup_player_health_bar()

func _spawn_cards() -> void:
	for data in card_data:
		var card := CARD_SCENE.instantiate()
		card.card_title = data["title"]
		card.card_description = data["description"]
		card.card_color = data["color"]
		card.card_clicked.connect(_on_card_clicked)
		hand_container.add_child(card)

func _setup_player_health_bar() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBase
	if not player:
		return
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.current_hp, player.max_hp)

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
