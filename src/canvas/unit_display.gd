class_name UnitDisplay
extends PanelContainer

## One cell on the Unit Information Board (or a 2-column horizontal span for a
## Boss Monster or Adventurer Team header).
## Styled with a medieval sword-and-magic iron/gold/parchment aesthetic:
## - Upper-left badge: Reference Mark (Ω, Ψ, A1..A6, B1..B6, ω1..6, ψ1..6)
## - Upper-right badge: Class Mark icon (for Enemy Adventurers)
## - Center: Cartoon unit portrait texture
## - Right side (for Boss Monsters): Frenzy Power badge (e.g. 100%)
## - Bottom: HP bar + Ghost HP trail (and xN bar count for non-local Boss Monsters)

const TEX_BOSS_DRAGON := preload("res://src/resource/battlefield/avatar_boss_dragon.png")
const TEX_KNIGHT := preload("res://src/resource/battlefield/avatar_knight.png")
const TEX_WARRIOR := preload("res://src/resource/battlefield/avatar_warrior.png")
const TEX_RANGER := preload("res://src/resource/battlefield/avatar_ranger.png")
const TEX_MAGE := preload("res://src/resource/battlefield/avatar_mage.png")
const TEX_MINION := preload("res://src/resource/battlefield/avatar_minion.png")

const TEX_CLASS_KNIGHT := preload("res://src/resource/battlefield/class_knight.png")
const TEX_CLASS_WARRIOR := preload("res://src/resource/battlefield/class_warrior.png")
const TEX_CLASS_RANGER := preload("res://src/resource/battlefield/class_ranger.png")
const TEX_CLASS_MAGE := preload("res://src/resource/battlefield/class_mage.png")

var grid_id: String = ""
var span_cols: int = 1
var is_team_header: bool = false
var is_occupied: bool = false
var unit_do: UnitInformationDO = null

var _outer_vbox: VBoxContainer = null
var _portrait_frame: PanelContainer = null
var _portrait_overlay: Control = null
var _corner_overlay: Control = null
var _avatar_rect: TextureRect = null
var _header_label: Label = null
var _ref_badge: PanelContainer = null
var _ref_label: Label = null
var _class_badge: PanelContainer = null
var _class_rect: TextureRect = null
var _frenzy_value_label: Label = null
var _hp_row: HBoxContainer = null
var _hp_bar_frame: PanelContainer = null
var _hp_bar_bg: ColorRect = null
var _hp_ghost_fill: ColorRect = null
var _hp_fill: ColorRect = null
var _bars_label: Label = null
var _hp_bar_visible: bool = false


func _init(p_grid_id: String = "", p_span_cols: int = 1) -> void:
	grid_id = p_grid_id
	span_cols = p_span_cols
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(132 if span_cols == 2 else 62, 46)
	_build_ui()
	set_empty()


func _build_ui() -> void:
	_outer_vbox = VBoxContainer.new()
	_outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outer_vbox.add_theme_constant_override("separation", 2)
	add_child(_outer_vbox)

	var top_hbox := HBoxContainer.new()
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_hbox.add_theme_constant_override("separation", 4)
	_outer_vbox.add_child(top_hbox)

	var portrait_stack := Control.new()
	portrait_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(portrait_stack)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_frame.clip_contents = true
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0.11, 0.09, 0.08, 0.90)
	inner_style.set_corner_radius_all(4)
	_portrait_frame.add_theme_stylebox_override("panel", inner_style)
	portrait_stack.add_child(_portrait_frame)

	_portrait_overlay = Control.new()
	_portrait_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_frame.add_child(_portrait_overlay)

	_avatar_rect = TextureRect.new()
	_avatar_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_overlay.add_child(_avatar_rect)

	_header_label = Label.new()
	_header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 17)
	_header_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.56, 1.0))
	_header_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03, 1.0))
	_header_label.add_theme_constant_override("outline_size", 4)
	_header_label.visible = false
	_portrait_overlay.add_child(_header_label)

	# Unclipped overlay above _portrait_frame so Reference Mark and Class Mark
	# can be larger and slightly overlap the upper-left and upper-right corners!
	_corner_overlay = Control.new()
	_corner_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_corner_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stack.add_child(_corner_overlay)

	# Upper-left Reference Mark badge (larger, overlapping the upper-left corner)
	_ref_badge = PanelContainer.new()
	_ref_badge.position = Vector2(-3, -3)
	_ref_badge.custom_minimum_size = Vector2(26, 22)
	_ref_badge.z_index = 3
	_corner_overlay.add_child(_ref_badge)

	_ref_label = Label.new()
	_ref_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ref_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ref_label.add_theme_font_size_override("font_size", 13)
	_ref_label.add_theme_constant_override("outline_size", 2)
	_ref_badge.add_child(_ref_label)

	# Upper-right Class Mark badge (larger, overlapping the upper-right corner)
	_class_badge = PanelContainer.new()
	_class_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_class_badge.offset_left = -23
	_class_badge.offset_top = -3
	_class_badge.offset_right = 3
	_class_badge.offset_bottom = 23
	_class_badge.z_index = 3
	var cls_box := StyleBoxFlat.new()
	cls_box.bg_color = Color(0.10, 0.08, 0.06, 0.92)
	cls_box.border_color = Color(0.90, 0.74, 0.30, 0.96)
	cls_box.set_border_width_all(1)
	cls_box.set_corner_radius_all(5)
	cls_box.set_content_margin_all(2)
	_class_badge.add_theme_stylebox_override("panel", cls_box)
	_corner_overlay.add_child(_class_badge)

	_class_rect = TextureRect.new()
	_class_rect.custom_minimum_size = Vector2(20, 20)
	_class_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_class_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_class_badge.add_child(_class_rect)

	# Right side of 2-cell Boss Unit Display: Frenzy Power number directly overlaid (no box, no "Frenzy" label, ~30% larger)
	_frenzy_value_label = Label.new()
	_frenzy_value_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_frenzy_value_label.offset_left = -64
	_frenzy_value_label.offset_top = -14
	_frenzy_value_label.offset_right = -6
	_frenzy_value_label.offset_bottom = 14
	_frenzy_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_frenzy_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frenzy_value_label.add_theme_font_size_override("font_size", 18)
	_frenzy_value_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.28, 1.0))
	_frenzy_value_label.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.02, 1.0))
	_frenzy_value_label.add_theme_constant_override("outline_size", 4)
	_frenzy_value_label.visible = false
	_corner_overlay.add_child(_frenzy_value_label)

	# Bottom HP bar row
	_hp_row = HBoxContainer.new()
	_hp_row.custom_minimum_size = Vector2(0, 11)
	_hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_row.add_theme_constant_override("separation", 4)
	_outer_vbox.add_child(_hp_row)

	# Thin black border around the HP bar so it stands out cleanly against ?3 (Yellow) and ?5 (Green) borders
	_hp_bar_frame = PanelContainer.new()
	_hp_bar_frame.custom_minimum_size = Vector2(40, 10)
	_hp_bar_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hp_border_style := StyleBoxFlat.new()
	hp_border_style.bg_color = Color(0.05, 0.05, 0.05, 0.98)
	hp_border_style.border_color = Color(0.02, 0.02, 0.02, 1.0)
	hp_border_style.set_border_width_all(1)
	hp_border_style.set_corner_radius_all(2)
	hp_border_style.set_content_margin_all(1)
	_hp_bar_frame.add_theme_stylebox_override("panel", hp_border_style)
	_hp_row.add_child(_hp_bar_frame)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.custom_minimum_size = Vector2(36, 7)
	_hp_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hp_bar_bg.color = Color(0.07, 0.06, 0.06, 0.96)
	_hp_bar_bg.resized.connect(_refresh_hp_bars)
	_hp_bar_frame.add_child(_hp_bar_bg)

	_hp_ghost_fill = ColorRect.new()
	_hp_ghost_fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_hp_ghost_fill.color = Color(0.95, 0.55, 0.16, 0.92)
	_hp_bar_bg.add_child(_hp_ghost_fill)

	_hp_fill = ColorRect.new()
	_hp_fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_hp_fill.color = Color(0.11, 0.56, 0.18, 0.98)
	_hp_bar_bg.add_child(_hp_fill)

	_bars_label = Label.new()
	_bars_label.add_theme_font_size_override("font_size", 10)
	_bars_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.48, 1.0))
	_bars_label.visible = false
	_hp_row.add_child(_bars_label)


func set_empty() -> void:
	is_occupied = false
	is_team_header = false
	unit_do = null
	_hp_bar_visible = false
	_avatar_rect.texture = null
	_avatar_rect.visible = false
	_header_label.visible = false
	_ref_badge.visible = false
	_class_badge.visible = false
	_frenzy_value_label.visible = false
	_hp_row.visible = false
	_bars_label.visible = false

	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color(0.11, 0.09, 0.07, 0.34)
	empty_style.border_color = Color(0.36, 0.28, 0.18, 0.42)
	empty_style.set_border_width_all(1)
	empty_style.set_corner_radius_all(5)
	empty_style.set_content_margin_all(3)
	add_theme_stylebox_override("panel", empty_style)


func set_team_header(loc_key: String, team_index: int) -> void:
	is_occupied = false
	is_team_header = true
	unit_do = null
	_hp_bar_visible = false
	_avatar_rect.visible = false
	_ref_badge.visible = false
	_class_badge.visible = false
	_frenzy_value_label.visible = false
	_hp_row.visible = false
	_bars_label.visible = false
	_header_label.visible = true
	_header_label.text = "⚔ %s ⚔" % Loc.t(loc_key)

	var hdr_style := StyleBoxFlat.new()
	hdr_style.bg_color = Color(0.22, 0.14, 0.09, 0.92) if team_index == 1 else Color(0.26, 0.14, 0.08, 0.92)
	hdr_style.border_color = Color(0.84, 0.66, 0.28, 0.95)
	hdr_style.set_border_width_all(2)
	hdr_style.set_corner_radius_all(6)
	hdr_style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", hdr_style)


func render_unit(u: UnitInformationDO, local_role: String) -> void:
	if u == null:
		set_empty()
		return
	unit_do = u
	is_occupied = true
	is_team_header = false
	_header_label.visible = false

	# Cell border follows unit slot colour (or Black with Gold inner sheen for Boss Monster)
	var cell_style := StyleBoxFlat.new()
	cell_style.bg_color = Color(0.13, 0.10, 0.08, 0.92)
	cell_style.border_color = u.slot_color
	cell_style.set_border_width_all(3)
	cell_style.set_corner_radius_all(6)
	cell_style.set_content_margin_all(3)
	cell_style.shadow_color = Color(0, 0, 0, 0.45)
	cell_style.shadow_size = 2
	add_theme_stylebox_override("panel", cell_style)

	# Portrait avatar texture
	_avatar_rect.visible = true
	_avatar_rect.texture = _resolve_avatar_texture(u)
	_avatar_rect.modulate = Color(0.45, 0.45, 0.45, 1.0) if (u.is_dead or u.is_pocketed) else Color.WHITE

	# Upper-left Reference Mark badge
	_ref_badge.visible = not u.reference_mark.is_empty()
	_ref_label.text = u.reference_mark
	var ref_box := StyleBoxFlat.new()
	var mark_lum := u.reference_mark_color.get_luminance()
	# For dark team mark colours (Deep Grey / Deep Brown), use a parchment/badge plate so the mark colour stands out clearly
	if mark_lum < 0.40:
		ref_box.bg_color = Color(0.90, 0.84, 0.70, 0.94)
		ref_box.border_color = u.reference_mark_color
		_ref_label.add_theme_color_override("font_color", u.reference_mark_color)
		_ref_label.add_theme_color_override("font_outline_color", Color(0.98, 0.95, 0.88, 0.85))
	else:
		ref_box.bg_color = Color(0.10, 0.08, 0.07, 0.90)
		ref_box.border_color = u.reference_mark_color
		_ref_label.add_theme_color_override("font_color", u.reference_mark_color)
		_ref_label.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.03, 0.95))
	ref_box.set_border_width_all(1)
	ref_box.set_corner_radius_all(4)
	ref_box.content_margin_left = 4
	ref_box.content_margin_right = 4
	ref_box.content_margin_top = 1
	ref_box.content_margin_bottom = 1
	_ref_badge.add_theme_stylebox_override("panel", ref_box)

	# Upper-right Class Mark icon (for Enemy Adventurers only)
	if u.unit_kind == "enemy_adventurer":
		_class_badge.visible = true
		_class_rect.texture = _resolve_class_texture(u.adventurer_class)
	else:
		_class_badge.visible = false

	# Boss Monster Frenzy Power (right side of 2-cell Boss Unit Display, plain number ~30% larger, no box)
	if u.unit_kind == "boss":
		custom_minimum_size = Vector2(132, 68)
		size_flags_stretch_ratio = 1.35
		_frenzy_value_label.visible = true
		var pct := int(round(u.frenzy_power * 100.0))
		_frenzy_value_label.text = Loc.t("uib_frenzy_format", {"pct": pct})
		_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		custom_minimum_size = Vector2(62, 46)
		size_flags_stretch_ratio = 1.0
		_frenzy_value_label.visible = false
		_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Role-based Boss Monster HP bar visibility:
	# - The Boss Monster shown in the upper-left HUD is Player A's Boss for Player A ("a") & Spectator ("spectator"),
	#   or Player B's Boss for Player B ("b"). That Boss omits its internal HP bar.
	# - Every other Boss Monster (and every non-defeated Minion/Adventurer/Target Puck) displays its HP bar!
	if u.is_dead:
		_hp_bar_visible = false
	elif u.unit_kind == "boss":
		var upper_left_hud_seat := "b" if local_role == "b" else "a"
		_hp_bar_visible = (u.owner_seat != upper_left_hud_seat)
	else:
		_hp_bar_visible = true

	_hp_row.visible = _hp_bar_visible
	if _hp_bar_visible and u.unit_kind == "boss":
		_bars_label.visible = true
		_bars_label.text = Loc.t("bar_count", {"count": u.bars_remaining})
	else:
		_bars_label.visible = false

	_refresh_hp_bars()


func _refresh_hp_bars() -> void:
	if unit_do == null or not _hp_bar_visible or _hp_bar_bg == null:
		return
	var max_v := maxi(unit_do.max_hp, 1)
	var cur_v := clampi(unit_do.current_hp, 0, max_v)
	var ratio := float(cur_v) / float(max_v)
	var bar_w := _hp_bar_bg.size.x if _hp_bar_bg.size.x > 4.0 else 72.0
	_hp_fill.offset_right = bar_w * ratio
	_hp_ghost_fill.offset_right = bar_w * ratio
	if ratio > 0.6:
		_hp_fill.color = Color(0.11, 0.56, 0.18, 0.98)
	elif ratio > 0.3:
		_hp_fill.color = Color(0.88, 0.72, 0.14, 0.98)
	else:
		_hp_fill.color = Color(0.86, 0.18, 0.14, 0.98)


func _resolve_avatar_texture(u: UnitInformationDO) -> Texture2D:
	if not u.avatar_path.is_empty() and ResourceLoader.exists(u.avatar_path):
		var loaded := load(u.avatar_path) as Texture2D
		if loaded != null:
			return loaded
	if u.unit_kind == "boss":
		return TEX_BOSS_DRAGON
	if u.unit_kind == "minion":
		return TEX_MINION
	match u.adventurer_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return TEX_KNIGHT
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return TEX_WARRIOR
		EnemyAdventurer.AdventurerClass.RANGER:
			return TEX_RANGER
		EnemyAdventurer.AdventurerClass.MAGE:
			return TEX_MAGE
		_:
			return TEX_WARRIOR


func _resolve_class_texture(adv_class: int) -> Texture2D:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return TEX_CLASS_KNIGHT
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return TEX_CLASS_WARRIOR
		EnemyAdventurer.AdventurerClass.RANGER:
			return TEX_CLASS_RANGER
		EnemyAdventurer.AdventurerClass.MAGE:
			return TEX_CLASS_MAGE
		_:
			return TEX_CLASS_WARRIOR


func get_info() -> Dictionary:
	if is_team_header:
		return {
			"grid_id": grid_id,
			"occupied": false,
			"is_team_header": true,
			"header_text": _header_label.text,
			"hp_bar_visible": false,
		}
	if not is_occupied or unit_do == null:
		return {
			"grid_id": grid_id,
			"occupied": false,
			"is_team_header": false,
			"hp_bar_visible": false,
		}
	return {
		"grid_id": grid_id,
		"occupied": true,
		"is_team_header": false,
		"unit_id": unit_do.unit_id,
		"unit_kind": unit_do.unit_kind,
		"reference_mark": unit_do.reference_mark,
		"reference_mark_color": unit_do.reference_mark_color,
		"slot_color": unit_do.slot_color,
		"class_mark_visible": _class_badge.visible,
		"frenzy_visible": _frenzy_value_label.visible,
		"frenzy_text": _frenzy_value_label.text if _frenzy_value_label.visible else "",
		"hp_bar_visible": _hp_bar_visible,
		"bars_text": _bars_label.text if _bars_label.visible else "",
		"current_hp": unit_do.current_hp,
		"max_hp": unit_do.max_hp,
	}
