class_name TimeBoard
extends Control

## The Time Board view: a dumb renderer for board state fed to it.
## Two serpentine 10-slot bars — slot 0 lower-left, slot 9 lower-right,
## slot 10 upper-right, slot 19 (the goal) upper-left. The Energy fill grows
## from slot 0 along the path; the charging slot fills progressively over the
## Turn. Tag arrows sit above the upper bar / below the lower bar pointing
## into the bar, each carrying a unit-count and a Turns-to-goal integer.
##
## All motion lives here and only here: the smooth one-slot glide, the 9→10
## fade-out/fade-in teleport wrap, and the spend-Energy rewind. No board
## rules — the view renders and animates whatever state it is fed.
##
## `demo_mode` is ticket-01 scaffolding (crafted placeholder states so the
## look and feel can be tuned before the model exists); ticket 02 removes it.

## Crafted/model state shape:
## {"energy": int 0..20, "charge": float 0..1, "tags": {slot: {"count", "turns"}}}

const SLOT_COUNT := 20
const BAR_SIZE := 10
const GOAL_SLOT := 19

@export var slot_size := Vector2(26, 26)
@export var slot_gap := 3.0
@export var tag_row_height := 44.0
@export var slot_color := Color(0.12, 0.12, 0.16, 0.9)
@export var goal_color := Color(0.2, 0.45, 0.25, 0.95)
@export var energy_color := Color(0.95, 0.75, 0.2, 1.0)
@export var charging_color := Color(0.95, 0.75, 0.2, 0.45)
@export var tag_color := Color(0.9, 0.9, 0.95, 1.0)
## Ticket-01 scaffolding: cycle a crafted state to preview the animations.
@export var demo_mode := false

@onready var _upper_tags: HBoxContainer = $Board/UpperTags
@onready var _upper_bar: HBoxContainer = $Board/UpperBar
@onready var _lower_bar: HBoxContainer = $Board/LowerBar
@onready var _lower_tags: HBoxContainer = $Board/LowerTags

var _fills: Array[ColorRect] = []
var _tag_movers: Array[Control] = []
var _tag_turns: Array[Label] = []
var _tag_counts: Array[Label] = []
var _tag_arrows: Array[Label] = []

## The animation kind the last apply_state() requested — "glide",
## "fade_teleport", "rewind", or "" for none. The observable animation seam
## for tests (tween parameters are never asserted).
var last_animation_kind := ""

var _state: Dictionary = {"energy": 0, "charge": 0.0, "tags": {}}
var _demo_timer: Timer = null
var _demo_state: Dictionary = {}


func _ready() -> void:
	_build_board()
	render_state(_state)
	if demo_mode:
		_start_demo()


# ----- construction (all generated: tuning happens via the exports) -----

func _build_board() -> void:
	_lower_bar.add_theme_constant_override("separation", int(slot_gap))
	_upper_bar.add_theme_constant_override("separation", int(slot_gap))
	_lower_tags.add_theme_constant_override("separation", int(slot_gap))
	_upper_tags.add_theme_constant_override("separation", int(slot_gap))
	_fills.resize(SLOT_COUNT)
	_tag_movers.resize(SLOT_COUNT)
	_tag_turns.resize(SLOT_COUNT)
	_tag_counts.resize(SLOT_COUNT)
	_tag_arrows.resize(SLOT_COUNT)
	# Lower bar: slots 0..9 left→right. Upper bar: slots 19..10 left→right.
	for slot in range(BAR_SIZE):
		_lower_bar.add_child(_make_slot_cell(slot, false))
		_lower_tags.add_child(_make_tag_cell(slot, false))
	for column in range(BAR_SIZE):
		var slot := GOAL_SLOT - column
		_upper_bar.add_child(_make_slot_cell(slot, true))
		_upper_tags.add_child(_make_tag_cell(slot, true))


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
	cell.custom_minimum_size = Vector2(slot_size.x, tag_row_height)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The mover is the animated content: glides offset, or fades for the wrap.
	var mover := Control.new()
	mover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.modulate.a = 0.0
	cell.add_child(mover)
	var arrow := Label.new()
	arrow.text = "▼" if upper else "▲"
	arrow.modulate = tag_color
	var count := Label.new()
	count.modulate = tag_color
	var turns := Label.new()
	turns.modulate = tag_color
	turns.add_theme_font_size_override("font_size", 14)
	for label in [arrow, count, turns]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(slot_size.x, 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mover.add_child(label)
	# Arrow nearest the bar, Turns integer outermost.
	if upper:
		turns.position = Vector2.ZERO
		count.position = Vector2(0, 14)
		arrow.position = Vector2(0, 28)
	else:
		arrow.position = Vector2.ZERO
		count.position = Vector2(0, 14)
		turns.position = Vector2(0, 28)
	_tag_movers[slot] = mover
	_tag_arrows[slot] = arrow
	_tag_counts[slot] = count
	_tag_turns[slot] = turns
	return cell


# ----- public view API (the model→view seam) -----

## Render a full board state instantly, no animation.
func render_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_render_energy(state.get("energy", 0), state.get("charge", 0.0))
	_render_tags(state.get("tags", {}))


## Apply a new state, animating the transition: spend-Energy rewind, the
## 9→10 fade-teleport wrap, and one-slot glides. Records last_animation_kind.
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
	render_state(state)


# ----- observable renderable output (test seam; never tween internals) -----

func slot_bar(slot: int) -> String:
	return "upper" if slot >= BAR_SIZE else "lower"


## Left-to-right screen column of a slot within its bar (0 = leftmost).
func slot_column(slot: int) -> int:
	return GOAL_SLOT - slot if slot >= BAR_SIZE else slot


## Rendered fill ratio of a slot: 1.0 filled, the fractional charge on the
## charging slot, 0.0 otherwise.
func slot_fill_ratio(slot: int) -> float:
	return _fills[slot].size.x / slot_size.x if slot_size.x > 0.0 else 0.0


## Tag render info for a slot: {"side": "above"/"below", "count", "turns"},
## or empty when no tag is rendered there.
func tag_info(slot: int) -> Dictionary:
	var mover := _tag_movers[slot]
	if mover == null or mover.modulate.a <= 0.0:
		return {}
	return {
		"side": "above" if slot >= BAR_SIZE else "below",
		"count": int(_tag_counts[slot].text),
		"turns": int(_tag_turns[slot].text),
		"arrow": _tag_arrows[slot].text,
	}


# ----- rendering -----

func _render_energy(energy: int, charge: float) -> void:
	for slot in range(SLOT_COUNT):
		var fill := _fills[slot]
		if slot < energy:
			_set_fill(fill, 1.0, energy_color)
		elif slot == energy and energy < SLOT_COUNT:
			_set_fill(fill, clampf(charge, 0.0, 1.0), charging_color)
		else:
			_set_fill(fill, 0.0, energy_color)


func _set_fill(fill: ColorRect, ratio: float, color: Color) -> void:
	fill.color = color
	var width := slot_size.x * ratio
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

## Smooth one-slot glide: content appears at the old column and tweens to 0.
func _play_glide(from_slot: int, to_slot: int) -> void:
	var mover := _tag_movers[to_slot]
	var pitch := slot_size.x + slot_gap
	# Lower bar path goes right; upper bar path goes left.
	var direction := -1.0 if to_slot >= BAR_SIZE else 1.0
	mover.position.x = -direction * pitch
	var tween := create_tween()
	tween.tween_property(mover, "position:x", 0.0, 0.18)


## The 9→10 wrap: fade out at the lower-right, fade in at the upper-right.
func _play_fade_teleport(from_slot: int, to_slot: int) -> void:
	var old_mover := _tag_movers[from_slot]
	var new_mover := _tag_movers[to_slot]
	var tween := create_tween()
	tween.tween_property(old_mover, "modulate:a", 0.0, 0.12)
	tween.tween_property(new_mover, "modulate:a", 1.0, 0.12)


## Spend-Energy rewind: the drained slots empty quickly along the path.
func _play_rewind(old_energy: int, new_energy: int) -> void:
	var tween := create_tween()
	for slot in range(old_energy - 1, new_energy - 1, -1):
		tween.tween_property(_fills[slot], "modulate:a", 0.2, 0.05)
		tween.tween_property(_fills[slot], "modulate:a", 1.0, 0.05)


# ----- ticket-01 demo scaffolding (removed when the model lands) -----

func _start_demo() -> void:
	_demo_state = {
		"energy": 8,
		"charge": 0.5,
		"tags": {
			3: {"count": 2, "turns": 16},
			12: {"count": 1, "turns": 7},
			17: {"count": 4, "turns": 2},
		},
	}
	render_state(_demo_state)
	_demo_timer = Timer.new()
	_demo_timer.wait_time = 0.8
	_demo_timer.timeout.connect(_demo_step)
	add_child(_demo_timer)
	_demo_timer.start()


var _demo_tick := 0


func _demo_step() -> void:
	_demo_tick += 1
	var next: Dictionary = _demo_state.duplicate(true)
	# Tags advance one slot per tick; the goal slot consumes them; every few
	# ticks a fresh tag appears so the loop never empties.
	var next_tags := {}
	for slot in next.get("tags", {}):
		if slot + 1 <= GOAL_SLOT:
			next_tags[slot + 1] = next["tags"][slot]
	if _demo_tick % 3 == 0:
		var spawn_slot := 2 + (_demo_tick % 5)
		next_tags[spawn_slot] = {"count": 1 + _demo_tick % 3, "turns": GOAL_SLOT - spawn_slot}
	next["tags"] = next_tags
	# Energy charges; every so often a spend rewinds the fill.
	if _demo_tick % 8 == 7:
		next["energy"] = maxi(0, next.get("energy", 0) - 4)
		next["charge"] = 0.0
	else:
		var charge: float = next.get("charge", 0.0) + 0.5
		var energy: int = next.get("energy", 0)
		if charge >= 1.0:
			charge = 0.0
			energy = mini(SLOT_COUNT, energy + 1)
		next["charge"] = charge
		next["energy"] = energy
	_demo_state = next
	apply_state(_demo_state)
