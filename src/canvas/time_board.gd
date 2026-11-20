class_name TimeBoard
extends Control

## The Time Board view: a dumb renderer for board state fed to it.
## Two serpentine 10-slot bars — slot 0 lower-left, slot 9 lower-right,
## slot 10 upper-right, slot 19 (the goal) upper-left. The Energy fill grows
## from slot 0 along the path; the charging slot fills smoothly over the
## Turn. Tags are pennant arrows above the upper bar / below the lower bar,
## resting ON slot edges (the leading edge in the path direction) with the
## unit count printed on the arrow and the Turns-to-goal integer outside it.
## The integers count down exactly when a gliding arrow lands on the next
## edge — never while it sits mid-box.
##
## All motion lives here and only here: smooth charging, a pop when a slot
## completes, the one-slot tag glide, the 9→10 fade-teleport wrap, and the
## spend-Energy rewind. No board rules — the view renders and animates
## whatever state it is fed.
##
## `demo_mode` is ticket-01 scaffolding (crafted placeholder states so the
## look and feel can be tuned before the model exists); ticket 02 removes it.

## Crafted/model state shape:
## {"energy": int 0..20, "charge": float 0..1, "tags": {slot: {"count", "turns"}}}

const SLOT_COUNT := 20
const BAR_SIZE := 10
const GOAL_SLOT := 19

@export var slot_size := Vector2(44, 15)
@export var secondary_slot_size := Vector2(44, 6)
@export var slot_gap := 3.0
## Turn duration — the single configurable time knob (default 1s). Tag
## glides run this long so indicators slide continuously.
@export var turn_duration := 1.0
## How long the charging fill takes to tween to a newly reported fraction
## (kept under the demo tick so motion reads as continuous).
@export var charge_tween_duration := 0.15
## Duration per slot when rewinding spent Energy sequentially from highest slot to lowest.
@export var rewind_slot_duration := 0.08
@export var slot_color := Color(0.1, 0.09, 0.09, 0.85)
@export var goal_color := Color(0.55, 0.16, 0.14, 0.9)
@export var energy_color := Color(0.95, 0.72, 0.18, 1.0)
@export var charging_color := Color(0.95, 0.72, 0.18, 0.4)
@export var consume_preview_color := Color(0.26, 0.82, 0.96, 0.95)
@export var overdrag_preview_color := Color(0.92, 0.18, 0.16, 0.95)
@export var turns_color := Color(0.92, 0.86, 0.68, 1.0)
@export var count_color := Color(0.22, 0.1, 0.06, 1.0)
@export var arrow_down_texture: Texture2D = preload("res://src/resource/battlefield/arrow_down.png")
@export var arrow_up_texture: Texture2D = preload("res://src/resource/battlefield/arrow_up.png")
## Ticket-01 scaffolding: cycle a crafted state to preview the animations.
@export var demo_mode := false

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
var _tag_movers: Array[Control] = []
var _tag_turns: Array[Label] = []
var _tag_counts: Array[Label] = []
var _tag_arrows: Array[TextureRect] = []
var _fill_tweens: Dictionary = {}
var _rewind_tween: Tween = null
var _secondary_rewind_tween: Tween = null
var _target_energy_ratios: Array[float] = []
var _target_charging_ratios: Array[float] = []
var _secondary_target_energy_ratios: Array[float] = []
var _secondary_target_charging_ratios: Array[float] = []
var _perspective_role: String = "a"

## The animation kind the last apply_state() requested — "glide",
## "fade_teleport", "rewind", or "" for none. The observable animation seam
## for tests (tween parameters are never asserted).
var last_animation_kind := ""

var _state: Dictionary = {"energy": 0.0, "charge": 0.0, "preview_cost": 0.0, "tags": {}}
var _demo_timer: Timer = null
var _demo_state: Dictionary = {}
var _demo_tick := 0


func _ready() -> void:
	_build_board()
	render_state(_state)
	if demo_mode:
		_start_demo()


# ----- construction (all generated: tuning happens via the exports) -----

func _build_board() -> void:
	for row in [_lower_bar, _upper_bar, _lower_tags, _upper_tags, _secondary_lower_bar, _secondary_upper_bar]:
		if row != null:
			row.add_theme_constant_override("separation", int(slot_gap))
	_fills.resize(SLOT_COUNT)
	_charging_fills.resize(SLOT_COUNT)
	_consume_fills.resize(SLOT_COUNT)
	_overdrag_fills.resize(SLOT_COUNT)
	_secondary_fills.resize(SLOT_COUNT)
	_secondary_charging_fills.resize(SLOT_COUNT)
	_target_energy_ratios.resize(SLOT_COUNT)
	_target_energy_ratios.fill(0.0)
	_target_charging_ratios.resize(SLOT_COUNT)
	_target_charging_ratios.fill(0.0)
	_secondary_target_energy_ratios.resize(SLOT_COUNT)
	_secondary_target_energy_ratios.fill(0.0)
	_secondary_target_charging_ratios.resize(SLOT_COUNT)
	_secondary_target_charging_ratios.fill(0.0)
	_tag_movers.resize(SLOT_COUNT)
	_tag_turns.resize(SLOT_COUNT)
	_tag_counts.resize(SLOT_COUNT)
	_tag_arrows.resize(SLOT_COUNT)
	# Lower bar: slots 0..9 left→right. Upper bar: slots 19..10 left→right.
	for slot in range(BAR_SIZE):
		_lower_bar.add_child(_make_slot_cell(slot, false))
		_lower_tags.add_child(_make_tag_cell(slot, false))
		if _secondary_lower_bar != null:
			_secondary_lower_bar.add_child(_make_secondary_slot_cell(slot, false))
	for column in range(BAR_SIZE):
		var slot := GOAL_SLOT - column
		_upper_bar.add_child(_make_slot_cell(slot, true))
		_upper_tags.add_child(_make_tag_cell(slot, true))
		if _secondary_upper_bar != null:
			_secondary_upper_bar.add_child(_make_secondary_slot_cell(slot, true))


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


## A tag cell holds one slot's tag. The mover (arrow + integers) rests with
## the arrow centered on the slot's LEADING edge — the boundary in the path
## direction — so tags sit on box edges, never mid-box.
func _make_tag_cell(slot: int, upper: bool) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(slot_size.x, 22.0)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mover := Control.new()
	mover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.modulate.a = 0.0
	mover.position.x = _edge_offset(upper)
	cell.add_child(mover)
	var turns := Label.new()
	turns.modulate = turns_color
	turns.add_theme_font_size_override("font_size", 11)
	turns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turns.size = Vector2(slot_size.x, 11)
	turns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.add_child(turns)
	# The count sits on the arrow itself, in a contrasting color.
	var arrow_frame := Control.new()
	arrow_frame.size = Vector2(slot_size.x, 12.0)
	arrow_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := TextureRect.new()
	arrow.texture = arrow_down_texture if upper else arrow_up_texture
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_frame.add_child(arrow)
	var count := Label.new()
	count.modulate = count_color
	count.add_theme_font_size_override("font_size", 10)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_frame.add_child(count)
	mover.add_child(arrow_frame)
	# Arrow nearest the bar, Turns integer outermost, with a gap so the
	# arrow never overlaps the text line.
	if upper:
		turns.position = Vector2.ZERO
		arrow_frame.position = Vector2(0, 10)
	else:
		arrow_frame.position = Vector2.ZERO
		turns.position = Vector2(0, 11)
	_tag_movers[slot] = mover
	_tag_arrows[slot] = arrow
	_tag_counts[slot] = count
	_tag_turns[slot] = turns
	return cell


## The mover's resting x inside its cell: the slot's leading edge (right on
## the lower bar, left on the upper bar — the path direction).
func _edge_offset(upper: bool) -> float:
	var direction := -1.0 if upper else 1.0
	return direction * (slot_size.x / 2.0 + slot_gap / 2.0)


# ----- public view API (the model→view seam) -----

## Sets the local viewer's seat role ("a", "b", or "spectator") so that in
## 2-player mode a seated player always sees their own Energy on the main
## bottom bar and the opponent's Energy on the secondary top bar (while
## Spectators see Player A on the main bar and Player B on the secondary bar).
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


## Render a full board state instantly, no animation.
func render_state(state: Dictionary) -> void:
	_state = _normalize_state(state)
	var two_p := bool(_state.get("has_player_b", false))
	if _secondary_bar_box != null:
		_secondary_bar_box.visible = two_p
	var main_e := _main_energy_of(_state)
	var sec_e := _secondary_energy_of(_state)
	var ch := float(_state.get("charge", 0.0))
	_render_energy(main_e, ch, false)
	if two_p:
		_render_secondary_energy(sec_e, ch)
	_render_preview(main_e, float(_state.get("preview_cost", 0.0)))
	_render_tags(_state.get("tags", {}))


## Update only the aiming preview_cost on top of the current state.
func set_preview_cost(cost: float) -> void:
	_state["preview_cost"] = maxf(cost, 0.0)
	_render_preview(_main_energy_of(_state), float(_state.get("preview_cost", 0.0)))


func get_preview_cost() -> float:
	return float(_state.get("preview_cost", 0.0))


## Reusable entry point for any Energy reduction (Cue-Shot spend, card cost,
## enemy drain, or Prepare-Time reset): updates board Energy to `new_energy`
## and runs the slot-by-slot sequential rewind animation from highest slot
## to lowest.
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



## Apply a new state, animating the transition: the charging fill tweens
## smoothly, a completing slot pops, spend-Energy rewinds, tag moves glide,
## 9→10 wraps fade-teleport. Records last_animation_kind.
func apply_state(state: Dictionary) -> void:
	var old: Dictionary = _normalize_state(_state)
	var next: Dictionary = _normalize_state(state)
	var kind := ""
	var two_p := bool(next.get("has_player_b", false))
	if _secondary_bar_box != null:
		_secondary_bar_box.visible = two_p

	var old_main_e := _main_energy_of(old)
	var new_main_e := _main_energy_of(next)
	var old_sec_e := _secondary_energy_of(old)
	var new_sec_e := _secondary_energy_of(next)

	var old_tags: Dictionary = old.get("tags", {})
	var new_tags: Dictionary = next.get("tags", {})
	# Detect movement before rendering (same count one slot further along
	# the path = the same tag gliding; 9→10 wraps with a fade-teleport).
	var glides: Array = []
	var teleports: Array = []
	for slot in new_tags:
		if old_tags.has(slot):
			continue
		var prev: int = slot - 1
		if old_tags.has(prev) and old_tags[prev].get("count", -1) == new_tags[slot].get("count", -2):
			if prev == 9 and slot == 10:
				teleports.append([prev, slot])
			else:
				glides.append([prev, slot])
	var main_rewound := new_main_e < old_main_e - 0.001
	var sec_rewound := two_p and (new_sec_e < old_sec_e - 0.001)
	if main_rewound or sec_rewound:
		kind = "rewind"
	elif int(floorf(new_main_e + 0.001)) > int(floorf(old_main_e + 0.001)):
		for slot in range(int(floorf(old_main_e + 0.001)), int(floorf(new_main_e + 0.001))):
			_play_charge_pop(slot)
	if not teleports.is_empty():
		kind = "fade_teleport"
	elif not glides.is_empty():
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
	_render_preview(new_main_e, float(_state.get("preview_cost", 0.0)))
	_render_tags(new_tags)
	# Post-render fix-ups: movers in motion show their OLD numbers until the
	# arrow lands on the next edge, then count down.
	for pair in glides:
		_play_glide(pair[0], pair[1], old_tags[pair[0]], new_tags[pair[1]])
	for pair in teleports:
		_play_fade_teleport(pair[0], pair[1], old_tags[pair[0]])


# ----- observable renderable output (test seam; never tween internals) -----

func slot_bar(slot: int) -> String:
	return "upper" if slot >= BAR_SIZE else "lower"


## Left-to-right screen column of a slot within its bar (0 = leftmost).
func slot_column(slot: int) -> int:
	return GOAL_SLOT - slot if slot >= BAR_SIZE else slot


## Rendered fill ratio of a slot: 1.0 filled, 0.5 on a half-filled energy
## slot, the fractional charge on a charging-only slot, 0.0 otherwise.
func slot_fill_ratio(slot: int) -> float:
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_energy_ratios.size():
		if _target_energy_ratios[slot] > 0.0001:
			return _target_energy_ratios[slot]
		return _target_charging_ratios[slot]
	var owned_ratio := _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if owned_ratio > 0.0001:
		return owned_ratio
	return slot_charging_ratio(slot)


## Rendered charging-progress ratio on a slot (0.0..1.0).
func slot_charging_ratio(slot: int) -> float:
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_charging_ratios.size():
		return _target_charging_ratios[slot]
	return _charging_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Rendered fill kind of a slot's base fill ("energy", "charging", or "empty").
func slot_fill_kind(slot: int) -> String:
	var owned_ratio := _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if _rewind_tween != null and _rewind_tween.is_running() and slot >= 0 and slot < _target_energy_ratios.size():
		owned_ratio = _target_energy_ratios[slot]
	if owned_ratio > 0.0001:
		return "energy"
	if slot_charging_ratio(slot) > 0.0001:
		return "charging"
	return "empty"


## Rendered consume-preview ratio on a slot (0.0..1.0).
func slot_consume_ratio(slot: int) -> float:
	return _consume_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Rendered red over-drag ratio on a slot (0.0..1.0).
func slot_overdrag_ratio(slot: int) -> float:
	return _overdrag_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Rendered fill ratio of a slot on the secondary (2-player top) bar:
## 1.0 filled, 0.5 on a half-filled energy slot, the fractional charge on a
## charging-only slot, 0.0 otherwise.
func secondary_slot_fill_ratio(slot: int) -> float:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running() and slot >= 0 and slot < _secondary_target_energy_ratios.size():
		if _secondary_target_energy_ratios[slot] > 0.0001:
			return _secondary_target_energy_ratios[slot]
		return _secondary_target_charging_ratios[slot]
	var owned_ratio := _secondary_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0
	if owned_ratio > 0.0001:
		return owned_ratio
	return secondary_slot_charging_ratio(slot)


## Rendered charging-progress ratio on a slot of the secondary bar (0.0..1.0).
func secondary_slot_charging_ratio(slot: int) -> float:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running() and slot >= 0 and slot < _secondary_target_charging_ratios.size():
		return _secondary_target_charging_ratios[slot]
	return _secondary_charging_fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Tag render info for a slot: {"side", "count", "turns", "arrow"} from the
## committed state, or empty when no tag is rendered there. (Transient
## in-flight label text is motion, not renderable output.)
func tag_info(slot: int) -> Dictionary:
	var tags: Dictionary = _state.get("tags", {})
	if not tags.has(slot):
		return {}
	return {
		"side": "above" if slot >= BAR_SIZE else "below",
		"count": tags[slot].get("count", 0),
		"turns": tags[slot].get("turns", 0),
		"arrow": "down" if _tag_arrows[slot].texture == arrow_down_texture else "up",
	}


# ----- rendering -----

func _render_energy(energy: float, charge: float, animate: bool) -> void:
	if _rewind_tween != null and _rewind_tween.is_running():
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
		# Set owned Energy width immediately (charge progress already advanced smoothly
		# over the Turn, and _play_charge_pop handles the completion flash — tweening
		# _fills[slot] from 0 -> 1 over 0.15s after _charging_fills cleared caused a
		# visible empty blink when a slot completed).
		_set_fill(fill, slot, energy_in_slot, energy_color, false)

		# Charging progress starts right where owned Energy ends (e.g. at 0.5 on a half-filled slot)
		# and continues seamlessly without leaving any empty half-slot gap.
		var ch_start := clampf(clamped_energy - slot_f, 0.0, 1.0)
		var ch_end := clampf(charge_end - slot_f, 0.0, 1.0)
		var ch_ratio := maxf(0.0, ch_end - ch_start)
		_target_charging_ratios[slot] = ch_ratio
		_apply_segment(_charging_fills[slot], charging_color, ch_start, maxf(ch_start, ch_end))


func _render_secondary_energy(energy: float, charge: float) -> void:
	if _secondary_rewind_tween != null and _secondary_rewind_tween.is_running():
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


func _render_preview(energy: float, preview_cost: float) -> void:
	var clamped_energy := clampf(energy, 0.0, float(SLOT_COUNT))
	var clamped_cost := clampf(preview_cost, 0.0, float(SLOT_COUNT))
	var affordable := minf(clamped_cost, clamped_energy)
	for slot in range(SLOT_COUNT):
		var slot_f := float(slot)
		var c_start := clampf(0.0 - slot_f, 0.0, 1.0)
		var c_end := clampf(affordable - slot_f, 0.0, 1.0)
		_apply_segment(_consume_fills[slot], consume_preview_color, c_start, maxf(c_start, c_end))

		if clamped_cost > clamped_energy + 0.0001:
			var o_start := clampf(clamped_energy - slot_f, 0.0, 1.0)
			var o_end := clampf(clamped_cost - slot_f, 0.0, 1.0)
			_apply_segment(_overdrag_fills[slot], overdrag_preview_color, o_start, maxf(o_start, o_end))
		else:
			_apply_segment(_overdrag_fills[slot], overdrag_preview_color, 0.0, 0.0)


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
	# Lower bar fills grow rightward from the left edge; upper bar fills grow
	# leftward from the right edge (path direction).
	if fill.anchor_right == 0.0:
		fill.offset_right = width
	else:
		fill.offset_left = -width


func _render_tags(tags: Dictionary) -> void:
	for slot in range(SLOT_COUNT):
		var mover := _tag_movers[slot]
		if tags.has(slot):
			_set_tag_text(slot, tags[slot])
			mover.modulate.a = 1.0
		else:
			mover.modulate.a = 0.0


func _set_tag_text(slot: int, tag: Dictionary) -> void:
	_tag_counts[slot].text = str(tag.get("count", 0))
	_tag_turns[slot].text = str(tag.get("turns", 0))


# ----- animations (tuned visually in the editor; never asserted) -----

## Smooth one-slot glide along the leading edges: the arrow slides to the
## next edge over one Turn; the integers count down when it lands.
func _play_glide(from_slot: int, to_slot: int, old_tag: Dictionary, new_tag: Dictionary) -> void:
	var mover := _tag_movers[to_slot]
	var direction := -1.0 if to_slot >= BAR_SIZE else 1.0
	var pitch := slot_size.x + slot_gap
	var rest_x: float = mover.position.x
	mover.position.x = rest_x - direction * pitch
	_set_tag_text(to_slot, old_tag)  # keep the old numbers while in flight
	var tween := create_tween()
	tween.tween_property(mover, "position:x", rest_x, turn_duration * 0.9)
	tween.tween_callback(_set_tag_text.bind(to_slot, new_tag))


## The 9→10 wrap: fade out at the lower-right edge, fade in at the
## upper-right edge (the new numbers appear with the fade-in).
func _play_fade_teleport(from_slot: int, to_slot: int, old_tag: Dictionary) -> void:
	var old_mover := _tag_movers[from_slot]
	var new_mover := _tag_movers[to_slot]
	_set_tag_text(from_slot, old_tag)
	old_mover.modulate.a = 1.0
	new_mover.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(old_mover, "modulate:a", 0.0, 0.12)
	tween.tween_property(new_mover, "modulate:a", 1.0, 0.12)


## Spend-Energy rewind: drains slots sequentially one-by-one from the highest
## filled slot down to new_energy (from more to less).
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

	# Record target ratios and ensure all slots start at their pre-spend widths
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


## A slot finished charging: a quick bright pop on the new Energy.
func _play_charge_pop(slot: int) -> void:
	var fill := _fills[slot]
	var tween := create_tween()
	tween.tween_property(fill, "modulate", Color(1.7, 1.7, 1.7), 0.08)
	tween.tween_property(fill, "modulate", Color.WHITE, 0.18)


# ----- ticket-01 demo scaffolding (removed when the model lands) -----

func _start_demo() -> void:
	_demo_state = {
		"energy": 8,
		"charge": 0.0,
		"tags": {
			3: {"count": 2, "turns": 16},
			12: {"count": 1, "turns": 7},
			17: {"count": 4, "turns": 2},
		},
	}
	render_state(_demo_state)
	_demo_timer = Timer.new()
	_demo_timer.wait_time = 0.2
	_demo_timer.timeout.connect(_demo_step)
	add_child(_demo_timer)
	_demo_timer.start()


func _demo_step() -> void:
	_demo_tick += 1
	var next: Dictionary = _demo_state.duplicate(true)
	# Smooth charging: a slot completes every second of demo time.
	var charge: float = next.get("charge", 0.0) + 0.2
	var energy: int = next.get("energy", 0)
	if charge >= 1.0:
		charge = 0.0
		energy = mini(SLOT_COUNT, energy + 1)
	next["charge"] = charge
	next["energy"] = energy
	# Tags advance one slot per second; the goal consumes them; a fresh tag
	# appears periodically so the loop never empties. Turns count down as
	# they glide (turns = distance to goal).
	if _demo_tick % 5 == 0:
		var next_tags := {}
		for slot in next.get("tags", {}):
			if slot + 1 <= GOAL_SLOT:
				next_tags[slot + 1] = {"count": next["tags"][slot]["count"], "turns": GOAL_SLOT - slot - 1}
		next["tags"] = next_tags
	if _demo_tick % 15 == 0:
		var spawn_slot := 2 + (_demo_tick / 15 % 5)
		var tags: Dictionary = next["tags"]
		tags[spawn_slot] = {"count": 1 + _demo_tick % 3, "turns": GOAL_SLOT - spawn_slot}
	# Every so often a spend rewinds the fill.
	if _demo_tick % 40 == 39:
		next["energy"] = maxi(0, energy - 4)
		next["charge"] = 0.0
	_demo_state = next
	apply_state(_demo_state)
