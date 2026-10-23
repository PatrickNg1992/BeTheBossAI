class_name TimeBoard
extends Control

## The Time Board view: a dumb renderer for board state fed to it.
## Two serpentine 10-slot bars — slot 0 lower-left, slot 9 lower-right,
## slot 10 upper-right, slot 19 (the goal, flagged) upper-left. The Energy
## fill grows from slot 0 along the path; the charging slot fills smoothly
## over the Turn. Tags are pennant arrows above the upper bar / below the
## lower bar pointing into the bar, the unit count printed on the arrow and
## the Turns-to-goal integer outside it.
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

@export var slot_size := Vector2(30, 12)
@export var slot_gap := 3.0
## Turn duration — the single configurable time knob (default 1s). Tag
## glides run this long so indicators slide continuously.
@export var turn_duration := 1.0
## How long the charging fill takes to tween to a newly reported fraction
## (kept under the demo tick so motion reads as continuous).
@export var charge_tween_duration := 0.15
@export var slot_color := Color(0.1, 0.09, 0.09, 0.85)
@export var goal_color := Color(0.55, 0.16, 0.14, 0.9)
@export var energy_color := Color(0.95, 0.72, 0.18, 1.0)
@export var charging_color := Color(0.95, 0.72, 0.18, 0.4)
@export var turns_color := Color(0.92, 0.86, 0.68, 1.0)
@export var count_color := Color(0.22, 0.1, 0.06, 1.0)
@export var wood_texture: Texture2D = preload("res://src/resource/battlefield/wood_panel.png")
@export var arrow_down_texture: Texture2D = preload("res://src/resource/battlefield/arrow_down.png")
@export var arrow_up_texture: Texture2D = preload("res://src/resource/battlefield/arrow_up.png")
@export var flag_texture: Texture2D = preload("res://src/resource/battlefield/goal_flag.png")
## Ticket-01 scaffolding: cycle a crafted state to preview the animations.
@export var demo_mode := false

@onready var _upper_tags: HBoxContainer = $Frame/Margin/Content/Board/UpperTags
@onready var _upper_bar: HBoxContainer = $Frame/Margin/Content/Board/UpperBarRow
@onready var _lower_bar: HBoxContainer = $Frame/Margin/Content/Board/LowerBar
@onready var _lower_tags: HBoxContainer = $Frame/Margin/Content/Board/LowerTags

var _fills: Array[ColorRect] = []
var _tag_movers: Array[Control] = []
var _tag_turns: Array[Label] = []
var _tag_counts: Array[Label] = []
var _tag_arrows: Array[TextureRect] = []
var _fill_tweens: Dictionary = {}

## The animation kind the last apply_state() requested — "glide",
## "fade_teleport", "rewind", or "" for none. The observable animation seam
## for tests (tween parameters are never asserted).
var last_animation_kind := ""

var _state: Dictionary = {"energy": 0, "charge": 0.0, "tags": {}}
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
	for row in [_lower_bar, _upper_bar, _lower_tags, _upper_tags]:
		row.add_theme_constant_override("separation", int(slot_gap))
	_fills.resize(SLOT_COUNT)
	_tag_movers.resize(SLOT_COUNT)
	_tag_turns.resize(SLOT_COUNT)
	_tag_counts.resize(SLOT_COUNT)
	_tag_arrows.resize(SLOT_COUNT)
	# The goal flag leads the upper bar (goal = slot 19 at the upper-left);
	# a matching spacer keeps the upper tag row aligned with its slots.
	_upper_bar.add_child(_make_flag_cell())
	_upper_tags.add_child(_make_spacer_cell())
	# Lower bar: slots 0..9 left→right. Upper bar: slots 19..10 left→right.
	for slot in range(BAR_SIZE):
		_lower_bar.add_child(_make_slot_cell(slot, false))
		_lower_tags.add_child(_make_tag_cell(slot, false))
	for column in range(BAR_SIZE):
		var slot := GOAL_SLOT - column
		_upper_bar.add_child(_make_slot_cell(slot, true))
		_upper_tags.add_child(_make_tag_cell(slot, true))


func _make_flag_cell() -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = slot_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flag := TextureRect.new()
	flag.texture = flag_texture
	flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.custom_minimum_size = Vector2(slot_size.x, slot_size.y + 6.0)
	flag.position = Vector2(0, -6.0)
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(flag)
	return cell


func _make_spacer_cell() -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = slot_size
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var fill := ColorRect.new()
	fill.color = energy_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The fill grows along the path direction: left→right on the lower bar,
	# right→left on the upper bar.
	if upper:
		fill.anchor_left = 1.0
		fill.anchor_right = 1.0
		fill.offset_left = 0.0
	else:
		fill.anchor_left = 0.0
		fill.anchor_right = 0.0
		fill.offset_right = 0.0
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.offset_top = 0.0
	fill.offset_bottom = 0.0
	cell.add_child(fill)
	_fills[slot] = fill
	return cell


func _make_tag_cell(slot: int, upper: bool) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(slot_size.x, slot_size.y + 14.0)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The mover is the animated content: glides offset, or fades for the wrap.
	var mover := Control.new()
	mover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.modulate.a = 0.0
	cell.add_child(mover)
	var turns := Label.new()
	turns.modulate = turns_color
	turns.add_theme_font_size_override("font_size", 11)
	turns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turns.size = Vector2(slot_size.x, 12)
	turns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.add_child(turns)
	# The count sits on the arrow itself, in a contrasting color.
	var arrow_frame := Control.new()
	arrow_frame.size = Vector2(slot_size.x, slot_size.y + 2)
	arrow_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := TextureRect.new()
	arrow.texture = arrow_down_texture if upper else arrow_up_texture
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_frame.add_child(arrow)
	var count := Label.new()
	count.modulate = count_color
	count.add_theme_font_size_override("font_size", 11)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_frame.add_child(count)
	mover.add_child(arrow_frame)
	# Arrow nearest the bar, Turns integer outermost.
	if upper:
		turns.position = Vector2.ZERO
		arrow_frame.position = Vector2(0, 12)
	else:
		arrow_frame.position = Vector2.ZERO
		turns.position = Vector2(0, slot_size.y + 2)
	_tag_movers[slot] = mover
	_tag_arrows[slot] = arrow
	_tag_counts[slot] = count
	_tag_turns[slot] = turns
	return cell


# ----- public view API (the model→view seam) -----

## Render a full board state instantly, no animation.
func render_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_render_energy(state.get("energy", 0), state.get("charge", 0.0), false)
	_render_tags(state.get("tags", {}))


## Apply a new state, animating the transition: the charging fill tweens
## smoothly, a completing slot pops, spend-Energy rewinds, tag moves glide,
## 9→10 wraps fade-teleport. Records last_animation_kind.
func apply_state(state: Dictionary) -> void:
	var old: Dictionary = _state
	var kind := ""
	var new_energy: int = state.get("energy", 0)
	var old_energy: int = old.get("energy", 0)
	var old_tags: Dictionary = old.get("tags", {})
	var new_tags: Dictionary = state.get("tags", {})
	if new_energy < old_energy:
		kind = "rewind"
		_play_rewind(old_energy, new_energy)
	elif new_energy > old_energy:
		for slot in range(old_energy, new_energy):
			_play_charge_pop(slot)
	# Tag movement: same count one slot further along the path = a glide;
	# crossing 9→10 wraps with a fade-teleport.
	for slot in new_tags:
		var moved_from := -1
		if not old_tags.has(slot):
			var prev: int = slot - 1
			if old_tags.has(prev) and old_tags[prev].get("count", -1) == new_tags[slot].get("count", -2):
				moved_from = prev
		if moved_from == 9 and slot == 10:
			kind = "fade_teleport"
			_play_fade_teleport(moved_from, slot)
		elif moved_from >= 0:
			if kind == "":
				kind = "glide"
			_play_glide(moved_from, slot)
	last_animation_kind = kind
	_state = state.duplicate(true)
	_render_energy(state.get("energy", 0), state.get("charge", 0.0), true)
	_render_tags(state.get("tags", {}))


# ----- observable renderable output (test seam; never tween internals) -----

func slot_bar(slot: int) -> String:
	return "upper" if slot >= BAR_SIZE else "lower"


## Left-to-right screen column of a slot within its bar (0 = leftmost),
## not counting the goal-flag prefix cell.
func slot_column(slot: int) -> int:
	return GOAL_SLOT - slot if slot >= BAR_SIZE else slot


## Rendered fill ratio of a slot: 1.0 filled, the fractional charge on the
## charging slot, 0.0 otherwise.
func slot_fill_ratio(slot: int) -> float:
	return _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Tag render info for a slot: {"side", "count", "turns", "arrow"}, or empty
## when no tag is rendered there. Arrow is the actual texture direction.
func tag_info(slot: int) -> Dictionary:
	var mover := _tag_movers[slot]
	if mover == null or mover.modulate.a <= 0.0:
		return {}
	return {
		"side": "above" if slot >= BAR_SIZE else "below",
		"count": int(_tag_counts[slot].text),
		"turns": int(_tag_turns[slot].text),
		"arrow": "down" if _tag_arrows[slot].texture == arrow_down_texture else "up",
	}


# ----- rendering -----

func _render_energy(energy: int, charge: float, animate: bool) -> void:
	for slot in range(SLOT_COUNT):
		var fill := _fills[slot]
		if slot < energy:
			_set_fill(fill, slot, 1.0, energy_color, animate)
		elif slot == energy and energy < SLOT_COUNT:
			_set_fill(fill, slot, clampf(charge, 0.0, 1.0), charging_color, animate)
		else:
			_set_fill(fill, slot, 0.0, energy_color, animate)


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
			_tag_counts[slot].text = str(tags[slot].get("count", 0))
			_tag_turns[slot].text = str(tags[slot].get("turns", 0))
			mover.modulate.a = 1.0
		else:
			mover.modulate.a = 0.0


# ----- animations (tuned visually in the editor; never asserted) -----

## Smooth one-slot glide: content appears at the old column and slides over
## (one Turn long, so indicators move continuously).
func _play_glide(from_slot: int, to_slot: int) -> void:
	var mover := _tag_movers[to_slot]
	var pitch := slot_size.x + slot_gap
	# Lower bar path goes right; upper bar path goes left.
	var direction := -1.0 if to_slot >= BAR_SIZE else 1.0
	mover.position.x = -direction * pitch
	var tween := create_tween()
	tween.tween_property(mover, "position:x", 0.0, turn_duration * 0.9)


## The 9→10 wrap: fade out at the lower-right, fade in at the upper-right.
func _play_fade_teleport(from_slot: int, to_slot: int) -> void:
	var old_mover := _tag_movers[from_slot]
	var new_mover := _tag_movers[to_slot]
	var tween := create_tween()
	tween.tween_property(old_mover, "modulate:a", 0.0, 0.12)
	tween.tween_property(new_mover, "modulate:a", 1.0, 0.12)


## Spend-Energy rewind: the drained slots flash and empty along the path.
func _play_rewind(old_energy: int, new_energy: int) -> void:
	var tween := create_tween()
	for slot in range(old_energy - 1, new_energy - 1, -1):
		tween.tween_property(_fills[slot], "modulate:a", 0.2, 0.05)
		tween.tween_property(_fills[slot], "modulate:a", 1.0, 0.05)


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
