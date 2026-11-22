class_name UnitDetailDisplay
extends PanelContainer

## Popup inspection window alongside the Unit Information Board that displays
## full localized details for a clicked Unit Display:
## - Unit name + Reference Mark
## - Detailed Class name & Class Mark icon (if Enemy Adventurer)
## - HP bar displaying numeric "HP / Max HP" (plus remaining Health Bar count if Boss Monster)
## - Attack power, Puck Mass & Radius
## - Current Hit Level and Frenzy Power (if Boss Monster)
## - Special condition (Normal, Focusing, Pocketed + return turns, Defeated)
## - Skills and Statuses (buffs/debuffs/conditional statuses)

const TEX_CLASS_KNIGHT := preload("res://src/resource/battlefield/class_knight.png")
const TEX_CLASS_WARRIOR := preload("res://src/resource/battlefield/class_warrior.png")
const TEX_CLASS_RANGER := preload("res://src/resource/battlefield/class_ranger.png")
const TEX_CLASS_MAGE := preload("res://src/resource/battlefield/class_mage.png")

var inspected_unit: UnitInformationDO = null
var inspected_grid_id: String = ""

var _name_label: Label = null
var _ref_label: Label = null
var _class_row: HBoxContainer = null
var _class_icon: TextureRect = null
var _class_label: Label = null
var _hp_bar_frame: PanelContainer = null
var _hp_bar_bg: ColorRect = null
var _hp_fill: ColorRect = null
var _hp_value_label: Label = null
var _bars_value_label: Label = null
var _power_label: Label = null
var _mass_radius_label: Label = null
var _hit_level_label: Label = null
var _frenzy_label: Label = null
var _condition_label: Label = null
var _skills_label: Label = null
var _statuses_label: Label = null

var _cached_info: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(380, 340)
	z_index = 30
	visible = false
	_build_ui()


func _build_ui() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.10, 0.08, 0.06, 0.96)
	box.border_color = Color(0.86, 0.70, 0.28, 0.96)
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(16)
	box.shadow_color = Color(0, 0, 0, 0.65)
	box.shadow_size = 8
	add_theme_stylebox_override("panel", box)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Title row: Reference Mark + Unit Name
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	_ref_label = Label.new()
	_ref_label.add_theme_font_size_override("font_size", 24)
	_ref_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.32, 1.0))
	title_row.add_child(_ref_label)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78, 1.0))
	title_row.add_child(_name_label)

	# Class row (visible for Enemy Adventurers)
	_class_row = HBoxContainer.new()
	_class_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_class_row)

	_class_icon = TextureRect.new()
	_class_icon.custom_minimum_size = Vector2(28, 28)
	_class_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_class_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_class_row.add_child(_class_icon)

	_class_label = Label.new()
	_class_label.add_theme_font_size_override("font_size", 19)
	_class_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.70, 1.0))
	_class_row.add_child(_class_label)

	# HP Bar with numeric HP / Max HP overlay + optional Boss bar count
	var hp_hbox := HBoxContainer.new()
	hp_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_hbox)

	_hp_bar_frame = PanelContainer.new()
	_hp_bar_frame.custom_minimum_size = Vector2(240, 28)
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
	_hp_value_label.add_theme_font_size_override("font_size", 17)
	_hp_value_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	_hp_value_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.98))
	_hp_value_label.add_theme_constant_override("outline_size", 4)
	_hp_bar_bg.add_child(_hp_value_label)

	_bars_value_label = Label.new()
	_bars_value_label.add_theme_font_size_override("font_size", 19)
	_bars_value_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.36, 1.0))
	hp_hbox.add_child(_bars_value_label)

	_power_label = _make_stat_label(vbox)
	_mass_radius_label = _make_stat_label(vbox)
	_hit_level_label = _make_stat_label(vbox)
	_frenzy_label = _make_stat_label(vbox)
	_condition_label = _make_stat_label(vbox)
	_skills_label = _make_stat_label(vbox)
	_statuses_label = _make_stat_label(vbox)


func _make_stat_label(parent_box: VBoxContainer) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent_box.add_child(lbl)
	return lbl


func show_for_unit(u: UnitInformationDO, grid_id: String = "") -> void:
	if u == null:
		close_popup()
		return
	inspected_unit = u
	inspected_grid_id = grid_id if not grid_id.is_empty() else u.grid_id
	visible = true

	# Position alongside Left or Right board (larger popup window)
	if inspected_grid_id.begins_with("L"):
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		offset_left = 260
		offset_right = 650
		offset_top = -180
		offset_bottom = 180
	else:
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		offset_left = -650
		offset_right = -260
		offset_top = -180
		offset_bottom = 180

	_ref_label.text = "[%s]" % u.reference_mark
	_name_label.text = Loc.t(u.name_key)

	var is_adv := (u.unit_kind == "enemy_adventurer")
	_class_row.visible = is_adv
	var cls_name := ""
	if is_adv:
		cls_name = Loc.t(UnitInformationManager.get_class_name_key(u.adventurer_class))
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

	_power_label.text = "%s: %d" % [Loc.t("udd_power"), u.power]
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
		cond_val = Loc.t("udd_cond_pocketed", {"turns": u.pocket_return_turns})
	elif u.is_focusing:
		cond_val = Loc.t("udd_cond_focusing")
	_condition_label.text = "%s: %s" % [Loc.t("udd_condition"), cond_val]

	var sk_list: Array[String] = []
	for s in u.skills:
		sk_list.append(str(s))
	var sk_str := ", ".join(sk_list) if not sk_list.is_empty() else Loc.t("udd_none")
	_skills_label.text = "%s: %s" % [Loc.t("udd_skills"), sk_str]

	var st_list: Array[String] = []
	for st in u.statuses:
		st_list.append(str(st))
	var st_str := ", ".join(st_list) if not st_list.is_empty() else Loc.t("udd_none")
	_statuses_label.text = "%s: %s" % [Loc.t("udd_statuses"), st_str]

	_cached_info = {
		"visible": true,
		"unit_id": u.unit_id,
		"grid_id": inspected_grid_id,
		"name_text": _name_label.text,
		"class_visible": is_adv,
		"class_text": cls_name,
		"hp_text": hp_str,
		"bars_text": bars_str,
		"power_value": u.power,
		"mass_value": u.mass,
		"radius_value": u.radius,
		"hit_level_value": u.hit_level,
		"frenzy_text": frz_str,
		"condition_text": cond_val,
		"skills_text": sk_str,
		"statuses_text": st_str,
	}
	_refresh_hp_fill()


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
	inspected_unit = null
	inspected_grid_id = ""
	visible = false
	_cached_info = {"visible": false}


func get_info() -> Dictionary:
	if not visible or inspected_unit == null:
		return {"visible": false}
	return _cached_info.duplicate(true)


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
