extends PanelContainer

signal card_clicked(card_name: String)

@export var card_title: String = "Card"
@export var card_description: String = "Description"
@export var card_color: Color = Color.WHITE

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var icon_panel: Panel = %IconPanel
@onready var hover_tween: Tween

var original_scale := Vector2.ONE
var is_hovered := false

func _ready() -> void:
	title_label.text = card_title
	desc_label.text = card_description
	_setup_styles()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	original_scale = scale

func _setup_styles() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	bg_style.border_color = card_color
	bg_style.set_border_width_all(3)
	bg_style.set_corner_radius_all(12)
	bg_style.set_content_margin_all(12)
	bg_style.shadow_color = Color(0, 0, 0, 0.5)
	bg_style.shadow_size = 6
	bg_style.shadow_offset = Vector2(2, 4)
	add_theme_stylebox_override("panel", bg_style)

	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = card_color.darkened(0.2)
	icon_style.set_corner_radius_all(8)
	icon_style.set_content_margin_all(8)
	icon_panel.add_theme_stylebox_override("panel", icon_style)

func _on_mouse_entered() -> void:
	is_hovered = true
	_animate_hover(1.08, card_color.lightened(0.3))

func _on_mouse_exited() -> void:
	is_hovered = false
	_animate_hover(1.0, card_color)

func _animate_hover(target_scale: float, border_color: Color) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()

	var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
	var start_color := panel_style.border_color if panel_style else card_color

	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(self, "scale", original_scale * target_scale, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if panel_style:
		var new_style := panel_style.duplicate() as StyleBoxFlat
		new_style.border_color = border_color
		add_theme_stylebox_override("panel", new_style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_animate_click()
			card_clicked.emit(card_title)

func _animate_click() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", original_scale * 0.92, 0.05)
	tween.tween_property(self, "scale", original_scale * (1.08 if is_hovered else 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
