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


# ----- Ticket 01 (cue-shot-energy): half-slot energy + bottom-left consume/over-drag preview -----


func test_half_slot_energy_renders_accurately_along_serpentine_path() -> void:
	if _board == null:
		return
	# When energy = 11.5 (slots 0..10 full, slot 11 has 0.5 owned) and charge = 0.6:
	# - First 0.4 of charge fills the second half of slot 11 (from 0.5 to 0.9), so slot 11 has 0.5 owned + 0.4 charging
	# - Remaining 0.2 of charge spills into slot 12 (from 0.0 to 0.2) without leaving a 0.5 gap!
	_board.render_state({"energy": 11.5, "charge": 0.6, "tags": {}})
	assert_eq(_board.slot_fill_ratio(0), 1.0, "Slot 0 filled")
	assert_eq(_board.slot_fill_ratio(10), 1.0, "Slot 10 filled")
	assert_eq(_board.slot_fill_ratio(11), 0.5, "Slot 11 shows the 0.5 half-slot owned Energy")
	assert_eq(_board.slot_fill_kind(11), "energy", "Half-slot owned Energy renders in normal energy kind")
	assert_true(is_equal_approx(_board.slot_charging_ratio(11), 0.5), "Slot 11 charging fill covers the remaining 0.5 half of slot 11")
	assert_true(is_equal_approx(_board.slot_charging_ratio(12), 0.1), "Remaining 0.1 of the 0.6 Turn charge continues seamlessly into slot 12")
	assert_eq(_board.slot_fill_kind(12), "charging", "Slot 12 renders in charging kind")
	assert_eq(_board.slot_fill_ratio(13), 0.0, "Slot 13 empty")


func test_affordable_preview_cost_highlights_from_slot_0_and_keeps_remaining_energy_gold() -> void:
	if _board == null:
		return
	_board.render_state({"energy": 6.5, "charge": 0.0, "preview_cost": 3.5, "tags": {}})
	assert_eq(_board.slot_consume_ratio(0), 1.0, "Slot 0 is fully highlighted in consume-preview colour")
	assert_eq(_board.slot_consume_ratio(2), 1.0, "Slot 2 is fully highlighted in consume-preview colour")
	assert_eq(_board.slot_consume_ratio(3), 0.5, "Slot 3 has first 0.5 highlighted in consume-preview colour")
	assert_eq(_board.slot_fill_ratio(3), 1.0, "Slot 3 still has full 1.0 owned Energy underneath")
	assert_eq(_board.slot_consume_ratio(4), 0.0, "Slot 4 is past preview_cost and has no consume highlight")
	assert_eq(_board.slot_fill_ratio(5), 1.0, "Slot 5 remains in normal owned Energy colour")
	assert_eq(_board.slot_fill_ratio(6), 0.5, "Slot 6 shows the remaining 0.5 owned Energy")
	assert_eq(_board.slot_overdrag_ratio(3), 0.0, "No red overdrag when preview_cost <= energy")


func test_overdrag_preview_cost_highlights_owned_energy_and_continues_in_red() -> void:
	if _board == null:
		return
	# Owned energy = 2.5, preview_cost = 4.5 -> 0..2.5 consume-preview, 2.5..4.5 red overdrag
	_board.render_state({"energy": 2.5, "charge": 0.0, "preview_cost": 4.5, "tags": {}})
	assert_eq(_board.slot_consume_ratio(0), 1.0, "Slot 0 is consume-preview")
	assert_eq(_board.slot_consume_ratio(1), 1.0, "Slot 1 is consume-preview")
	assert_eq(_board.slot_consume_ratio(2), 0.5, "Slot 2 first half is consume-preview")
	assert_eq(_board.slot_overdrag_ratio(2), 0.5, "Slot 2 second half is red overdrag")
	assert_eq(_board.slot_overdrag_ratio(3), 1.0, "Slot 3 is full red overdrag")
	assert_eq(_board.slot_overdrag_ratio(4), 0.5, "Slot 4 first half is red overdrag")
	assert_eq(_board.slot_overdrag_ratio(5), 0.0, "Slot 5 is untouched")

	# Clearing preview_cost (0.0) restores normal owned Energy display
	_board.set_preview_cost(0.0)
	assert_eq(_board.slot_consume_ratio(0), 0.0, "Clearing preview_cost removes consume highlight")
	assert_eq(_board.slot_overdrag_ratio(2), 0.0, "Clearing preview_cost removes red overdrag")
	assert_eq(_board.slot_fill_ratio(0), 1.0, "Owned Energy on slot 0 restored")
	assert_eq(_board.slot_fill_ratio(2), 0.5, "Half-slot owned Energy on slot 2 restored")


func test_all_energy_reductions_trigger_sequential_rewind_animation() -> void:
	if _board == null:
		return
	_board.render_state({"energy": 8.5, "charge": 0.0, "tags": {}})
	# 1. Reduction via apply_state (e.g. TimingManager.energy_changed after consume_energy / set_energy)
	_board.apply_state({"energy": 5.0, "charge": 0.0, "tags": {}})
	assert_eq(_board.last_animation_kind, "rewind", "Energy reduction via apply_state triggers sequential rewind")
	assert_eq(_board.slot_fill_ratio(4), 1.0, "Slot 4 remains filled")
	assert_eq(_board.slot_fill_ratio(5), 0.0, "Slots 5..8 drained")

	# 2. Reduction via reusable animate_energy_reduction helper (e.g. card cost or drain effect)
	_board.last_animation_kind = ""
	_board.animate_energy_reduction(2.5)
	assert_eq(_board.last_animation_kind, "rewind", "animate_energy_reduction triggers the same sequential rewind")
	assert_eq(_board.slot_fill_ratio(1), 1.0, "Slot 1 remains filled")
	assert_eq(_board.slot_fill_ratio(2), 0.5, "Slot 2 reduced to half-slot 0.5")
	assert_eq(_board.slot_fill_ratio(3), 0.0, "Slots 3..4 drained")


# ----- Ticket 02 (battlefield-data-sync): Two-Player Time Board mode & perspective mapping -----


func test_two_player_mode_visibility_and_perspective_mapping() -> void:
	if _board == null:
		return
	# 1. Single-player (has_player_b = false): extra top bar is hidden
	_board.render_state({
		"has_player_b": false,
		"energy_a": 12.0,
		"energy_b": 0.0,
		"charge": 0.5,
		"tags": {},
	})
	assert_false(_board.is_two_player_mode(), "1-player mode when has_player_b is false")
	assert_eq(_board.slot_fill_ratio(11), 1.0, "Main bar shows Player A's 12.0 Energy")
	assert_eq(_board.slot_fill_ratio(12), 0.5, "Main bar shows 0.5 charge at slot 12")

	# 2. Two-player mode as Player A ("a") or Spectator ("spectator"):
	#    Main bar = Player A (14.5), Extra top bar = Player B (6.5)
	_board.set_perspective_role("a")
	_board.render_state({
		"has_player_b": true,
		"energy_a": 14.5,
		"energy_b": 6.5,
		"charge": 0.0,
		"tags": {5: {"count": 2, "turns": 14}},
	})
	assert_true(_board.is_two_player_mode(), "Extra top bar is visible when has_player_b is true")
	assert_eq(_board.slot_fill_ratio(13), 1.0, "Player A sees own Energy (14.5) on main bar slot 13")
	assert_eq(_board.slot_fill_ratio(14), 0.5, "Player A sees own Energy (14.5) half-slot on main bar slot 14")
	assert_eq(_board.secondary_slot_fill_ratio(5), 1.0, "Player A sees Player B's Energy (6.5) on secondary top bar slot 5")
	assert_eq(_board.secondary_slot_fill_ratio(6), 0.5, "Player A sees Player B's Energy (6.5) half-slot on secondary top bar slot 6")
	assert_eq(_board.secondary_slot_fill_ratio(7), 0.0, "Secondary top bar slot 7 is empty")

	# Spectator sees the same orientation (Main = Player A, Secondary = Player B)
	_board.set_perspective_role("spectator")
	assert_eq(_board.slot_fill_ratio(14), 0.5, "Spectator sees Player A's 14.5 Energy on main bar")
	assert_eq(_board.secondary_slot_fill_ratio(6), 0.5, "Spectator sees Player B's 6.5 Energy on secondary top bar")

	# 3. Two-player mode as Player B ("b"): reversed so Player B sees self on main bar!
	#    Main bar = Player B (6.5), Extra top bar = Player A (14.5)
	_board.set_perspective_role("b")
	assert_eq(_board.slot_fill_ratio(5), 1.0, "Player B sees own Energy (6.5) on main bar slot 5")
	assert_eq(_board.slot_fill_ratio(6), 0.5, "Player B sees own Energy (6.5) half-slot on main bar slot 6")
	assert_eq(_board.slot_fill_ratio(7), 0.0, "Player B main bar slot 7 is empty")
	assert_eq(_board.secondary_slot_fill_ratio(13), 1.0, "Player B sees Player A's Energy (14.5) on secondary top bar slot 13")
	assert_eq(_board.secondary_slot_fill_ratio(14), 0.5, "Player B sees Player A's Energy (14.5) half-slot on secondary top bar slot 14")

	# 4. Rewind animation triggers when EITHER player's Energy decreases in 2-player mode
	_board.last_animation_kind = ""
	_board.apply_state({
		"has_player_b": true,
		"energy_a": 10.0,
		"energy_b": 6.5,
		"charge": 0.0,
		"tags": {},
	})
	assert_eq(_board.last_animation_kind, "rewind",
		"Lowering Player A's Energy (on the secondary bar for Player B) still triggers rewind animation")
	assert_eq(_board.secondary_slot_fill_ratio(9), 1.0, "Secondary bar rewound to 10.0 (slot 9 filled)")
	assert_eq(_board.secondary_slot_fill_ratio(10), 0.0, "Secondary bar slot 10 drained")



