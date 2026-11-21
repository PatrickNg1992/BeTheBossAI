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
var _hp_change_label: Label = null
var _hp_row: HBoxContainer = null
var _damage_badge: PanelContainer = null
var _damage_badge_label: Label = null
var _hp_bar_frame: PanelContainer = null
var _hp_bar_bg: ColorRect = null
var _hp_ghost_fill: ColorRect = null
var _hp_fill: ColorRect = null
var _bars_label: Label = null
var _hp_bar_visible: bool = false
var _last_badge_shake_amplitude: float = 0.0
var _last_display_shake_amplitude: float = 0.0
var _frenzy_spread_played_count: int = 0
var _last_settled_hp_change_text: String = ""
var _badge_shake_tween: Tween = null
var _display_shake_tween: Tween = null
var _spread_tween: Tween = null
var _hp_change_tween: Tween = null


func _init(p_grid_id: String = "", p_span_cols: int = 1) -> void:
	grid_id = p_grid_id
	span_cols = p_span_cols
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(132 if span_cols == 2 else 62, 46)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	set_empty()


func _build_ui() -> void:
	_outer_vbox = VBoxContainer.new()
	_outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outer_vbox.add_theme_constant_override("separation", 2)
	_outer_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_outer_vbox)

	var top_hbox := HBoxContainer.new()
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_hbox.add_theme_constant_override("separation", 4)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outer_vbox.add_child(top_hbox)

	var portrait_stack := Control.new()
	portrait_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(portrait_stack)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_frame.clip_contents = true
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0.11, 0.09, 0.08, 0.90)
	inner_style.set_corner_radius_all(4)
	_portrait_frame.add_theme_stylebox_override("panel", inner_style)
	portrait_stack.add_child(_portrait_frame)

	_portrait_overlay = Control.new()
	_portrait_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait_overlay)

	_avatar_rect = TextureRect.new()
	_avatar_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_overlay.add_child(_avatar_rect)

	_header_label = Label.new()
	_header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 17)
	_header_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.56, 1.0))
	_header_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03, 1.0))
	_header_label.add_theme_constant_override("outline_size", 4)
	_header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_ref_badge.position = Vector2(-4, -4)
	_ref_badge.custom_minimum_size = Vector2(28, 24)
	_ref_badge.z_index = 3
	_ref_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corner_overlay.add_child(_ref_badge)

	_ref_label = Label.new()
	_ref_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ref_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ref_label.add_theme_font_size_override("font_size", 16)
	_ref_label.add_theme_constant_override("outline_size", 2)
	_ref_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ref_badge.add_child(_ref_label)

	# Upper-right Class Mark badge (larger, overlapping the upper-right corner)
	_class_badge = PanelContainer.new()
	_class_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_class_badge.offset_left = -23
	_class_badge.offset_top = -3
	_class_badge.offset_right = 3
	_class_badge.offset_bottom = 23
	_class_badge.z_index = 3
	_class_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_class_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# Floating settled HP change label (e.g. "-567") shown on Settle Time damage resolution
	_hp_change_label = Label.new()
	_hp_change_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hp_change_label.offset_left = -40
	_hp_change_label.offset_top = -22
	_hp_change_label.offset_right = 40
	_hp_change_label.offset_bottom = 0
	_hp_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_change_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_change_label.add_theme_font_size_override("font_size", 14)
	_hp_change_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22, 1.0))
	_hp_change_label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 1.0))
	_hp_change_label.add_theme_constant_override("outline_size", 4)
	_hp_change_label.z_index = 6
	_hp_change_label.visible = false
	_corner_overlay.add_child(_hp_change_label)

	# Bottom HP bar row
	_hp_row = HBoxContainer.new()
	_hp_row.custom_minimum_size = Vector2(0, 14)
	_hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_row.add_theme_constant_override("separation", 3)
	_hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outer_vbox.add_child(_hp_row)

	# Small circle mark on the left of the HP bar showing Damage Stack count (invisible when count == 0)
	_damage_badge = PanelContainer.new()
	_damage_badge.custom_minimum_size = Vector2(15, 15)
	_damage_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_damage_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.84, 0.14, 0.12, 0.96)
	badge_style.border_color = Color(0.98, 0.84, 0.30, 0.98)
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(8)
	badge_style.set_content_margin_all(1)
	_damage_badge.add_theme_stylebox_override("panel", badge_style)
	_damage_badge.visible = false
	_hp_row.add_child(_damage_badge)

	_damage_badge_label = Label.new()
	_damage_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_badge_label.add_theme_font_size_override("font_size", 9)
	_damage_badge_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86, 1.0))
	_damage_badge_label.add_theme_color_override("font_outline_color", Color(0.10, 0.03, 0.02, 1.0))
	_damage_badge_label.add_theme_constant_override("outline_size", 2)
	_damage_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_badge.add_child(_damage_badge_label)

	# Thin black border around the HP bar so it stands out cleanly against ?3 (Yellow) and ?5 (Green) borders
	_hp_bar_frame = PanelContainer.new()
	_hp_bar_frame.custom_minimum_size = Vector2(40, 10)
	_hp_bar_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_bg.resized.connect(_refresh_hp_bars)
	_hp_bar_frame.add_child(_hp_bar_bg)

	_hp_ghost_fill = ColorRect.new()
	_hp_ghost_fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_hp_ghost_fill.color = Color(0.95, 0.55, 0.16, 0.92)
	_hp_ghost_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_bg.add_child(_hp_ghost_fill)

	_hp_fill = ColorRect.new()
	_hp_fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_hp_fill.color = Color(0.11, 0.56, 0.18, 0.98)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_bg.add_child(_hp_fill)

	_bars_label = Label.new()
	_bars_label.add_theme_font_size_override("font_size", 10)
	_bars_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.48, 1.0))
	_bars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_hp_change_label.visible = false
	_hp_row.visible = false
	_damage_badge.visible = false
	_bars_label.visible = false
	_last_badge_shake_amplitude = 0.0
	_last_display_shake_amplitude = 0.0
	_frenzy_spread_played_count = 0
	_last_settled_hp_change_text = ""

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
	_damage_badge.visible = false
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

	# Boss Monster Frenzy Power (right side of 2-cell Boss Unit Display, plain number to 1 d.p., ~30% larger, no box)
	if u.unit_kind == "boss":
		custom_minimum_size = Vector2(132, 68)
		size_flags_stretch_ratio = 1.35
		_frenzy_value_label.visible = true
		var pct_str := "%.1f" % (u.frenzy_power * 100.0)
		_frenzy_value_label.text = Loc.t("uib_frenzy_format", {"pct": pct_str})
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

	var stack_count := u.get_damage_stack_count()
	_damage_badge.visible = (not u.is_dead) and stack_count > 0
	_damage_badge_label.text = str(stack_count) if stack_count > 0 else ""
	_hp_bar_frame.visible = _hp_bar_visible
	_hp_row.visible = _hp_bar_visible or _damage_badge.visible
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
	var ghost_v := clampi(unit_do.get_preview_ghost_hp(), 0, cur_v)
	var cur_ratio := float(cur_v) / float(max_v)
	var ghost_ratio := float(ghost_v) / float(max_v)
	var bar_w := _hp_bar_bg.size.x if _hp_bar_bg.size.x > 4.0 else 72.0
	# _hp_ghost_fill spans 0..cur_ratio (revealing the orange/gold trailing segment between ghost_ratio and cur_ratio)
	# while _hp_fill spans 0..ghost_ratio (the remaining HP after staged Damage Stack * 1.1^HitLevel)
	_hp_ghost_fill.offset_right = bar_w * cur_ratio
	_hp_fill.offset_right = bar_w * ghost_ratio
	if ghost_ratio > 0.6:
		_hp_fill.color = Color(0.11, 0.56, 0.18, 0.98)
	elif ghost_ratio > 0.3:
		_hp_fill.color = Color(0.88, 0.72, 0.14, 0.98)
	else:
		_hp_fill.color = Color(0.86, 0.18, 0.14, 0.98)


## Shakes the Damage Stack circle mark on the left of the HP bar whenever the
## unit takes damage; a harder hit creates a larger shake.
func trigger_damage_badge_shake(damage_value: float) -> void:
	if damage_value <= 0.0 or _damage_badge == null:
		return
	var amp := clampf(1.5 + float(damage_value) * 0.03, 1.5, 10.0)
	_last_badge_shake_amplitude = amp
	if not is_inside_tree():
		return
	if _badge_shake_tween != null and _badge_shake_tween.is_running():
		_badge_shake_tween.kill()
	_damage_badge.pivot_offset = _damage_badge.size * 0.5
	_badge_shake_tween = create_tween()
	var scale_bump := 1.0 + clampf(amp * 0.06, 0.12, 0.55)
	_badge_shake_tween.tween_property(_damage_badge, "scale", Vector2(scale_bump, scale_bump), 0.04)
	_badge_shake_tween.tween_property(_damage_badge, "rotation_degrees", amp * 2.2, 0.04)
	_badge_shake_tween.tween_property(_damage_badge, "rotation_degrees", -amp * 1.8, 0.04)
	_badge_shake_tween.tween_property(_damage_badge, "rotation_degrees", 0.0, 0.04)
	_badge_shake_tween.tween_property(_damage_badge, "scale", Vector2.ONE, 0.05)


## Shakes the Unit Display cell during "Puck-puck Time!" proportional to the
## collision Impulse received.
func trigger_collision_impulse_shake(impulse_magnitude: float) -> void:
	if impulse_magnitude <= 0.0 or _portrait_frame == null:
		return
	var amp := clampf(impulse_magnitude * 0.45, 1.0, 12.0)
	_last_display_shake_amplitude = amp
	if not is_inside_tree():
		return
	if _display_shake_tween != null and _display_shake_tween.is_running():
		_display_shake_tween.kill()
	var base_pos := Vector2.ZERO
	_display_shake_tween = create_tween()
	_display_shake_tween.tween_property(_portrait_frame, "position", base_pos + Vector2(amp, -amp * 0.5), 0.035)
	_display_shake_tween.tween_property(_portrait_frame, "position", base_pos + Vector2(-amp * 0.8, amp * 0.4), 0.035)
	_display_shake_tween.tween_property(_portrait_frame, "position", base_pos + Vector2(amp * 0.4, 0.0), 0.035)
	_display_shake_tween.tween_property(_portrait_frame, "position", base_pos, 0.035)


## Plays the visual effect that spreads Frenzy Power onto the opponent's HP bar
## when Damage Settlement starts in Settle Time.
func play_frenzy_spread_effect() -> void:
	_frenzy_spread_played_count += 1
	if not is_inside_tree() or _hp_ghost_fill == null:
		return
	if _spread_tween != null and _spread_tween.is_running():
		_spread_tween.kill()
	_hp_ghost_fill.color = Color(1.0, 0.88, 0.26, 1.0)
	_spread_tween = create_tween()
	_spread_tween.tween_property(_hp_ghost_fill, "color", Color(0.95, 0.55, 0.16, 0.92), 0.35)


## Displays the settled HP change as a negative integer popup (e.g. "-567") on the Unit Display.
func show_settled_hp_change(settled_damage: int) -> void:
	if settled_damage <= 0 or _hp_change_label == null:
		return
	_last_settled_hp_change_text = "-%d" % settled_damage
	_hp_change_label.text = _last_settled_hp_change_text
	_hp_change_label.visible = true
	_hp_change_label.modulate.a = 1.0
	_hp_change_label.offset_top = -22
	_hp_change_label.offset_bottom = 0
	if not is_inside_tree():
		return
	if _hp_change_tween != null and _hp_change_tween.is_running():
		_hp_change_tween.kill()
	_hp_change_tween = create_tween()
	_hp_change_tween.tween_property(_hp_change_label, "offset_top", -36.0, 0.65)
	_hp_change_tween.parallel().tween_property(_hp_change_label, "offset_bottom", -14.0, 0.65)
	_hp_change_tween.tween_interval(0.25)
	_hp_change_tween.tween_property(_hp_change_label, "modulate:a", 0.0, 0.30)
	_hp_change_tween.tween_callback(func() -> void:
		if is_instance_valid(_hp_change_label):
			_hp_change_label.visible = false
	)


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
			"damage_badge_visible": false,
			"damage_stack_count": 0,
		}
	if not is_occupied or unit_do == null:
		return {
			"grid_id": grid_id,
			"occupied": false,
			"is_team_header": false,
			"hp_bar_visible": false,
			"damage_badge_visible": false,
			"damage_stack_count": 0,
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
		"ghost_hp": unit_do.get_preview_ghost_hp(),
		"damage_stack_count": unit_do.get_damage_stack_count(),
		"damage_badge_visible": _damage_badge.visible,
		"damage_badge_text": _damage_badge_label.text if _damage_badge.visible else "",
		"last_badge_shake_amplitude": _last_badge_shake_amplitude,
		"last_display_shake_amplitude": _last_display_shake_amplitude,
		"frenzy_spread_played_count": _frenzy_spread_played_count,
		"last_settled_hp_change_text": _last_settled_hp_change_text,
	}
