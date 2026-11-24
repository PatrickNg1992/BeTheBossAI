class_name UnitDetailDisplay
extends PanelContainer

## Popup inspection window alongside the Unit Information Board that displays
## full localized details for a clicked Unit Display:
## - Unit name + Reference Mark + Unit Lv
## - Detailed Class name & Class Mark icon (if Enemy Adventurer)
## - HP bar displaying numeric "HP / Max HP" (plus remaining Health Bar count if Boss Monster)
## - Attack power, Speed (SPD), Puck Mass & Radius
## - Current Hit Level and Frenzy Power (if Boss Monster)
## - Special condition (Normal, Focusing, Pocketed + turns, Defeated)
## - Statuses (buffs/debuffs/conditional statuses)
## - Skill Icons at the bottom:
##     * Row 1 (3 spaced SQUARE 68x68 slots): Move Skill | Attack Skill | Active Skill
##       (empty square slot frame if no Active Skill), displaying Skill Lv ("Lv 1") and countdown badge.
##     * Passive Grid below (3 rows x 10 columns = 30 SQUARE 30x30 slots, ~40% of Row-1 size,
##       allowing up to 30 Passive Skills for future Heroes), displaying Skill Lv ("Lv1").
## - Hovering any populated skill icon opens the larger (+20%, 400x210) floating `Skill Display`
##   window showing Name, Type, Skill Lv, styled Description with resolved variables & *keyword*
##   highlights, and keyword meanings at the bottom.
## - Persistent Slot Controls: skill slot nodes are pre-allocated and updated in place so
##   per-Turn Time Board Action Tag updates never destroy hovered nodes or flash/close `Skill Display`.

const MAX_PASSIVE_SLOTS := 30
const PASSIVE_GRID_COLUMNS := 10
const PASSIVE_GRID_ROWS := 3
const ROW1_ICON_SIZE := Vector2(68, 68)
const PASSIVE_ICON_SIZE := Vector2(30, 30)
const SKILL_DISPLAY_MIN_SIZE := Vector2(400, 210)

const TEX_CLASS_KNIGHT := preload("res://src/resource/battlefield/class_knight.png")
const TEX_CLASS_WARRIOR := preload("res://src/resource/battlefield/class_warrior.png")
const TEX_CLASS_RANGER := preload("res://src/resource/battlefield/class_ranger.png")
const TEX_CLASS_MAGE := preload("res://src/resource/battlefield/class_mage.png")
const TEX_SWORD := preload("res://src/resource/battlefield/sword.png")
const TEX_DOUBLE_ARROW := preload("res://src/resource/battlefield/double_arrow.png")
const TEX_GOAL_FLAG := preload("res://src/resource/battlefield/goal_flag.png")

var inspected_unit: UnitInformationDO = null
var inspected_grid_id: String = ""
var unit_manager: UnitInformationManager = null

var _name_label: Label = null
var _ref_label: Label = null
var _lv_label: Label = null
var _class_row: HBoxContainer = null
var _class_icon: TextureRect = null
var _class_label: Label = null
var _hp_bar_frame: PanelContainer = null
var _hp_bar_bg: ColorRect = null
var _hp_fill: ColorRect = null
var _hp_value_label: Label = null
var _bars_value_label: Label = null
var _power_spd_label: Label = null
var _mass_radius_label: Label = null
var _hit_level_label: Label = null
var _frenzy_label: Label = null
var _condition_label: Label = null
var _statuses_label: Label = null
var _skills_header_label: Label = null
var _skill_row1_box: HBoxContainer = null
var _passive_grid_box: GridContainer = null

# Persistent pre-allocated slot controls so per-Turn refreshes never flash or drop hover state
var _row1_slot_controls: Array[Dictionary] = []
var _passive_slot_controls: Array[Dictionary] = []

var _skill_display_panel: PanelContainer = null
var _sd_title_label: Label = null
var _sd_meta_label: Label = null
var _sd_icon_frame: PanelContainer = null
var _sd_icon_style: StyleBoxFlat = null
var _sd_icon_rect: TextureRect = null
var _sd_desc_rtl: RichTextLabel = null
var _sd_kw_sep: HSeparator = null
var _sd_kw_rtl: RichTextLabel = null

var _hovered_skill_row: int = 0
var _hovered_skill_slot: int = -1
var _row1_slot_meta: Array[Dictionary] = []
var _row2_slot_meta: Array[Dictionary] = []
var _skill_display_info: Dictionary = {"visible": false}
var _cached_info: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(396, 470)
	z_index = 30
	visible = false
	_build_ui()


func _build_ui() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.10, 0.08, 0.06, 0.96)
	box.border_color = Color(0.86, 0.70, 0.28, 0.96)
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(14)
	box.shadow_color = Color(0, 0, 0, 0.65)
	box.shadow_size = 8
	add_theme_stylebox_override("panel", box)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	# Title row: Reference Mark + Unit Name + Unit Lv
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	_ref_label = Label.new()
	_ref_label.add_theme_font_size_override("font_size", 22)
	_ref_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.32, 1.0))
	title_row.add_child(_ref_label)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78, 1.0))
	title_row.add_child(_name_label)

	_lv_label = Label.new()
	_lv_label.add_theme_font_size_override("font_size", 18)
	_lv_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.36, 1.0))
	title_row.add_child(_lv_label)

	# Class row (visible for Enemy Adventurers)
	_class_row = HBoxContainer.new()
	_class_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_class_row)

	_class_icon = TextureRect.new()
	_class_icon.custom_minimum_size = Vector2(24, 24)
	_class_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_class_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_class_row.add_child(_class_icon)

	_class_label = Label.new()
	_class_label.add_theme_font_size_override("font_size", 17)
	_class_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.70, 1.0))
	_class_row.add_child(_class_label)

	# HP Bar with numeric HP / Max HP overlay + optional Boss bar count
	var hp_hbox := HBoxContainer.new()
	hp_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_hbox)

	_hp_bar_frame = PanelContainer.new()
	_hp_bar_frame.custom_minimum_size = Vector2(240, 24)
	_hp_bar_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color(0.05, 0.05, 0.05, 0.98)
	hp_style.border_color = Color(0.02, 0.02, 0.02, 1.0)
	hp_style.set_border_width_all(1)
	hp_style.set_corner_radius_all(4)
	hp_style.set_content_margin_all(2)
	_hp_bar_frame.add_theme_stylebox_override("panel", hp_style)
	hp_hbox.add_child(_hp_bar_frame)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hp_bar_bg.color = Color(0.08, 0.07, 0.07, 0.96)
	_hp_bar_bg.resized.connect(_refresh_hp_fill)
	_hp_bar_frame.add_child(_hp_bar_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_hp_fill.color = Color(0.11, 0.58, 0.18, 0.98)
	_hp_bar_bg.add_child(_hp_fill)

	_hp_value_label = Label.new()
	_hp_value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_value_label.add_theme_font_size_override("font_size", 15)
	_hp_value_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	_hp_value_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.98))
	_hp_value_label.add_theme_constant_override("outline_size", 4)
	_hp_bar_bg.add_child(_hp_value_label)

	_bars_value_label = Label.new()
	_bars_value_label.add_theme_font_size_override("font_size", 17)
	_bars_value_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.36, 1.0))
	hp_hbox.add_child(_bars_value_label)

	_power_spd_label = _make_stat_label(vbox)
	_mass_radius_label = _make_stat_label(vbox)
	_hit_level_label = _make_stat_label(vbox)
	_frenzy_label = _make_stat_label(vbox)
	_condition_label = _make_stat_label(vbox)
	_statuses_label = _make_stat_label(vbox)

	# Bottom section: Row 1 (3 square 68x68 slots: Move | Attack | Active) +
	# Passive Grid below (3 rows x 10 columns = 30 square 30x30 slots)
	var sep := HSeparator.new()
	vbox.add_child(sep)

	_skills_header_label = _make_stat_label(vbox)
	_skills_header_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.42, 1.0))

	_skill_row1_box = HBoxContainer.new()
	_skill_row1_box.add_theme_constant_override("separation", 18)
	vbox.add_child(_skill_row1_box)

	for i in range(3):
		_row1_slot_controls.append(_create_persistent_row1_slot(i))

	_passive_grid_box = GridContainer.new()
	_passive_grid_box.columns = PASSIVE_GRID_COLUMNS
	_passive_grid_box.add_theme_constant_override("h_separation", 6)
	_passive_grid_box.add_theme_constant_override("v_separation", 6)
	vbox.add_child(_passive_grid_box)

	for i in range(MAX_PASSIVE_SLOTS):
		_passive_slot_controls.append(_create_persistent_passive_slot(i))

	_build_skill_display_tooltip()


func _create_persistent_row1_slot(slot_idx: int) -> Dictionary:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = ROW1_ICON_SIZE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", style)

	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(canvas)

	var empty_lbl := Label.new()
	empty_lbl.text = "—"
	empty_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38, 0.75))
	empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(empty_lbl)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(28, 28)
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon_rect.offset_left = -14
	icon_rect.offset_right = 14
	icon_rect.offset_top = -16
	icon_rect.offset_bottom = 12
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(icon_rect)

	var lv_lbl := Label.new()
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	lv_lbl.offset_left = 1
	lv_lbl.offset_right = 34
	lv_lbl.offset_top = -1
	lv_lbl.offset_bottom = 14
	lv_lbl.add_theme_font_size_override("font_size", 10)
	lv_lbl.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0, 0.98))
	lv_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.98))
	lv_lbl.add_theme_constant_override("outline_size", 3)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lv_lbl)

	var badge_lbl := Label.new()
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge_lbl.offset_left = -30
	badge_lbl.offset_right = -1
	badge_lbl.offset_top = -1
	badge_lbl.offset_bottom = 14
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32, 1.0))
	badge_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.98))
	badge_lbl.add_theme_constant_override("outline_size", 3)
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(badge_lbl)

	var name_lbl := Label.new()
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -16
	name_lbl.offset_bottom = 0
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78, 1.0))
	name_lbl.clip_text = true
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(name_lbl)

	frame.mouse_entered.connect(func() -> void:
		simulate_skill_hover(1, slot_idx, true)
	)
	frame.mouse_exited.connect(func() -> void:
		if _hovered_skill_row == 1 and _hovered_skill_slot == slot_idx:
			simulate_skill_hover(1, slot_idx, false)
	)
	_skill_row1_box.add_child(frame)
	return {
		"frame": frame,
		"style": style,
		"empty_lbl": empty_lbl,
		"icon_rect": icon_rect,
		"lv_lbl": lv_lbl,
		"badge_lbl": badge_lbl,
		"name_lbl": name_lbl,
	}


func _create_persistent_passive_slot(slot_idx: int) -> Dictionary:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = PASSIVE_ICON_SIZE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", style)

	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(canvas)

	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 2
	icon_rect.offset_right = -2
	icon_rect.offset_top = 2
	icon_rect.offset_bottom = -2
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(icon_rect)

	var lv_lbl := Label.new()
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	lv_lbl.offset_left = -26
	lv_lbl.offset_right = 0
	lv_lbl.offset_top = -12
	lv_lbl.offset_bottom = 1
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv_lbl.add_theme_font_size_override("font_size", 9)
	lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.46, 1.0))
	lv_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 0.98))
	lv_lbl.add_theme_constant_override("outline_size", 3)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lv_lbl)

	frame.mouse_entered.connect(func() -> void:
		simulate_skill_hover(2, slot_idx, true)
	)
	frame.mouse_exited.connect(func() -> void:
		if _hovered_skill_row == 2 and _hovered_skill_slot == slot_idx:
			simulate_skill_hover(2, slot_idx, false)
	)
	_passive_grid_box.add_child(frame)
	return {
		"frame": frame,
		"style": style,
		"icon_rect": icon_rect,
		"lv_lbl": lv_lbl,
	}


func _build_skill_display_tooltip() -> void:
	_skill_display_panel = PanelContainer.new()
	_skill_display_panel.name = "SkillDisplayTooltip"
	_skill_display_panel.top_level = true
	_skill_display_panel.z_index = 60
	_skill_display_panel.custom_minimum_size = SKILL_DISPLAY_MIN_SIZE
	_skill_display_panel.visible = false
	_skill_display_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sd_box := StyleBoxFlat.new()
	sd_box.bg_color = Color(0.07, 0.06, 0.05, 0.98)
	sd_box.border_color = Color(0.94, 0.78, 0.32, 0.98)
	sd_box.set_border_width_all(2)
	sd_box.set_corner_radius_all(8)
	sd_box.set_content_margin_all(15)
	sd_box.shadow_color = Color(0, 0, 0, 0.75)
	sd_box.shadow_size = 8
	_skill_display_panel.add_theme_stylebox_override("panel", sd_box)
	add_child(_skill_display_panel)

	var sd_vbox := VBoxContainer.new()
	sd_vbox.add_theme_constant_override("separation", 8)
	sd_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_display_panel.add_child(sd_vbox)

	# Header row: Title + Type/Lv on the left, and the 68x68 square Skill Icon in the upper-right corner
	var sd_header_hbox := HBoxContainer.new()
	sd_header_hbox.add_theme_constant_override("separation", 12)
	sd_header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_vbox.add_child(sd_header_hbox)

	var sd_title_vbox := VBoxContainer.new()
	sd_title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sd_title_vbox.add_theme_constant_override("separation", 4)
	sd_title_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_header_hbox.add_child(sd_title_vbox)

	_sd_title_label = Label.new()
	_sd_title_label.add_theme_font_size_override("font_size", 22)
	_sd_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62, 1.0))
	_sd_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sd_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_title_vbox.add_child(_sd_title_label)

	_sd_meta_label = Label.new()
	_sd_meta_label.add_theme_font_size_override("font_size", 16)
	_sd_meta_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.92, 1.0))
	_sd_meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_title_vbox.add_child(_sd_meta_label)

	_sd_icon_frame = PanelContainer.new()
	_sd_icon_frame.custom_minimum_size = ROW1_ICON_SIZE
	_sd_icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_END
	_sd_icon_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sd_icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sd_icon_style = StyleBoxFlat.new()
	_sd_icon_style.bg_color = Color(0.15, 0.12, 0.09, 0.96)
	_sd_icon_style.border_color = Color(0.68, 0.46, 0.92, 0.95)
	_sd_icon_style.set_border_width_all(2)
	_sd_icon_style.set_corner_radius_all(6)
	_sd_icon_style.set_content_margin_all(8)
	_sd_icon_frame.add_theme_stylebox_override("panel", _sd_icon_style)
	sd_header_hbox.add_child(_sd_icon_frame)

	_sd_icon_rect = TextureRect.new()
	_sd_icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sd_icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sd_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sd_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sd_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sd_icon_frame.add_child(_sd_icon_rect)

	_sd_desc_rtl = RichTextLabel.new()
	_sd_desc_rtl.bbcode_enabled = true
	_sd_desc_rtl.fit_content = true
	_sd_desc_rtl.scroll_active = false
	_sd_desc_rtl.custom_minimum_size = Vector2(368, 58)
	_sd_desc_rtl.add_theme_font_size_override("normal_font_size", 18)
	_sd_desc_rtl.add_theme_color_override("default_color", Color(0.94, 0.90, 0.82, 1.0))
	_sd_desc_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_vbox.add_child(_sd_desc_rtl)

	_sd_kw_sep = HSeparator.new()
	_sd_kw_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_vbox.add_child(_sd_kw_sep)

	_sd_kw_rtl = RichTextLabel.new()
	_sd_kw_rtl.bbcode_enabled = true
	_sd_kw_rtl.fit_content = true
	_sd_kw_rtl.scroll_active = false
	_sd_kw_rtl.custom_minimum_size = Vector2(368, 40)
	_sd_kw_rtl.add_theme_font_size_override("normal_font_size", 15)
	_sd_kw_rtl.add_theme_color_override("default_color", Color(0.78, 0.76, 0.70, 1.0))
	_sd_kw_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sd_vbox.add_child(_sd_kw_rtl)


func _make_stat_label(parent_box: VBoxContainer) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent_box.add_child(lbl)
	return lbl


func show_for_unit(u: UnitInformationDO, grid_id: String = "", p_manager: UnitInformationManager = null) -> void:
	if u == null:
		close_popup()
		return
	var switched_unit := (inspected_unit != u)
	inspected_unit = u
	inspected_grid_id = grid_id if not grid_id.is_empty() else u.grid_id
	if p_manager != null:
		unit_manager = p_manager
	visible = true
	if switched_unit:
		_hide_skill_display()

	# Position alongside Left or Right board
	if inspected_grid_id.begins_with("L"):
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		offset_left = 260
		offset_right = 656
		offset_top = -235
		offset_bottom = 235
	else:
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		offset_left = -656
		offset_right = -260
		offset_top = -235
		offset_bottom = 235

	_ref_label.text = "[%s]" % u.reference_mark
	_name_label.text = Loc.t(u.name_key)

	var is_adv := (u.unit_kind == "enemy_adventurer")
	_lv_label.visible = is_adv
	_lv_label.text = "%s %d" % [Loc.t("udd_lv"), u.unit_lv]

	_class_row.visible = is_adv
	var cls_name := ""
	if is_adv:
		var cls_entry := ClassCodex.get_class_entry(u.class_id if not u.class_id.is_empty() else ClassCodex.class_id_for_enum(u.adventurer_class))
		cls_name = Loc.t(str(cls_entry.get("name_key", UnitInformationManager.get_class_name_key(u.adventurer_class))))
		_class_label.text = "%s: %s" % [Loc.t("udd_class"), cls_name]
		_class_icon.texture = _resolve_class_texture(u.adventurer_class)

	var hp_str := "%d / %d" % [u.current_hp, u.max_hp]
	_hp_value_label.text = hp_str

	var bars_str := ""
	if u.unit_kind == "boss":
		bars_str = Loc.t("bar_count", {"count": u.bars_remaining})
		_bars_value_label.text = bars_str
		_bars_value_label.visible = true
	else:
		_bars_value_label.visible = false

	_power_spd_label.text = "%s: %d   %s: %d" % [Loc.t("udd_power"), u.power, Loc.t("udd_spd"), u.spd]
	_mass_radius_label.text = "%s: %.2f   %s: %.2f" % [Loc.t("udd_mass"), u.mass, Loc.t("udd_radius"), u.radius]
	_hit_level_label.text = "%s: %d" % [Loc.t("udd_hit_level"), u.hit_level]

	var frz_str := ""
	if u.unit_kind == "boss":
		frz_str = Loc.t("uib_frenzy_format", {"pct": "%.1f" % (u.frenzy_power * 100.0)})
		_frenzy_label.text = "%s: %s" % [Loc.t("udd_frenzy"), frz_str]
		_frenzy_label.visible = true
	else:
		_frenzy_label.visible = false

	var cond_val := Loc.t("udd_cond_normal")
	if u.is_dead:
		cond_val = Loc.t("udd_cond_defeated")
	elif u.is_pocketed:
		cond_val = Loc.t("udd_cond_pocketed", {"turns": u.next_action_turns if u.next_action_turns > 0 else u.pocket_return_turns})
	elif u.is_focusing:
		cond_val = Loc.t("udd_cond_focusing")
	_condition_label.text = "%s: %s" % [Loc.t("udd_condition"), cond_val]

	var st_list: Array[String] = []
	for st in u.statuses:
		st_list.append(str(st))
	var st_str := ", ".join(st_list) if not st_list.is_empty() else Loc.t("udd_none")
	_statuses_label.text = "%s: %s" % [Loc.t("udd_statuses"), st_str]

	var sk_list: Array[String] = []
	for s in u.skills:
		sk_list.append(str(s))
	var sk_str := ", ".join(sk_list) if not sk_list.is_empty() else Loc.t("udd_none")
	_skills_header_label.text = "%s:" % Loc.t("udd_skills")

	_update_skill_icon_rows_in_place(u)
	if not switched_unit and _hovered_skill_row > 0 and _hovered_skill_slot >= 0 and _skill_display_panel.visible:
		simulate_skill_hover(_hovered_skill_row, _hovered_skill_slot, true)

	_cached_info = {
		"visible": true,
		"unit_id": u.unit_id,
		"grid_id": inspected_grid_id,
		"name_text": _name_label.text,
		"unit_lv_value": u.unit_lv,
		"class_visible": is_adv,
		"class_text": cls_name,
		"hp_text": hp_str,
		"bars_text": bars_str,
		"power_value": u.power,
		"spd_value": u.spd,
		"mass_value": u.mass,
		"radius_value": u.radius,
		"hit_level_value": u.hit_level,
		"frenzy_text": frz_str,
		"condition_text": cond_val,
		"skills_text": sk_str,
		"statuses_text": st_str,
		"skill_row1_slots": _row1_slot_meta.duplicate(true),
		"skill_row2_slots": _row2_slot_meta.duplicate(true),
		"passive_grid_capacity": MAX_PASSIVE_SLOTS,
		"passive_grid_columns": PASSIVE_GRID_COLUMNS,
		"passive_grid_rows": PASSIVE_GRID_ROWS,
		"row1_icon_size": ROW1_ICON_SIZE,
		"passive_icon_size": PASSIVE_ICON_SIZE,
		"skill_display_min_size": SKILL_DISPLAY_MIN_SIZE,
	}
	_refresh_hp_fill()


func _update_skill_icon_rows_in_place(u: UnitInformationDO) -> void:
	_row1_slot_meta.clear()
	_row2_slot_meta.clear()

	var move_skill: UnitSkill = null
	var attack_skill: UnitSkill = null
	var active_skill: UnitSkill = null
	var passive_skills: Array[UnitSkill] = []

	for s_item in u.skills:
		if s_item is MoveSkill:
			move_skill = s_item as UnitSkill
		elif s_item is AttackSkill:
			attack_skill = s_item as UnitSkill
		elif s_item is ActiveSkill:
			active_skill = s_item as UnitSkill
		elif s_item is PassiveSkill:
			passive_skills.append(s_item as UnitSkill)
		elif s_item is UnitSkill:
			passive_skills.append(s_item as UnitSkill)
		elif s_item is String:
			var built := UnitSkillManager.create_skill(str(s_item), u.default_skill_lv)
			if built is MoveSkill:
				move_skill = built
			elif built is AttackSkill:
				attack_skill = built
			elif built is ActiveSkill:
				active_skill = built
			elif built != null:
				passive_skills.append(built)

	# Row 1: 3 persistent square 68x68 slots -> [0: Move, 1: Attack, 2: Active]
	var row1_skills: Array = [move_skill, attack_skill, active_skill]
	var row1_categories: Array[String] = [UnitSkill.CATEGORY_MOVE, UnitSkill.CATEGORY_ATTACK, UnitSkill.CATEGORY_ACTIVE]
	for idx in range(3):
		var sk: UnitSkill = row1_skills[idx]
		var meta := _populate_row1_slot(idx, sk, row1_categories[idx])
		_row1_slot_meta.append(meta)

	# Passive Grid below: 3 rows x 10 columns = 30 persistent square 30x30 slots
	var lv_prefix := Loc.t("udd_lv") if Loc != null else "Lv"
	for idx in range(MAX_PASSIVE_SLOTS):
		var ctrl_info: Dictionary = _passive_slot_controls[idx]
		var style: StyleBoxFlat = ctrl_info["style"]
		var icon_rect: TextureRect = ctrl_info["icon_rect"]
		var lv_lbl: Label = ctrl_info["lv_lbl"]

		if idx < passive_skills.size():
			var sk := passive_skills[idx]
			style.bg_color = Color(0.15, 0.12, 0.09, 0.96)
			style.border_color = Color(0.68, 0.46, 0.92, 0.95)
			style.set_border_width_all(2)
			icon_rect.visible = true
			icon_rect.texture = _resolve_skill_icon_texture(sk)
			lv_lbl.visible = true
			var lv_text := "%s%d" % [lv_prefix, sk.skill_lv]
			if sk.counter > 0:
				lv_text = "x%d" % sk.counter
			lv_lbl.text = lv_text
			_row2_slot_meta.append({
				"row": 2,
				"slot_index": idx,
				"is_empty_slot": false,
				"skill_id": sk.skill_id,
				"name_text": sk.get_localized_name(),
				"category": UnitSkill.CATEGORY_PASSIVE,
				"skill_lv": sk.skill_lv,
				"lv_text": lv_text,
				"current_countdown": sk.current_countdown,
				"max_countdown": sk.max_countdown,
				"counter": sk.counter,
				"icon_size": PASSIVE_ICON_SIZE,
				"skill": sk,
			})
		else:
			style.bg_color = Color(0.07, 0.06, 0.05, 0.35)
			style.border_color = Color(0.26, 0.22, 0.18, 0.35)
			style.set_border_width_all(1)
			icon_rect.visible = false
			lv_lbl.visible = false


func _populate_row1_slot(slot_idx: int, sk: UnitSkill, category: String) -> Dictionary:
	var ctrl_info: Dictionary = _row1_slot_controls[slot_idx]
	var style: StyleBoxFlat = ctrl_info["style"]
	var empty_lbl: Label = ctrl_info["empty_lbl"]
	var icon_rect: TextureRect = ctrl_info["icon_rect"]
	var lv_lbl: Label = ctrl_info["lv_lbl"]
	var badge_lbl: Label = ctrl_info["badge_lbl"]
	var name_lbl: Label = ctrl_info["name_lbl"]

	if sk == null:
		style.bg_color = Color(0.08, 0.07, 0.06, 0.55)
		style.border_color = Color(0.32, 0.28, 0.24, 0.55)
		style.set_border_width_all(1)
		empty_lbl.visible = true
		icon_rect.visible = false
		lv_lbl.visible = false
		badge_lbl.visible = false
		name_lbl.visible = false
		return {
			"row": 1,
			"slot_index": slot_idx,
			"is_empty_slot": true,
			"skill_id": "",
			"category": category,
			"icon_size": ROW1_ICON_SIZE,
			"skill": null,
		}

	style.bg_color = Color(0.15, 0.12, 0.09, 0.96)
	match category:
		UnitSkill.CATEGORY_MOVE:
			style.border_color = Color(0.28, 0.78, 0.56, 0.95)
		UnitSkill.CATEGORY_ATTACK:
			style.border_color = Color(0.92, 0.34, 0.24, 0.95)
		UnitSkill.CATEGORY_ACTIVE:
			style.border_color = Color(0.96, 0.78, 0.22, 0.95)
		_:
			style.border_color = Color(0.68, 0.46, 0.92, 0.95)
	style.set_border_width_all(2)

	empty_lbl.visible = false
	icon_rect.visible = true
	icon_rect.texture = _resolve_skill_icon_texture(sk)

	var lv_prefix := Loc.t("udd_lv") if Loc != null else "Lv"
	var lv_str := "%s%d" % [lv_prefix, sk.skill_lv]
	lv_lbl.text = lv_str
	lv_lbl.visible = true

	var badge_text := ""
	if sk.max_countdown > 0:
		badge_text = "%dT" % sk.current_countdown
	elif sk.counter > 0:
		badge_text = "x%d" % sk.counter
	badge_lbl.text = badge_text
	badge_lbl.visible = not badge_text.is_empty()

	name_lbl.text = sk.get_localized_name()
	name_lbl.visible = true

	return {
		"row": 1,
		"slot_index": slot_idx,
		"is_empty_slot": false,
		"skill_id": sk.skill_id,
		"name_text": sk.get_localized_name(),
		"category": category,
		"skill_lv": sk.skill_lv,
		"lv_text": lv_str,
		"current_countdown": sk.current_countdown,
		"max_countdown": sk.max_countdown,
		"counter": sk.counter,
		"icon_size": ROW1_ICON_SIZE,
		"skill": sk,
	}


func simulate_skill_hover(row_num: int, slot_index: int, hovered: bool) -> void:
	if not hovered or inspected_unit == null:
		_hide_skill_display()
		return
	var slots := _row1_slot_meta if row_num == 1 else _row2_slot_meta
	if slot_index < 0 or slot_index >= slots.size():
		_hide_skill_display()
		return
	var meta: Dictionary = slots[slot_index]
	if bool(meta.get("is_empty_slot", true)):
		_hide_skill_display()
		return
	var sk: UnitSkill = meta.get("skill", null) as UnitSkill
	if sk == null:
		_hide_skill_display()
		return

	_hovered_skill_row = row_num
	_hovered_skill_slot = slot_index

	var formatted := sk.format_display_description(inspected_unit, unit_manager)
	var s_name := sk.get_localized_name()
	var s_type := sk.get_localized_type()
	var lv_str := "%s %d" % [Loc.t("udd_lv") if Loc != null else "Lv", sk.skill_lv]

	_sd_title_label.text = "%s   (%s)" % [s_name, lv_str]
	_sd_meta_label.text = "%s  •  %s" % [s_type, lv_str]
	if _sd_icon_rect != null:
		_sd_icon_rect.texture = _resolve_skill_icon_texture(sk)
	if _sd_icon_style != null:
		match sk.skill_category:
			UnitSkill.CATEGORY_MOVE:
				_sd_icon_style.border_color = Color(0.28, 0.78, 0.56, 0.95)
			UnitSkill.CATEGORY_ATTACK:
				_sd_icon_style.border_color = Color(0.92, 0.34, 0.24, 0.95)
			UnitSkill.CATEGORY_ACTIVE:
				_sd_icon_style.border_color = Color(0.96, 0.78, 0.22, 0.95)
			_:
				_sd_icon_style.border_color = Color(0.68, 0.46, 0.92, 0.95)
	_sd_desc_rtl.text = str(formatted.get("bbcode_text", ""))

	var kw_list: Array = formatted.get("keywords", [])
	var kw_bbcode_lines: Array[String] = []
	for item in kw_list:
		if item is Dictionary:
			kw_bbcode_lines.append("[color=%s]%s[/color]: %s" % [
				UnitSkill.COLOR_KEYWORD_HEX,
				str(item.get("keyword", "")),
				str(item.get("meaning", "")),
			])
	var has_kw := not kw_bbcode_lines.is_empty()
	_sd_kw_sep.visible = has_kw
	_sd_kw_rtl.visible = has_kw
	_sd_kw_rtl.text = "\n".join(kw_bbcode_lines)

	var g_rect := get_global_rect()
	if inspected_grid_id.begins_with("L"):
		_skill_display_panel.global_position = Vector2(g_rect.end.x + 10.0, g_rect.position.y + 60.0)
	else:
		_skill_display_panel.global_position = Vector2(maxf(12.0, g_rect.position.x - (SKILL_DISPLAY_MIN_SIZE.x + 12.0)), g_rect.position.y + 60.0)
	_skill_display_panel.visible = true

	_skill_display_info = {
		"visible": true,
		"skill_id": sk.skill_id,
		"name_text": s_name,
		"title_text": _sd_title_label.text,
		"type_text": s_type,
		"skill_lv": sk.skill_lv,
		"min_size": _skill_display_panel.custom_minimum_size,
		"icon_visible": _sd_icon_rect != null and _sd_icon_rect.texture != null,
		"icon_size": _sd_icon_frame.custom_minimum_size if _sd_icon_frame != null else Vector2.ZERO,
		"description_plain": str(formatted.get("plain_text", "")),
		"description_bbcode": str(formatted.get("bbcode_text", "")),
		"keywords": kw_list,
		"keywords_text": str(formatted.get("keywords_text", "")),
		"resolved_vars": formatted.get("resolved_vars", {}),
	}


func _hide_skill_display() -> void:
	_hovered_skill_row = 0
	_hovered_skill_slot = -1
	if _skill_display_panel != null:
		_skill_display_panel.visible = false
	_skill_display_info = {"visible": false}


func get_skill_display_info() -> Dictionary:
	return _skill_display_info.duplicate(true)


func _refresh_hp_fill() -> void:
	if inspected_unit == null or _hp_bar_bg == null or _hp_fill == null:
		return
	var max_v := maxi(inspected_unit.max_hp, 1)
	var cur_v := clampi(inspected_unit.current_hp, 0, max_v)
	var ratio := float(cur_v) / float(max_v)
	var bar_w := _hp_bar_bg.size.x if _hp_bar_bg.size.x > 4.0 else 146.0
	_hp_fill.offset_right = bar_w * ratio
	var full_green := Color(0.11, 0.58, 0.18, 0.98)
	var low_greenish_yellow := Color(0.76, 0.84, 0.14, 0.98)
	_hp_fill.color = low_greenish_yellow.lerp(full_green, clampf(ratio, 0.0, 1.0))


func close_popup() -> void:
	_hide_skill_display()
	inspected_unit = null
	inspected_grid_id = ""
	visible = false
	_cached_info = {"visible": false}


func get_info() -> Dictionary:
	if not visible or inspected_unit == null:
		return {"visible": false}
	return _cached_info.duplicate(true)


func _resolve_skill_icon_texture(sk: UnitSkill) -> Texture2D:
	if sk != null and not sk.icon_path.is_empty() and ResourceLoader.exists(sk.icon_path):
		var tex := load(sk.icon_path) as Texture2D
		if tex != null:
			return tex
	if sk is MoveSkill:
		return TEX_DOUBLE_ARROW
	if sk is AttackSkill:
		return TEX_SWORD
	if sk is ActiveSkill:
		return TEX_GOAL_FLAG
	return TEX_CLASS_KNIGHT


func _resolve_class_texture(adv_class: int) -> Texture2D:
	match adv_class:
		EnemyAdventurer.AdventurerClass.GUARD:
			return TEX_CLASS_KNIGHT
		EnemyAdventurer.AdventurerClass.BRAWLER:
			return TEX_CLASS_WARRIOR
		EnemyAdventurer.AdventurerClass.SCOUT:
			return TEX_CLASS_RANGER
		EnemyAdventurer.AdventurerClass.ACOLYTE:
			return TEX_CLASS_MAGE
		_:
			return TEX_CLASS_WARRIOR
