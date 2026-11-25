class_name TimeBoard
extends Control

## The Time Board view: a dumb renderer for board state fed to it.
## - Energy Bar: two serpentine 10-slot bars — slot 0..9 on the lower bar (left→right),
##   slot 10..19 on the upper bar (right→left toward the goal at slot 19, upper-left).
## - Upper Bar 11-Slot Layout: the upper bar has 11 visual slots (10 Energy slots 19..10
##   plus 1 always-empty extension slot on the upper-right, slot 11).
## - Fixed Pool of 6 Action Tags (`_cycle_tag_nodes`, one for each cycle step `[3, 4, 6, 8, 9, 12]`):
##   * Each of the 6 tags is an independent node tracking its own `turns` (`0..12`);
##     a tag's position and glide animation never depend on any other tag or slot container.
##   * While a tag stands at the goal (`turns == 0`), it has NOT respawned on the right;
##     only after it disappears from the goal does it reset to `turns = 12` (off-bar) and
##     glide in to slot 11 (`turns = 11`) on the following Turn.
##   * A tag arriving at the goal (`1 → 0`) lifts up (`GOAL_LIFT_Y`) ONLY after it finishes
##     gliding horizontally and stops at the goal.
## - Second Player's Bar (`SecondaryBarBox` in 2-player multiplayer): positioned BELOW
##   `LowerBar` (where the removed lower-bar action tags used to be) so the Time Board
##   always has clean space for both players' bars.

const SLOT_COUNT := 20
const BAR_SIZE := 10
const UPPER_SLOT_COUNT := 11
const EXTRA_UPPER_EMPTY_SLOTS := 1
const GOAL_SLOT := 19
const MAX_VISIBLE_TURNS := 11 # Slot 11's right edge is turns = 11 (slot = 8); turns = 12 is off-bar ready to glide in
const CYCLE_TAG_COUNT := 6
const CYCLE_STEPS: Array[int] = [3, 4, 6, 8, 9, 12]
const GOAL_LIFT_Y := -8.0

@export var slot_size := Vector2(38, 15)
@export var secondary_slot_size := Vector2(38, 8)
@export var slot_gap := 3.0
@export var turn_duration := 1.0
@export var charge_tween_duration := 0.15
@export var rewind_slot_duration := 0.08
@export var slot_color := Color(0.1, 0.09, 0.09, 0.85)
@export var empty_extension_slot_color := Color(0.07, 0.06, 0.06, 0.55)
@export var goal_color := Color(0.55, 0.16, 0.14, 0.9)
@export var energy_color := Color(0.95, 0.72, 0.18, 1.0)
@export var charging_color := Color(0.95, 0.72, 0.18, 0.4)
@export var consume_preview_color := Color(0.26, 0.82, 0.96, 0.95)
@export var overdrag_preview_color := Color(0.92, 0.18, 0.16, 0.95)

@export var tag_default_color := Color(0.95, 0.88, 0.72, 1.0)
@export var tag_cycle_6_light_red := Color(1.0, 0.54, 0.56, 1.0)
@export var tag_cycle_4_8_light_blue := Color(0.52, 0.78, 1.0, 1.0)
@export var tag_cycle_12_light_purple := Color(0.82, 0.56, 1.0, 1.0)
@export var count_color := Color(0.14, 0.06, 0.03, 1.0)
@export var demo_mode := false


## Custom-drawn Pin + Count Label for an Action Tag:
## - Circle is 50% larger (diameter 24px, radius 12px; 12th tag is +20% larger = 1.2x).
## - Triangle sides match the left/right tangent edges of the circle.
## - When `show_circle` is false (`count == 0`), only the bottom triangle pointer renders.
class TagPinDrawer extends Control:
	var fill_color: Color = Color(0.95, 0.88, 0.72, 1.0)
	var border_color: Color = Color(0.22, 0.11, 0.06, 0.98)
	var show_circle: bool = true
	var scale_mult: float = 1.0
	var is_at_goal: bool = false

	func _draw() -> void:
		var tip := Vector2(0.0, 0.0)
		var out_col := Color(1.0, 0.88, 0.32, 1.0) if is_at_goal else border_color
		var border_w := 2.2 if is_at_goal else 1.6

		if not show_circle:
			var tri_h := 10.5 * scale_mult
			var tri_hw := 6.8 * scale_mult
			var out_pts := PackedVector2Array([
				Vector2(-tri_hw - border_w, -tri_h - border_w * 0.6),
				Vector2(tri_hw + border_w, -tri_h - border_w * 0.6),
				Vector2(0.0, border_w),
			])
			draw_colored_polygon(out_pts, out_col)
			var in_pts := PackedVector2Array([
				Vector2(-tri_hw, -tri_h),
				Vector2(tri_hw, -tri_h),
				tip,
			])
			draw_colored_polygon(in_pts, fill_color)
			return

		var r := 11.5 * scale_mult
		var hc := 19.5 * scale_mult
		var center := Vector2(0.0, -hc)
		var sin_a := clampf(r / hc, 0.1, 0.95)
		var cos_a := sqrt(maxf(0.0, 1.0 - sin_a * sin_a))

		var r_out := r + border_w
		var tip_out := Vector2(0.0, border_w * 1.1)
		var l_out := Vector2(-r_out * cos_a, -hc + r_out * sin_a)
		var r_pt_out := Vector2(r_out * cos_a, -hc + r_out * sin_a)
		draw_colored_polygon(PackedVector2Array([l_out, r_pt_out, tip_out]), out_col)
		draw_circle(center, r_out, out_col)

		var l_in := Vector2(-r * cos_a, -hc + r * sin_a)
		var r_pt_in := Vector2(r * cos_a, -hc + r * sin_a)
		draw_colored_polygon(PackedVector2Array([l_in, r_pt_in, tip]), fill_color)
		draw_circle(center, r, fill_color)

		draw_arc(center, r - 1.2, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.35), 1.1)


@onready var _secondary_bar_box: VBoxContainer = $Frame/Margin/Content/Board/SecondaryBarBox
@onready var _secondary_upper_bar: HBoxContainer = $Frame/Margin/Content/Board/SecondaryBarBox/SecondaryUpperBarRow
@onready var _secondary_lower_bar: HBoxContainer = $Frame/Margin/Content/Board/SecondaryBarBox/SecondaryLowerBar
@onready var _upper_tags: HBoxContainer = $Frame/Margin/Content/Board/UpperTags
@onready var _upper_bar: HBoxContainer = $Frame/Margin/Content/Board/UpperBarRow
@onready var _lower_bar: HBoxContainer = $Frame/Margin/Content/Board/LowerBar
@onready var _lower_tags: HBoxContainer = $Frame/Margin/Content/Board/LowerTags

var _fills: Array[ColorRect] = []
var _charging_fills: Array[ColorRect] = []
var _consume_fills: Array[ColorRect] = []
var _overdrag_fills: Array[ColorRect] = []
var _secondary_fills: Array[ColorRect] = []
var _secondary_charging_fills: Array[ColorRect] = []
var _secondary_consume_fills: Array[ColorRect] = []
var _secondary_overdrag_fills: Array[ColorRect] = []

## Fixed list of 6 persistent Action Tag objects (`0..5` -> `[3, 4, 6, 8, 9, 12]`).
var _upper_tags_layer: Control = null
var _secondary_spacer: Control = null
var _cycle_tag_nodes: Array[Control] = []
var _cycle_tag_pins: Array[TagPinDrawer] = []
var _cycle_tag_counts: Array[Label] = []
var _cycle_tag_tweens: Array[Tween] = []
var _cycle_tag_state: Array[Dictionary] = []
var _slot_to_tag_index: Dictionary = {} # slot -> tag_index (0..5)

var _fill_tweens: Dictionary = {}
var _rewind_tween: Tween = null
var _secondary_rewind_tween: Tween = null
var _target_energy_ratios: Array[float] = []
var _target_charging_ratios: Array[float] = []
var _secondary_target_energy_ratios: Array[float] = []
var _secondary_target_charging_ratios: Array[float] = []
var _perspective_role: String = "a"

var last_animation_kind := ""
var _state: Dictionary = {"energy": 0.0, "charge": 0.0, "preview_cost": 0.0, "tags": {}}


func _ready() -> void:
	_build_board()
	render_state(_state)


# ----- construction -----

func _build_board() -> void:
	for row in [_lower_bar, _upper_bar, _secondary_lower_bar, _secondary_upper_bar]:
		if row != null:
			row.add_theme_constant_override("separation", int(slot_gap))
	if _lower_tags != null:
		_lower_tags.visible = false
	if _secondary_bar_box != null and _secondary_bar_box.get_parent() != null:
		# Ensure the 2nd player's bar sits below LowerBar with a clear gap between the two players' bars
		var board_parent := _secondary_bar_box.get_parent()
		_secondary_spacer = Control.new()
		_secondary_spacer.name = "SecondaryBarSpacer"
		_secondary_spacer.custom_minimum_size = Vector2(0, 8)
		_secondary_spacer.visible = _secondary_bar_box.visible
		_secondary_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_parent.add_child(_secondary_spacer)
		board_parent.move_child(_secondary_spacer, _lower_bar.get_index() + 1)
		board_parent.move_child(_secondary_bar_box, _secondary_spacer.get_index() + 1)

	_fills.resize(SLOT_COUNT)
	_charging_fills.resize(SLOT_COUNT)
	_consume_fills.resize(SLOT_COUNT)
	_overdrag_fills.resize(SLOT_COUNT)
	_secondary_fills.resize(SLOT_COUNT)
	_secondary_charging_fills.resize(SLOT_COUNT)
	_secondary_consume_fills.resize(SLOT_COUNT)
	_secondary_overdrag_fills.resize(SLOT_COUNT)
	_target_energy_ratios.resize(SLOT_COUNT)
	_target_energy_ratios.fill(0.0)
	_target_charging_ratios.resize(SLOT_COUNT)
	_target_charging_ratios.fill(0.0)
	_secondary_target_energy_ratios.resize(SLOT_COUNT)
	_secondary_target_energy_ratios.fill(0.0)
	_secondary_target_charging_ratios.resize(SLOT_COUNT)
	_secondary_target_charging_ratios.fill(0.0)

	# Lower bar: 10 Energy slots (0..9) left→right, plus 1 invisible spacer on main lower bar only.
	# Secondary opponent bars have ONLY 10 slots (no 11th extension slot, since opponent bar has no Action Tags).
	for slot in range(BAR_SIZE):
		_lower_bar.add_child(_make_slot_cell(slot, false))
		if _secondary_lower_bar != null:
			_secondary_lower_bar.add_child(_make_secondary_slot_cell(slot, false))
	for _ext in range(EXTRA_UPPER_EMPTY_SLOTS):
		_lower_bar.add_child(_make_spacer_cell(slot_size))

	# Upper bar: 11 slots on main upper bar (10 Energy slots 19..10 + 1 always-empty extension slot for Action Tags),
	# while secondary opponent upper bar has ONLY 10 slots (19..10).
	for column in range(UPPER_SLOT_COUNT):
		var slot := GOAL_SLOT - column
		if column < BAR_SIZE:
			_upper_bar.add_child(_make_slot_cell(slot, true))
			if _secondary_upper_bar != null:
				_secondary_upper_bar.add_child(_make_secondary_slot_cell(slot, true))
		else:
			_upper_bar.add_child(_make_empty_extension_slot_cell(slot_size))

	_build_six_persistent_tags()


func _build_six_persistent_tags() -> void:
	_upper_tags_layer = Control.new()
	_upper_tags_layer.name = "UpperTagsLayer"
	var total_w := float(UPPER_SLOT_COUNT) * slot_size.x + float(UPPER_SLOT_COUNT - 1) * slot_gap
	_upper_tags_layer.custom_minimum_size = Vector2(total_w, 42.0)
	_upper_tags_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upper_tags.add_child(_upper_tags_layer)

	_cycle_tag_nodes.resize(CYCLE_TAG_COUNT)
	_cycle_tag_pins.resize(CYCLE_TAG_COUNT)
	_cycle_tag_counts.resize(CYCLE_TAG_COUNT)
	_cycle_tag_tweens.resize(CYCLE_TAG_COUNT)
	_cycle_tag_state.resize(CYCLE_TAG_COUNT)

	for i in range(CYCLE_TAG_COUNT):
		var mover := Control.new()
		mover.name = "CycleTag_%d" % CYCLE_STEPS[i]
		mover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mover.modulate.a = 0.0
		mover.position = Vector2(_x_for_turns(CYCLE_STEPS[i]), 0.0)
		_upper_tags_layer.add_child(mover)

		var pin := TagPinDrawer.new()
		pin.position = Vector2(0.0, 41.0)
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mover.add_child(pin)

		var count := Label.new()
		count.modulate = count_color
		count.add_theme_font_size_override("font_size", 15)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.size = Vector2(36.0, 28.0)
		count.position = Vector2(-18.0, 41.0 - 19.5 - 14.0)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mover.add_child(count)

		_cycle_tag_nodes[i] = mover
		_cycle_tag_pins[i] = pin
		_cycle_tag_counts[i] = count
		_cycle_tag_tweens[i] = null
		_cycle_tag_state[i] = {}


func _x_for_turns(turns_to_goal: int) -> float:
	var pitch := slot_size.x + slot_gap
	return float(turns_to_goal) * pitch - slot_gap * 0.5


func get_upper_slot_count() -> int:
	return UPPER_SLOT_COUNT


func get_secondary_upper_slot_count() -> int:
	return _secondary_upper_bar.get_child_count() if _secondary_upper_bar != null else BAR_SIZE


func get_cycle_tag_node_count() -> int:
	return _cycle_tag_nodes.size()


func is_secondary_bar_below_lower_bar() -> bool:
	if _secondary_bar_box == null or _lower_bar == null:
		return false
	return _secondary_bar_box.get_index() > _lower_bar.get_index()


func _make_spacer_cell(sz: Vector2) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = sz
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _make_empty_extension_slot_cell(sz: Vector2) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = sz
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = empty_extension_slot_color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(bg)
	return cell


func _make_secondary_slot_cell(slot: int, upper: bool) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = secondary_slot_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = goal_color if slot == GOAL_SLOT else slot_color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(bg)
	var fill := _make_bar_rect(energy_color, upper)
	cell.add_child(fill)
	_secondary_fills[slot] = fill
	var charging_fill := _make_bar_rect(charging_color, upper)
	cell.add_child(charging_fill)
	_secondary_charging_fills[slot] = charging_fill
	var consume_fill := _make_bar_rect(consume_preview_color, upper)
	cell.add_child(consume_fill)
	_secondary_consume_fills[slot] = consume_fill
	var overdrag_fill := _make_bar_rect(overdrag_preview_color, upper)
	cell.add_child(overdrag_fill)
	_secondary_overdrag_fills[slot] = overdrag_fill
	return cell


func _make_slot_cell(slot: int, upper: bool) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = slot_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = goal_color if slot == GOAL_SLOT else slot_color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(bg)
	var fill := _make_bar_rect(energy_color, upper)
	cell.add_child(fill)
	_fills[slot] = fill
	var charging_fill := _make_bar_rect(charging_color, upper)
	cell.add_child(charging_fill)
	_charging_fills[slot] = charging_fill
	var consume_fill := _make_bar_rect(consume_preview_color, upper)
	cell.add_child(consume_fill)
	_consume_fills[slot] = consume_fill
	var overdrag_fill := _make_bar_rect(overdrag_preview_color, upper)
	cell.add_child(overdrag_fill)
	_overdrag_fills[slot] = overdrag_fill
	return cell


func _make_bar_rect(color: Color, upper: bool) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if upper:
		rect.anchor_left = 1.0
		rect.anchor_right = 1.0
		rect.offset_left = 0.0
		rect.offset_right = 0.0
	else:
		rect.anchor_left = 0.0
		rect.anchor_right = 0.0
		rect.offset_left = 0.0
		rect.offset_right = 0.0
	rect.anchor_top = 0.0
	rect.anchor_bottom = 1.0
	rect.offset_top = 0.0
	rect.offset_bottom = 0.0
	return rect


# ----- public view API (the model→view seam) -----

func set_perspective_role(role: String) -> void:
	var normalized := role if (role == "a" or role == "b") else "spectator"
	if _perspective_role == normalized:
		return
	_perspective_role = normalized
	render_state(_state)


func get_perspective_role() -> String:
	return _perspective_role


func is_two_player_mode() -> bool:
	return _secondary_bar_box != null and _secondary_bar_box.visible


func _normalize_state(raw: Dictionary) -> Dictionary:
	var s := raw.duplicate(true)
	if not s.has("preview_cost"):
		s["preview_cost"] = _state.get("preview_cost", 0.0)
	if not s.has("preview_seat"):
		s["preview_seat"] = _state.get("preview_seat", "")
	if not s.has("preview_in_deadzone"):
		s["preview_in_deadzone"] = _state.get("preview_in_deadzone", false)
	if s.has("turn_progress") and not s.has("charge"):
		s["charge"] = float(s["turn_progress"])
	elif not s.has("charge"):
		s["charge"] = 0.0
	if not s.has("has_player_b"):
		s["has_player_b"] = false
	if s.has("energy_a"):
		s["energy_a"] = float(s["energy_a"])
	else:
		s["energy_a"] = float(s.get("energy", 0.0))
	if s.has("energy_b"):
		s["energy_b"] = float(s["energy_b"])
	else:
		s["energy_b"] = 0.0
	if not s.has("tags"):
		if s.has("action_tags") and s["action_tags"] is Dictionary:
			s["tags"] = s["action_tags"].duplicate(true)
		elif s.has("action_tags") and s["action_tags"] is Array:
			var tag_map := {}
			for item in s["action_tags"]:
				if item is Dictionary and item.has("slot"):
					tag_map[int(item["slot"])] = {
						"count": int(item.get("count", 0)),
						"turns": int(item.get("turns", 0)),
						"cycle_step": int(item.get("cycle_step", 0)),
						"is_cycle_12": bool(item.get("is_cycle_12", false)),
					}
			s["tags"] = tag_map
		else:
			s["tags"] = {}
	return s


func _main_energy_of(s: Dictionary) -> float:
	var two_p := bool(s.get("has_player_b", false))
	if two_p and _perspective_role == "b":
		return float(s.get("energy_b", 0.0))
	return float(s.get("energy_a", s.get("energy", 0.0)))


func _secondary_energy_of(s: Dictionary) -> float:
	if _perspective_role == "b":
		return float(s.get("energy_a", s.get("energy", 0.0)))
	return float(s.get("energy_b", 0.0))


## Maps incoming state (`cycle_tags` list of 6, or `tags` dictionary keyed by slot)
## onto the 6 persistent tag slots `0..5`.
func _extract_six_tags(s: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]
	_slot_to_tag_index.clear()

	if s.has("cycle_tags") and s["cycle_tags"] is Array:
		var ct_arr: Array = s["cycle_tags"]
		for i in range(mini(CYCLE_TAG_COUNT, ct_arr.size())):
			if ct_arr[i] is Dictionary:
				var d: Dictionary = (ct_arr[i] as Dictionary).duplicate(true)
				var t_rem := int(d.get("turns", CYCLE_STEPS[i]))
				var slot := GOAL_SLOT - t_rem
				d["slot"] = slot
				d["tag_index"] = i
				result[i] = d
				_slot_to_tag_index[slot] = i
		return result

	var tags_dict: Dictionary = s.get("tags", {})
	var used_indices: Dictionary = {}
	var unassigned_slots: Array[int] = []

	# Pass 1: explicit tag_index or cycle_step match
	for raw_slot in tags_dict.keys():
		var slot := int(raw_slot)
		var d: Dictionary = (tags_dict[raw_slot] as Dictionary).duplicate(true)
		var t_rem := int(d.get("turns", GOAL_SLOT - slot))
		d["turns"] = t_rem
		d["slot"] = slot
		var idx := -1
		if d.has("tag_index"):
			var candidate := int(d["tag_index"])
			if candidate >= 0 and candidate < CYCLE_TAG_COUNT and not used_indices.has(candidate):
				idx = candidate
		if idx < 0 and d.has("cycle_step"):
			var step_idx := CYCLE_STEPS.find(int(d["cycle_step"]))
			if step_idx >= 0 and not used_indices.has(step_idx):
				idx = step_idx
		if idx >= 0:
			used_indices[idx] = true
			d["tag_index"] = idx
			result[idx] = d
			_slot_to_tag_index[slot] = idx
		else:
			unassigned_slots.append(slot)

	# Pass 2: match any unassigned slot to the persistent tag that was at `slot - 1` or `slot` previously
	unassigned_slots.sort()
	var still_unassigned: Array[int] = []
	for slot in unassigned_slots:
		var d: Dictionary = (tags_dict[slot] as Dictionary).duplicate(true)
		var t_rem := int(d.get("turns", GOAL_SLOT - slot))
		d["turns"] = t_rem
		d["slot"] = slot
		var matched_idx := -1
		for i in range(CYCLE_TAG_COUNT):
			if used_indices.has(i) or _cycle_tag_state[i].is_empty():
				continue
			var prev_slot := int(_cycle_tag_state[i].get("slot", -99))
			if (prev_slot == slot - 1 or prev_slot == slot) and int(_cycle_tag_state[i].get("count", -1)) == int(d.get("count", -2)):
				matched_idx = i
				break
		if matched_idx >= 0:
			used_indices[matched_idx] = true
			d["tag_index"] = matched_idx
			result[matched_idx] = d
			_slot_to_tag_index[slot] = matched_idx
		else:
			still_unassigned.append(slot)

	# Pass 3: fill any remaining unassigned slots into free indices 0..5
	for slot in still_unassigned:
		var d: Dictionary = (tags_dict[slot] as Dictionary).duplicate(true)
		d["turns"] = int(d.get("turns", GOAL_SLOT - slot))
		d["slot"] = slot
		for i in range(CYCLE_TAG_COUNT):
			if not used_indices.has(i):
				used_indices[i] = true
				d["tag_index"] = i
				result[i] = d
				_slot_to_tag_index[slot] = i
				break

	return result


## Render a full board state instantly, no animation.
func render_state(state: Dictionary) -> void:
	_kill_all_tag_tweens()
	_state = _normalize_state(state)
	var two_p := bool(_state.get("has_player_b", false))
	if _secondary_bar_box != null:
		_secondary_bar_box.visible = two_p
	if _secondary_spacer != null:
		_secondary_spacer.visible = two_p
	var main_e := _main_energy_of(_state)
	var sec_e := _secondary_energy_of(_state)
	var ch := float(_state.get("charge", 0.0))
	_render_energy(main_e, ch, false)
	if two_p:
		_render_secondary_energy(sec_e, ch)
	_render_all_previews()
	var six_tags := _extract_six_tags(_state)
	_render_six_tags_instant(six_tags)


func set_preview_cost(cost: float, player_seat: String = "", in_deadzone: bool = false) -> void:
	_state["preview_cost"] = maxf(cost, 0.0)
	_state["preview_seat"] = player_seat
	_state["preview_in_deadzone"] = in_deadzone
	_render_all_previews()


func _render_all_previews() -> void:
	var main_e := _main_energy_of(_state)
	var sec_e := _secondary_energy_of(_state)
	var cost := float(_state.get("preview_cost", 0.0))
	var seat := str(_state.get("preview_seat", ""))
	var in_dz := bool(_state.get("preview_in_deadzone", false))
	var two_p := bool(_state.get("has_player_b", false))
	var on_secondary := false
	if two_p and not seat.is_empty():
		var main_seat := "b" if _perspective_role == "b" else "a"
		on_secondary = (seat != main_seat)
	if on_secondary:
		_render_preview_on_arrays(main_e, 0.0, false, _consume_fills, _overdrag_fills)
		_render_preview_on_arrays(sec_e, cost, in_dz, _secondary_consume_fills, _secondary_overdrag_fills)
	else:
		_render_preview_on_arrays(main_e, cost, in_dz, _consume_fills, _overdrag_fills)
		if two_p:
			_render_preview_on_arrays(sec_e, 0.0, false, _secondary_consume_fills, _secondary_overdrag_fills)


func get_preview_cost() -> float:
	return float(_state.get("preview_cost", 0.0))


func animate_energy_reduction(new_energy: float, charge: float = -1.0) -> void:
	var next := _state.duplicate(true)
	var clamped := clampf(new_energy, 0.0, float(SLOT_COUNT))
	next["energy"] = clamped
	if bool(next.get("has_player_b", false)) and _perspective_role == "b":
		next["energy_b"] = clamped
	else:
		next["energy_a"] = clamped
	next["preview_cost"] = 0.0
	if charge >= 0.0:
		next["charge"] = clampf(charge, 0.0, 1.0)
	apply_state(next)


## Apply a new state, animating each of the 6 persistent tags independently.
func apply_state(state: Dictionary) -> void:
	var old: Dictionary = _normalize_state(_state)
	var next: Dictionary = _normalize_state(state)
	var kind := ""
	var two_p := bool(next.get("has_player_b", false))
	if _secondary_bar_box != null:
		_secondary_bar_box.visible = two_p
	if _secondary_spacer != null:
		_secondary_spacer.visible = two_p

	var old_main_e := _main_energy_of(old)
	var new_main_e := _main_energy_of(next)
	var old_sec_e := _secondary_energy_of(old)
	var new_sec_e := _secondary_energy_of(next)

	var prev_six := _cycle_tag_state.duplicate(true)
	var next_six := _extract_six_tags(next)

	var any_glide := false
	var any_fade_teleport := false
	for i in range(CYCLE_TAG_COUNT):
		var old_t: Dictionary = prev_six[i]
		var new_t: Dictionary = next_six[i]
		if old_t.is_empty() or new_t.is_empty():
			continue
		var old_slot := int(old_t.get("slot", -99))
		var new_slot := int(new_t.get("slot", -99))
		if new_slot == old_slot + 1:
			if old_slot == 9 and new_slot == 10 and not old_t.has("cycle_step"):
				any_fade_teleport = true
			else:
				any_glide = true

	var main_rewound := new_main_e < old_main_e - 0.001
	var sec_rewound := two_p and (new_sec_e < old_sec_e - 0.001)
	var is_rewinding := (_rewind_tween != null and _rewind_tween.is_running()) or (_secondary_rewind_tween != null and _secondary_rewind_tween.is_running())
	if main_rewound or sec_rewound or is_rewinding:
		kind = "rewind"
	elif int(floorf(new_main_e + 0.001)) > int(floorf(old_main_e + 0.001)):
		for slot in range(int(floorf(old_main_e + 0.001)), int(floorf(new_main_e + 0.001))):
			_play_charge_pop(slot)
	if any_fade_teleport:
		kind = "fade_teleport"
	elif any_glide:
		kind = "glide"
	last_animation_kind = kind
	_state = next
	var ch := float(_state.get("charge", 0.0))
	if main_rewound:
		_play_rewind_sequential(old_main_e, new_main_e, ch)
	else:
		_render_energy(new_main_e, ch, true)
	if two_p:
		if sec_rewound:
			_play_secondary_rewind_sequential(old_sec_e, new_sec_e, ch)
		else:
			_render_secondary_energy(new_sec_e, ch)
	_render_all_previews()
	_animate_six_tags(prev_six, next_six)


# ----- observable renderable output (test seam) -----

func slot_bar(slot: int) -> String:
	return "upper" if slot >= BAR_SIZE else "lower"


func slot_column(slot: int) -> int:
	return GOAL_SLOT - slot if slot >= BAR_SIZE else slot


func slot_fill_ratio(slot: int) -> float:
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_energy_ratios.size():
		if _target_energy_ratios[slot] > 0.0001:
			return _target_energy_ratios[slot]
		return _target_charging_ratios[slot]
	var owned_ratio := _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if owned_ratio > 0.0001:
		return owned_ratio
	return slot_charging_ratio(slot)


func slot_charging_ratio(slot: int) -> float:
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_charging_ratios.size():
		return _target_charging_ratios[slot]
	return _charging_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


func slot_fill_kind(slot: int) -> String:
	var owned_ratio := _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_energy_ratios.size():
		owned_ratio = _target_energy_ratios[slot]
	if owned_ratio > 0.0001:
		return "energy"
	if slot_charging_ratio(slot) > 0.0001:
		return "charging"
	return "empty"


func slot_consume_ratio(slot: int) -> float:
	return _consume_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


func slot_overdrag_ratio(slot: int) -> float:
	return _overdrag_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


func secondary_slot_fill_ratio(slot: int) -> float:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running() and slot >= 0 and slot < _secondary_target_energy_ratios.size():
		if _secondary_target_energy_ratios[slot] > 0.0001:
			return _secondary_target_energy_ratios[slot]
		return _secondary_target_charging_ratios[slot]
	var owned_ratio := _secondary_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if owned_ratio > 0.0001:
		return owned_ratio
	return secondary_slot_charging_ratio(slot)


func secondary_slot_charging_ratio(slot: int) -> float:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running() and slot >= 0 and slot < _secondary_target_charging_ratios.size():
		return _secondary_target_charging_ratios[slot]
	return _secondary_charging_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


func is_tag_gliding_at_slot(slot: int) -> bool:
	if not _slot_to_tag_index.has(slot):
		return false
	var idx: int = int(_slot_to_tag_index[slot])
	if idx < 0 or idx >= _cycle_tag_tweens.size():
		return false
	return _cycle_tag_tweens[idx] != null and _cycle_tag_tweens[idx].is_running()


func tag_info(slot: int) -> Dictionary:
	var tags: Dictionary = _state.get("tags", {})
	if not tags.has(slot):
		return {}
	var tag: Dictionary = tags[slot]
	var idx: int = int(_slot_to_tag_index.get(slot, tag.get("tag_index", 0)))
	var step := _resolve_cycle_step(slot, tag)
	var is_12 := (step == 12) or bool(tag.get("is_cycle_12", false))
	var t_rem := int(tag.get("turns", GOAL_SLOT - slot))
	var on_upper := (t_rem >= 0 and t_rem <= MAX_VISIBLE_TURNS)
	var pin := _cycle_tag_pins[clampi(idx, 0, CYCLE_TAG_COUNT - 1)]
	var mover := _cycle_tag_nodes[clampi(idx, 0, CYCLE_TAG_COUNT - 1)]
	var highlight_kind := _resolve_highlight_kind(step, is_12)
	return {
		"tag_index": idx,
		"side": "above" if slot >= GOAL_SLOT - 12 else "below",
		"count": int(tag.get("count", 0)),
		"turns": t_rem,
		"arrow": "down" if slot >= GOAL_SLOT - 12 else "up",
		"visible_on_board": on_upper and mover.modulate.a > 0.01,
		"count_circle_visible": pin.show_circle,
		"turns_label_visible": false,
		"cycle_step": step,
		"is_cycle_12": is_12,
		"is_cycle_12_highlighted": is_12,
		"highlight_kind": highlight_kind,
		"fill_color": pin.fill_color,
		"scale_mult": pin.scale_mult,
		"is_lifted_at_goal": (slot == GOAL_SLOT and mover.position.y < -1.0),
		"mover_y": mover.position.y,
	}


# ----- rendering -----

func _render_energy(energy: float, charge: float, _animate: bool) -> void:
	if _rewind_tween != null and _rewind_tween.is_running():
		var clamped_target := clampf(energy, 0.0, float(SLOT_COUNT))
		var cur_target := 0.0
		for ratio in _target_energy_ratios:
			cur_target += ratio
		if is_equal_approx(clamped_target, cur_target):
			return
		_rewind_tween.kill()
		_rewind_tween = null
	var clamped_energy := clampf(energy, 0.0, float(SLOT_COUNT))
	var clamped_charge := clampf(charge, 0.0, 1.0)
	var charge_end := clampf(clamped_energy + clamped_charge, 0.0, float(SLOT_COUNT))
	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var fill := _fills[slot]
		var energy_in_slot := clampf(clamped_energy - slot_f, 0.0, 1.0)
		_target_energy_ratios[slot] = energy_in_slot
		_set_fill(fill, slot, energy_in_slot, energy_color, false)

		var ch_start := clampf(clamped_energy - slot_f, 0.0, 1.0)
		var ch_end := clampf(charge_end - slot_f, 0.0, 1.0)
		var ch_ratio := maxf(0.0, ch_end - ch_start)
		_target_charging_ratios[slot] = ch_ratio
		_apply_segment(_charging_fills[slot], charging_color, ch_start, maxf(ch_start, ch_end))


func _render_secondary_energy(energy: float, charge: float) -> void:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running():
		var clamped_target := clampf(energy, 0.0, float(SLOT_COUNT))
		var cur_target := 0.0
		for ratio in _secondary_target_energy_ratios:
			cur_target += ratio
		if is_equal_approx(clamped_target, cur_target):
			return
		_secondary_rewind_tween.kill()
		_secondary_rewind_tween = null
	var clamped_energy := clampf(energy, 0.0, float(SLOT_COUNT))
	var clamped_charge := clampf(charge, 0.0, 1.0)
	var charge_end := clampf(clamped_energy + clamped_charge, 0.0, float(SLOT_COUNT))
	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var fill := _secondary_fills[slot]
		if fill == null:
			continue
		var energy_in_slot := clampf(clamped_energy - slot_f, 0.0, 1.0)
		_secondary_target_energy_ratios[slot] = energy_in_slot
		fill.color = energy_color
		_apply_fill_width(fill, slot_size.x * energy_in_slot)

		var ch_start := clampf(clamped_energy - slot_f, 0.0, 1.0)
		var ch_end := clampf(charge_end - slot_f, 0.0, 1.0)
		var ch_ratio := maxf(0.0, ch_end - ch_start)
		_secondary_target_charging_ratios[slot] = ch_ratio
		_apply_segment(_secondary_charging_fills[slot], charging_color, ch_start, maxf(ch_start, ch_end))


func _render_preview_on_arrays(energy: float, preview_cost: float, in_deadzone: bool, consume_arr: Array[ColorRect], overdrag_arr: Array[ColorRect]) -> void:
	var clamped_energy := clampf(energy, 0.0, float(SLOT_COUNT))
	var clamped_cost := clampf(preview_cost, 0.0, float(SLOT_COUNT))
	if in_deadzone and clamped_cost <= 0.0001:
		for slot in range(SLOT_COUNT):
			if consume_arr[slot] != null:
				_apply_segment(consume_arr[slot], consume_preview_color, 0.0, 0.0)
			if overdrag_arr[slot] != null:
				_apply_segment(overdrag_arr[slot], overdrag_preview_color, 0.0, 1.0 if slot == 0 else 0.0)
		return
	var affordable := minf(clamped_cost, clamped_energy)
	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var c_start := clampf(0.0 - slot_f, 0.0, 1.0)
		var c_end := clampf(affordable - slot_f, 0.0, 1.0)
		if consume_arr[slot] != null:
			_apply_segment(consume_arr[slot], consume_preview_color, c_start, maxf(c_start, c_end))

		if overdrag_arr[slot] != null:
			if clamped_cost > clamped_energy + 0.0001:
				var o_start := clampf(clamped_energy - slot_f, 0.0, 1.0)
				var o_end := clampf(clamped_cost - slot_f, 0.0, 1.0)
				_apply_segment(overdrag_arr[slot], overdrag_preview_color, o_start, maxf(o_start, o_end))
			else:
				_apply_segment(overdrag_arr[slot], overdrag_preview_color, 0.0, 0.0)


func _apply_segment(rect: ColorRect, color: Color, start_ratio: float, end_ratio: float) -> void:
	rect.color = color
	var s := clampf(start_ratio, 0.0, 1.0)
	var e := clampf(end_ratio, s, 1.0)
	if rect.anchor_right == 0.0:
		rect.offset_left = slot_size.x * s
		rect.offset_right = slot_size.x * e
	else:
		rect.offset_right = -slot_size.x * s
		rect.offset_left = -slot_size.x * e


func _set_fill(fill: ColorRect, slot: int, ratio: float, color: Color, animate: bool) -> void:
	fill.color = color
	var width := slot_size.x * ratio
	if _fill_tweens.has(slot) and _fill_tweens[slot].is_running():
		_fill_tweens[slot].kill()
	if not animate:
		_apply_fill_width(fill, width)
		return
	var tween := create_tween()
	_fill_tweens[slot] = tween
	if fill.anchor_right == 0.0:
		tween.tween_property(fill, "offset_right", width, charge_tween_duration)
	else:
		tween.tween_property(fill, "offset_left", -width, charge_tween_duration)


func _apply_fill_width(fill: ColorRect, width: float) -> void:
	if fill.anchor_right == 0.0:
		fill.offset_right = width
	else:
		fill.offset_left = -width


func _kill_tag_tween(idx: int) -> void:
	if idx < 0 or idx >= _cycle_tag_tweens.size():
		return
	if _cycle_tag_tweens[idx] != null and _cycle_tag_tweens[idx].is_running():
		_cycle_tag_tweens[idx].kill()
	_cycle_tag_tweens[idx] = null


func _kill_all_tag_tweens() -> void:
	for i in range(_cycle_tag_tweens.size()):
		_kill_tag_tween(i)


func _render_six_tags_instant(six_tags: Array[Dictionary]) -> void:
	for i in range(CYCLE_TAG_COUNT):
		var mover := _cycle_tag_nodes[i]
		var d: Dictionary = six_tags[i] if i < six_tags.size() else {}
		_cycle_tag_state[i] = d.duplicate(true)
		if d.is_empty():
			mover.modulate.a = 0.0
			continue
		var t_rem := int(d.get("turns", 12))
		var at_goal := (t_rem == 0)
		_set_single_tag_visual(i, d, at_goal)
		mover.position.x = _x_for_turns(t_rem)
		mover.position.y = GOAL_LIFT_Y if at_goal else 0.0
		mover.modulate.a = 1.0 if (t_rem >= 0 and t_rem <= MAX_VISIBLE_TURNS) else 0.0


func _animate_six_tags(prev_six: Array[Dictionary], next_six: Array[Dictionary]) -> void:
	for i in range(CYCLE_TAG_COUNT):
		var mover := _cycle_tag_nodes[i]
		var old_d: Dictionary = prev_six[i] if i < prev_six.size() else {}
		var new_d: Dictionary = next_six[i] if i < next_six.size() else {}
		_cycle_tag_state[i] = new_d.duplicate(true)

		if new_d.is_empty():
			_kill_tag_tween(i)
			mover.modulate.a = 0.0
			continue

		var new_turns := int(new_d.get("turns", 12))
		var old_turns := int(old_d.get("turns", -99)) if not old_d.is_empty() else -99

		# If this tag's turns did NOT change on this frame (e.g. per-frame charge update),
		# only refresh its count/visuals without touching its position or running tween!
		if new_turns == old_turns:
			var running := _cycle_tag_tweens[i] != null and _cycle_tag_tweens[i].is_running()
			var at_goal_now := (new_turns == 0) and not running
			_set_single_tag_visual(i, new_d, at_goal_now)
			continue

		_kill_tag_tween(i)

		# 1. Tag is off-bar (> 11 turns, e.g. turns == 12 right after disappearing from the goal):
		if new_turns > MAX_VISIBLE_TURNS or new_turns < 0:
			_set_single_tag_visual(i, new_d, false)
			mover.position = Vector2(_x_for_turns(new_turns), 0.0)
			mover.modulate.a = 0.0
			continue

		# 2. Replacement tag gliding in to slot 11 (`12 → 11`):
		if new_turns == MAX_VISIBLE_TURNS and (old_turns == MAX_VISIBLE_TURNS + 1 or old_turns <= 0):
			_set_single_tag_visual(i, new_d, false)
			mover.position = Vector2(_x_for_turns(MAX_VISIBLE_TURNS + 1), 0.0)
			mover.modulate.a = 0.0
			var tw := create_tween()
			_cycle_tag_tweens[i] = tw
			tw.tween_property(mover, "position:x", _x_for_turns(MAX_VISIBLE_TURNS), turn_duration * 0.9)
			tw.parallel().tween_property(mover, "modulate:a", 1.0, turn_duration * 0.45)
			continue

		# 3. Tag gliding into the Goal (`1 → 0`):
		#    Must glide horizontally at y = 0 FIRST, and lift up to GOAL_LIFT_Y ONLY AFTER it stops at the goal!
		if new_turns == 0 and old_turns == 1:
			_set_single_tag_visual(i, new_d, false)
			mover.position = Vector2(_x_for_turns(1), 0.0)
			mover.modulate.a = 1.0
			var tw := create_tween()
			_cycle_tag_tweens[i] = tw
			tw.tween_property(mover, "position:x", _x_for_turns(0), turn_duration * 0.82)
			tw.tween_callback(func() -> void:
				_set_single_tag_visual(i, new_d, true)
			)
			tw.tween_property(mover, "position:y", GOAL_LIFT_Y, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			continue

		# 4. Normal one-slot glide along the upper bar (`old_turns → new_turns` where `old_turns == new_turns + 1`):
		if old_turns == new_turns + 1:
			_set_single_tag_visual(i, new_d, false)
			mover.position = Vector2(_x_for_turns(old_turns), 0.0)
			mover.modulate.a = 1.0
			var tw := create_tween()
			_cycle_tag_tweens[i] = tw
			tw.tween_property(mover, "position:x", _x_for_turns(new_turns), turn_duration * 0.9)
			continue

		# 5. Direct placement fallback
		var at_goal := (new_turns == 0)
		_set_single_tag_visual(i, new_d, at_goal)
		mover.position = Vector2(_x_for_turns(new_turns), GOAL_LIFT_Y if at_goal else 0.0)
		mover.modulate.a = 1.0


func _resolve_cycle_step(slot: int, tag: Dictionary) -> int:
	if tag.has("cycle_step") and int(tag["cycle_step"]) > 0:
		return int(tag["cycle_step"])
	if bool(tag.get("is_cycle_12", false)):
		return 12
	var dist := int(tag.get("turns", GOAL_SLOT - slot))
	if dist == 12:
		return 12
	return 0


func _resolve_highlight_kind(step: int, is_12: bool) -> String:
	if is_12 or step == 12:
		return "light_purple"
	if step == 6:
		return "light_red"
	if step == 4 or step == 8:
		return "light_blue"
	return "default"


func _resolve_tag_color(step: int, is_12: bool) -> Color:
	if is_12 or step == 12:
		return tag_cycle_12_light_purple
	if step == 6:
		return tag_cycle_6_light_red
	if step == 4 or step == 8:
		return tag_cycle_4_8_light_blue
	return tag_default_color


func _set_single_tag_visual(idx: int, tag: Dictionary, is_stopped_at_goal: bool) -> void:
	var slot := int(tag.get("slot", GOAL_SLOT - int(tag.get("turns", 0))))
	var cnt := int(tag.get("count", 0))
	var step := _resolve_cycle_step(slot, tag)
	var is_12 := (step == 12) or bool(tag.get("is_cycle_12", false))
	var scale_m := 1.20 if is_12 else 1.0
	var show_circle := (cnt > 0)

	var pin := _cycle_tag_pins[idx]
	pin.fill_color = _resolve_tag_color(step, is_12)
	pin.show_circle = show_circle
	pin.scale_mult = scale_m
	pin.is_at_goal = is_stopped_at_goal
	pin.queue_redraw()

	var count_lbl := _cycle_tag_counts[idx]
	count_lbl.visible = show_circle
	count_lbl.text = str(cnt) if show_circle else ""
	var font_sz := 18 if is_12 else 15
	count_lbl.add_theme_font_size_override("font_size", font_sz)
	var hc := 19.5 * scale_m
	count_lbl.position = Vector2(-18.0, 41.0 - hc - 14.0)


func _play_rewind_sequential(old_energy: float, new_energy: float, charge: float) -> void:
	if _rewind_tween != null and _rewind_tween.is_running():
		_rewind_tween.kill()
		_rewind_tween = null
	for slot in _fill_tweens.keys():
		if _fill_tweens[slot].is_running():
			_fill_tweens[slot].kill()
	_fill_tweens.clear()

	var clamped_old := clampf(old_energy, 0.0, float(SLOT_COUNT))
	var clamped_new := clampf(new_energy, 0.0, float(SLOT_COUNT))
	var clamped_charge := clampf(charge, 0.0, 1.0)
	var charge_end := clampf(clamped_new + clamped_charge, 0.0, float(SLOT_COUNT))

	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var fill := _fills[slot]
		var old_ratio := clampf(clamped_old - slot_f, 0.0, 1.0)
		var new_ratio := clampf(clamped_new - slot_f, 0.0, 1.0)
		_target_energy_ratios[slot] = new_ratio
		var ch_start := clampf(clamped_new - slot_f, 0.0, 1.0)
		var ch_end := clampf(charge_end - slot_f, 0.0, 1.0)
		_target_charging_ratios[slot] = maxf(0.0, ch_end - ch_start)
		_apply_segment(_charging_fills[slot], charging_color, 0.0, 0.0)

		fill.color = energy_color
		if old_ratio > new_ratio + 0.0001:
			_apply_fill_width(fill, slot_size.x * old_ratio)
		else:
			_apply_fill_width(fill, slot_size.x * new_ratio)

	var top_slot := mini(SLOT_COUNT - 1, int(ceilf(clamped_old - 0.0001)) - 1)
	var bottom_slot := maxi(0, int(floorf(clamped_new + 0.0001)))
	if top_slot < bottom_slot:
		return

	_rewind_tween = create_tween()
	var cur := snappedf(clamped_old, 0.5)
	var target := snappedf(clamped_new, 0.5)
	while cur > target + 0.001:
		var next_val := maxf(target, snappedf(cur - 0.5, 0.5))
		var slot := clampi(int(floorf(cur - 0.0001)), 0, SLOT_COUNT - 1)
		var slot_target_ratio := clampf(next_val - float(slot), 0.0, 1.0)
		var fill := _fills[slot]
		var target_w := slot_size.x * slot_target_ratio
		var dur := rewind_slot_duration * (cur - next_val)
		if fill.anchor_right == 0.0:
			_rewind_tween.tween_property(fill, "offset_right", target_w, maxf(dur, 0.02))
		else:
			_rewind_tween.tween_property(fill, "offset_left", -target_w, maxf(dur, 0.02))
		cur = next_val
	_rewind_tween.tween_callback(func() -> void:
		_rewind_tween = null
		_render_energy(_main_energy_of(_state), float(_state.get("charge", 0.0)), false)
	)


func _play_secondary_rewind_sequential(old_energy: float, new_energy: float, charge: float) -> void:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running():
		_secondary_rewind_tween.kill()
		_secondary_rewind_tween = null
	var clamped_old := clampf(old_energy, 0.0, float(SLOT_COUNT))
	var clamped_new := clampf(new_energy, 0.0, float(SLOT_COUNT))
	var clamped_charge := clampf(charge, 0.0, 1.0)
	var charge_end := clampf(clamped_new + clamped_charge, 0.0, float(SLOT_COUNT))

	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var fill := _secondary_fills[slot]
		if fill == null:
			continue
		var old_ratio := clampf(clamped_old - slot_f, 0.0, 1.0)
		var new_ratio := clampf(clamped_new - slot_f, 0.0, 1.0)
		_secondary_target_energy_ratios[slot] = new_ratio
		var ch_start := clampf(clamped_new - slot_f, 0.0, 1.0)
		var ch_end := clampf(charge_end - slot_f, 0.0, 1.0)
		_secondary_target_charging_ratios[slot] = maxf(0.0, ch_end - ch_start)
		_apply_segment(_secondary_charging_fills[slot], charging_color, 0.0, 0.0)
		fill.color = energy_color
		if old_ratio > new_ratio + 0.0001:
			_apply_fill_width(fill, slot_size.x * old_ratio)
		else:
			_apply_fill_width(fill, slot_size.x * new_ratio)

	var top_slot := mini(SLOT_COUNT - 1, int(ceilf(clamped_old - 0.0001)) - 1)
	var bottom_slot := maxi(0, int(floorf(clamped_new + 0.0001)))
	if top_slot < bottom_slot:
		return

	_secondary_rewind_tween = create_tween()
	var cur := snappedf(clamped_old, 0.5)
	var target := snappedf(clamped_new, 0.5)
	while cur > target + 0.001:
		var next_val := maxf(target, snappedf(cur - 0.5, 0.5))
		var slot := clampi(int(floorf(cur - 0.0001)), 0, SLOT_COUNT - 1)
		var slot_target_ratio := clampf(next_val - float(slot), 0.0, 1.0)
		var fill := _secondary_fills[slot]
		var target_w := slot_size.x * slot_target_ratio
		var dur := rewind_slot_duration * (cur - next_val)
		if fill.anchor_right == 0.0:
			_secondary_rewind_tween.tween_property(fill, "offset_right", target_w, maxf(dur, 0.02))
		else:
			_secondary_rewind_tween.tween_property(fill, "offset_left", -target_w, maxf(dur, 0.02))
		cur = next_val
	_secondary_rewind_tween.tween_callback(func() -> void:
		_secondary_rewind_tween = null
		_render_secondary_energy(_secondary_energy_of(_state), float(_state.get("charge", 0.0)))
	)


func _play_charge_pop(slot: int) -> void:
	var fill := _fills[slot]
	var tween := create_tween()
	tween.tween_property(fill, "modulate", Color(1.7, 1.7, 1.7), 0.08)
	tween.tween_property(fill, "modulate", Color.WHITE, 0.18)
