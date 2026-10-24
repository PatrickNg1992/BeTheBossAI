extends McpTestSuite

## View-seam tests for the Time Board (ticket 01): renderable output for
## crafted states — serpentine layout, energy fill path, tag arrows with
## integers, and the animation KIND requested by a state change (glide vs
## fade-teleport vs rewind). Tween parameters are never asserted.

const TIME_BOARD_SCENE := "res://src/canvas/time_board.tscn"

var _board: TimeBoard = null


func suite_name() -> String:
	return "time-board-view"


func setup() -> void:
	var packed := ResourceLoader.load(TIME_BOARD_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Time Board scene failed to load")
	if packed == null:
		return
	_board = packed.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_board)


func teardown() -> void:
	if is_instance_valid(_board):
		_board.get_parent().remove_child(_board)
		_board.queue_free()
	_board = null


func _state(energy: int, charge: float, tags: Dictionary) -> Dictionary:
	return {"energy": energy, "charge": charge, "tags": tags}


func test_serpentine_layout_with_goal_at_upper_left() -> void:
	if _board == null:
		return
	assert_eq(_board.slot_bar(0), "lower", "Slot 0 is on the lower bar")
	assert_eq(_board.slot_bar(9), "lower", "Slot 9 is on the lower bar")
	assert_eq(_board.slot_bar(10), "upper", "Slot 10 is on the upper bar")
	assert_eq(_board.slot_bar(19), "upper", "Slot 19 is on the upper bar")
	assert_eq(_board.slot_column(0), 0, "Slot 0 is the lower bar's leftmost")
	assert_eq(_board.slot_column(9), 9, "Slot 9 is the lower bar's rightmost")
	assert_eq(_board.slot_column(10), 9, "Slot 10 is the upper bar's rightmost")
	assert_eq(_board.slot_column(19), 0, "The goal (slot 19) is the upper-left")


func test_energy_fill_grows_from_the_lower_left() -> void:
	if _board == null:
		return
	_board.render_state(_state(14, 0.5, {}))
	assert_eq(_board.slot_fill_ratio(0), 1.0, "Fill starts at slot 0")
	assert_eq(_board.slot_fill_ratio(9), 1.0, "The lower bar fills first")
	assert_eq(_board.slot_fill_ratio(10), 1.0, "Then the path crosses to the upper-right")
	assert_eq(_board.slot_fill_ratio(13), 1.0, "Upper fill extends toward the goal")
	assert_eq(_board.slot_fill_ratio(14), 0.5, "The charging slot fills progressively")
	assert_eq(_board.slot_fill_ratio(15), 0.0, "Slots past the charge stay empty")


func test_energy_caps_at_20_filled_slots() -> void:
	if _board == null:
		return
	_board.render_state(_state(20, 0.0, {}))
	assert_eq(_board.slot_fill_ratio(19), 1.0, "Even the goal slot fills at cap")
	assert_eq(_board.slot_fill_ratio(0), 1.0, "Every slot filled at 20")


func test_tag_renders_below_lower_bar_with_integers() -> void:
	if _board == null:
		return
	_board.render_state(_state(0, 0.0, {3: {"count": 2, "turns": 16}}))
	var info := _board.tag_info(3)
	assert_eq(info.get("side"), "below", "Lower-bar tag renders below the bar")
	assert_eq(info.get("arrow"), "up", "Lower-bar tag arrow points up into the bar")
	assert_eq(info.get("count"), 2, "Tag shows the unit count")
	assert_eq(info.get("turns"), 16, "Tag shows the Turns-to-goal integer")


func test_tag_renders_above_upper_bar_with_integers() -> void:
	if _board == null:
		return
	_board.render_state(_state(0, 0.0, {14: {"count": 3, "turns": 5}}))
	var info := _board.tag_info(14)
	assert_eq(info.get("side"), "above", "Upper-bar tag renders above the bar")
	assert_eq(info.get("arrow"), "down", "Upper-bar tag arrow points down into the bar")
	assert_eq(info.get("count"), 3, "Tag shows the unit count")
	assert_eq(info.get("turns"), 5, "Tag shows the Turns-to-goal integer")


func test_no_text_on_the_board_beyond_integers() -> void:
	if _board == null:
		return
	_board.render_state(_state(7, 0.5, {3: {"count": 2, "turns": 16}, 14: {"count": 1, "turns": 5}}))
	var queue: Array[Node] = [_board]
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		for child in node.get_children():
			queue.append(child)
		if node is Label:
			var text := (node as Label).text
			assert_true(text.is_empty() or text.is_valid_int(),
				"Board text must be integers only, got: '%s'" % text)


func test_tag_glide_requests_glide_animation() -> void:
	if _board == null:
		return
	_board.apply_state(_state(0, 0.0, {3: {"count": 2, "turns": 16}}))
	_board.apply_state(_state(0, 0.0, {4: {"count": 2, "turns": 15}}))
	assert_eq(_board.last_animation_kind, "glide", "A tag moving one slot along the bar glides")


func test_tag_crossing_9_to_10_requests_fade_teleport() -> void:
	if _board == null:
		return
	_board.apply_state(_state(0, 0.0, {9: {"count": 1, "turns": 10}}))
	_board.apply_state(_state(0, 0.0, {10: {"count": 1, "turns": 9}}))
	assert_eq(_board.last_animation_kind, "fade_teleport", "The 9→10 wrap fades out and in")


func test_spend_energy_requests_rewind_animation() -> void:
	if _board == null:
		return
	_board.apply_state(_state(10, 0.0, {}))
	_board.apply_state(_state(4, 0.0, {}))
	assert_eq(_board.last_animation_kind, "rewind", "Spending Energy rewinds the fill")


func test_plain_charge_progress_requests_no_animation() -> void:
	if _board == null:
		return
	_board.apply_state(_state(4, 0.0, {}))
	_board.apply_state(_state(4, 0.5, {}))
	assert_eq(_board.last_animation_kind, "", "Plain charging just fills smoothly")


func test_view_renders_whatever_it_is_fed() -> void:
	if _board == null:
		return
	# Arbitrary crafted state — the view holds no rules about what belongs.
	var crafted := _state(11, 0.25, {
		0: {"count": 9, "turns": 19},
		19: {"count": 1, "turns": 0},
		10: {"count": 5, "turns": 9},
	})
	_board.render_state(crafted)
	assert_eq(_board.tag_info(0).get("turns"), 19, "Tag data renders verbatim")
	assert_eq(_board.tag_info(19).get("count"), 1, "Even the goal slot renders what it's fed")
	assert_eq(_board.tag_info(10).get("count"), 5, "Upper-right slot renders verbatim")
	assert_true(_board.tag_info(7).is_empty(), "Empty slots render no tag")
