extends PanelContainer

signal card_clicked(card_node: PanelContainer)
signal card_double_clicked(card_node: PanelContainer)

@export var card_title: String = "Card"
@export var card_description: String = "Description"
@export var card_color: Color = Color.WHITE

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var icon_panel: Panel = %IconPanel

var card_data: Dictionary = {}
var is_selected := false
var is_locked := false
var original_scale := Vector2.ONE

var _hover_tween: Tween
var _select_tween: Tween

func _ready() -> void:
	title_label.text = card_title
	desc_label.text = card_description
	_setup_styles()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	original_scale = scale

func setup(card: Dictionary) -> void:
	card_data = card
	card_title = card["name"]
	card_description = card["description"]
	card_color = card["color"]

func set_locked(locked: bool) -> void:
	is_locked = locked
	if locked:
		mouse_filter = MOUSE_FILTER_IGNORE
		if _hover_tween and _hover_tween.is_valid():
			_hover_tween.kill()
		scale = original_scale
		# "CASTING" badge
		var vbox: Control = icon_panel.get_parent()
		var cast_label := Label.new()
		cast_label.name = "_CastingLabel"
		cast_label.text = "CASTING"
		cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cast_label.add_theme_font_size_override("font_size", 9)
		cast_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		vbox.add_child(cast_label)
		vbox.move_child(cast_label, 0)
		# Gold glowing border
		var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			var new_style := panel_style.duplicate() as StyleBoxFlat
			new_style.border_color = Color(1, 0.8, 0.1)
			new_style.set_border_width_all(5)
			new_style.shadow_color = Color(1, 0.8, 0.1, 0.6)
			new_style.shadow_size = 12
			add_theme_stylebox_override("panel", new_style)
		# Pulsing modulate
		var lock_tween := create_tween().set_loops()
		lock_tween.tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 1), 0.35).set_ease(Tween.EASE_IN_OUT)
		lock_tween.tween_property(self, "modulate", Color(0.9, 0.9, 0.9, 1), 0.35).set_ease(Tween.EASE_IN_OUT)
	else:
		mouse_filter = MOUSE_FILTER_STOP
		modulate = Color.WHITE
		var cast_label := get_node_or_null("VBoxContainer/_CastingLabel")
		if cast_label:
			cast_label.queue_free()
		var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			var new_style := panel_style.duplicate() as StyleBoxFlat
			new_style.border_color = card_color
			new_style.set_border_width_all(3)
			new_style.shadow_color = Color(0, 0, 0, 0.5)
			new_style.shadow_size = 6
			add_theme_stylebox_override("panel", new_style)

func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	is_selected = selected

	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	_select_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if selected:
		_select_tween.tween_property(self, "position:y", -20.0, 0.2).from_current()
		var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			var new_style := panel_style.duplicate() as StyleBoxFlat
			new_style.border_color = Color.WHITE
			new_style.set_border_width_all(4)
			add_theme_stylebox_override("panel", new_style)
	else:
		_select_tween.tween_property(self, "position:y", 0.0, 0.2).from_current()
		var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			var new_style := panel_style.duplicate() as StyleBoxFlat
			new_style.border_color = card_color
			new_style.set_border_width_all(3)
			add_theme_stylebox_override("panel", new_style)

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
	_animate_scale(1.08)

func _on_mouse_exited() -> void:
	_animate_scale(1.0)

func _animate_scale(target_scale: float) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", original_scale * target_scale, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			card_double_clicked.emit(self)
		else:
			card_clicked.emit(self)
