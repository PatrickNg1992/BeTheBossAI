extends McpTestSuite

## Ticket 02 tests (covering enemy-adventurers/02, time-board-display/02 & 03, and timing-system/02):
## - TimeBoardModel:
##   * Permanent cycle Action Tags at turns 3, 4, 6, 8, 9, 12 of each repeating 12-turn Action Cycle (even when count == 0)
##   * Every non-defeated Adventurer contributes +1 to all multiples of its fixed Action Countdown (3, 4, or 6), including while pocketed
##   * 12-interval tags flagged with `is_cycle_12 = true` for special colour highlight
##   * Prepare Time entry (`enter_prepare`): sets Energy to 10, clears old tags, places incoming team's cycle tags, initializes unit Action Countdowns, and freezes
##   * Per-Turn progression in Charging Time: advances tags 1 slot toward goal, decrements unit `next_action_turns` (synced to UnitInformationManager / UnitDisplay) and ticks Skill Countdowns
##   * 0-count cycle tag reaching the goal clears immediately without triggering Action Time
##   * >0-count cycle tag reaching the goal pins at goal and triggers Action Time; resets acted units' Action Countdowns at the end of Settle Time
##   * Defeated units are removed from future cycle tag counts in Settle Time
## - TimeBoard View:
##   * Upper-bar tags (slots 10..19, within 10 turns) show a count circle on top of the arrow when count > 0, and hide the circle when count == 0
##   * Lower-bar tags (slots 0..9) show only the arrow (count circle hidden)
##   * 12-interval tags render with the highlighted 12-cycle arrow colour
##   * No turns-to-goal integer is rendered on Time Board tags
## - 12-Turn Hit Level Persistence & Reset:
##   * Hit Level persists across Settle Time on turns 1..11 of the 12-turn cycle (while Damage Stack clears and Boss Frenzy Power decays every Settle Time)
##   * Hit Level resets to 0 across all units only after the Settle Time of Turn 12

const TIME_BOARD_MODEL_PATH := "res://src/canvas/time_board_model.gd"
const TIME_BOARD_SCENE := "res://src/canvas/time_board.tscn"
const UNIT_INFO_MANAGER_PATH := "res://src/battlefield/unit_information_manager.gd"
const UNIT_SKILL_MANAGER_PATH := "res://src/battlefield/unit_skill_manager.gd"
const UNIT_INFO_BOARD_PATH := "res://src/canvas/unit_information_board.gd"


func suite_name() -> String:
	return "time-board-model-and-action-cycle"


func test_prepare_time_opening_state_and_12_turn_cycle_tag_aggregation() -> void:
	assert_true(ResourceLoader.exists(TIME_BOARD_MODEL_PATH), "TimeBoardModel script exists")
	if not ResourceLoader.exists(TIME_BOARD_MODEL_PATH):
		return
	var tree := Engine.get_main_loop() as SceneTree
	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var model = load(TIME_BOARD_MODEL_PATH).new()
	tree.root.add_child(tm)
	tree.root.add_child(uim)
	tree.root.add_child(usm)
	usm.bind_unit_information_manager(uim)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	# Register 1 Guard (cd=4), 1 Brawler (cd=4), 1 Scout (cd=3), 1 Acolyte (cd=6)
	uim.register_adventurer_team(1, [
		{"unit_id": "u_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD},
		{"unit_id": "u_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER},
		{"unit_id": "u_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
		{"unit_id": "u_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
	])
	model.bind(tm, uim, usm)

	# 1. Enter Prepare Time (timing-system/02):
	#    Energy set to exactly 10, board frozen, unit next_action_turns initialized to 4, 4, 3, 6,
	#    and cycle tags placed at turns 3, 4, 6, 8, 9, 12 (slots 16, 15, 13, 11, 10, 7) + next cycle (slots 4, 3, 1)
	assert_true(tm.enter_prepare(), "TimingManager enters Prepare Time")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PREPARE, "Active timing is Prepare Time")
	var state: Dictionary = model.get_state()
	assert_true(is_equal_approx(float(state.get("energy", 0.0)), 10.0), "Prepare Time sets Energy to 10.0")
	assert_true(bool(state.get("frozen", false)), "TimeBoardModel is frozen during Prepare Time")

	# Advancing time during Prepare Time does NOT charge Energy or move tags
	tm.advance_time(2.5)
	state = model.get_state()
	assert_true(is_equal_approx(float(state.get("energy", 0.0)), 10.0), "Energy does not regenerate during Prepare Time")
	assert_true(is_equal_approx(float(state.get("charge", 1.0)), 0.0), "Charge progress stays 0 during Prepare Time")

	# Verify per-unit Action Countdown on UnitInformationDO (time-board-display/03)
	assert_eq(uim.get_unit("u_scout").next_action_turns, 3, "Scout initial Action Countdown is 3")
	assert_eq(uim.get_unit("u_guard").next_action_turns, 4, "Guard initial Action Countdown is 4")
	assert_eq(uim.get_unit("u_brawler").next_action_turns, 4, "Brawler initial Action Countdown is 4")
	assert_eq(uim.get_unit("u_acolyte").next_action_turns, 6, "Acolyte initial Action Countdown is 6")

	# Verify cycle Action Tags at turns 3, 4, 6, 8, 9, 12 from goal (slot = 19 - turns):
	#   turns=3  (slot 16): Scout (1)
	#   turns=4  (slot 15): Guard + Brawler (2)
	#   turns=6  (slot 13): Scout + Acolyte (2)
	#   turns=8  (slot 11): Guard + Brawler (2)
	#   turns=9  (slot 10): Scout (1)
	#   turns=12 (slot 7):  Guard + Brawler + Scout + Acolyte (4), is_cycle_12 = true
	var tags: Dictionary = state.get("tags", {})
	assert_true(tags.has(16), "Cycle tag exists at 3 turns (slot 16)")
	assert_eq(int(tags.get(16, {}).get("count", -1)), 1, "Turn 3 tag has count 1 (Scout)")
	assert_false(bool(tags.get(16, {}).get("is_cycle_12", true)), "Turn 3 tag is not a 12-interval tag")

	assert_true(tags.has(15), "Cycle tag exists at 4 turns (slot 15)")
	assert_eq(int(tags.get(15, {}).get("count", -1)), 2, "Turn 4 tag has count 2 (Guard + Brawler)")

	assert_true(tags.has(13), "Cycle tag exists at 6 turns (slot 13)")
	assert_eq(int(tags.get(13, {}).get("count", -1)), 2, "Turn 6 tag has count 2 (Scout + Acolyte)")

	assert_true(tags.has(11), "Cycle tag exists at 8 turns (slot 11)")
	assert_eq(int(tags.get(11, {}).get("count", -1)), 2, "Turn 8 tag has count 2 (Guard + Brawler)")

	assert_true(tags.has(10), "Cycle tag exists at 9 turns (slot 10)")
	assert_eq(int(tags.get(10, {}).get("count", -1)), 1, "Turn 9 tag has count 1 (Scout)")

	assert_true(tags.has(7), "Cycle tag exists at 12 turns (slot 7)")
	assert_eq(int(tags.get(7, {}).get("count", -1)), 4, "Turn 12 tag has count 4 (all 4 adventurers act together)")
	assert_true(bool(tags.get(7, {}).get("is_cycle_12", false)), "Turn 12 tag is flagged is_cycle_12 = true for special highlight")

	tree.root.remove_child(usm)
	tree.root.remove_child(uim)
	tree.root.remove_child(tm)
	usm.free()
	uim.free()
	tm.free()


func test_zero_count_tag_skips_action_time_pocketed_keeps_count_and_turn_12_resets_hit_level() -> void:
	if not ResourceLoader.exists(TIME_BOARD_MODEL_PATH):
		return
	var tree := Engine.get_main_loop() as SceneTree
	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var model = load(TIME_BOARD_MODEL_PATH).new()
	tree.root.add_child(tm)
	tree.root.add_child(uim)
	tree.root.add_child(usm)
	usm.bind_unit_information_manager(uim)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "power": 400})
	# Register ONLY Guard (cd=4) and Acolyte (cd=6) — NO Scout (cd=3)!
	# That way, cycle turns 3 and 9 have 0 acting adventurers!
	uim.register_adventurer_team(1, [
		{"unit_id": "u_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD},
		{"unit_id": "u_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
	])
	model.bind(tm, uim, usm)
	tm.enter_prepare()
	tm.start_charging()

	# 1. Verify Turn 3 tag exists even with count == 0!
	var tags: Dictionary = model.get_state().get("tags", {})
	assert_true(tags.has(16), "Turn 3 cycle tag exists at slot 16 even when no Scout is in the wave")
	assert_eq(int(tags.get(16, {}).get("count", -1)), 0, "Turn 3 cycle tag has count 0")

	# 2. Pocket Guard before Turn 3 -> pocketed non-defeated unit keeps its Action Tag count (+1 at 4, 8, 12) unchanged!
	uim.set_unit_pocketed("u_guard", true)
	model.refresh_tags()
	tags = model.get_state().get("tags", {})
	assert_eq(int(tags.get(15, {}).get("count", -1)), 1, "Pocketed Guard still contributes +1 to Turn 4 tag")
	assert_eq(int(tags.get(7, {}).get("count", -1)), 2, "Pocketed Guard still contributes +1 to Turn 12 tag (Guard + Acolyte = 2)")

	# 3. Complete Turn 1, Turn 2, Turn 3:
	#    At Turn 3, the 0-count tag reaches the goal (slot 19) -> clears immediately WITHOUT entering Action Time!
	tm.complete_charge_slot() # Turn 1
	assert_eq(uim.get_unit("u_guard").next_action_turns, 3, "Guard Action Countdown decremented to 3 after Turn 1")
	assert_eq(usm.get_unit_attack_skill("u_guard").current_countdown, 8, "Guard Lance Skill Countdown ticked from 9 to 8 on Turn 1 (even while pocketed)")
	tm.complete_charge_slot() # Turn 2
	tm.complete_charge_slot() # Turn 3 (0-count cycle tag arrives at goal)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "0-count cycle tag at Turn 3 clears at goal without entering Action Time")
	assert_false(model.get_state().get("tags", {}).has(19), "0-count tag was removed at the goal slot")

	# 4. Complete Turn 4:
	#    At Turn 4, Guard's tag (count = 1) reaches the goal -> triggers Action Time!
	#    While Guard's tag stands at the goal (slot 19, turns = 0), its next-cycle replacement
	#    must NOT have appeared at turns = 12 (slot 7) yet!
	tm.complete_charge_slot() # Turn 4
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_ACTION, "Turn 4 tag with count 1 triggers Action Time")
	assert_eq(uim.get_unit("u_guard").next_action_turns, 0, "Guard Action Countdown reached 0 at Turn 4")
	assert_eq(model.get_cycle_tags().size(), 6, "Model always maintains a fixed list of 6 persistent cycle tags")
	assert_true(model.get_state().get("tags", {}).has(19), "Firing tag stands at the goal slot (19) during Action Time")
	assert_false(model.get_state().get("tags", {}).has(7), "Next-cycle replacement has NOT appeared at turns=12 while the tag still stands at the goal")

	uim.modify_hit_level("u_guard", 2)
	uim.push_damage("u_guard", 100.0, "boss_a", "boss_a", "collision")
	tm.record_settle_event({"type": "action_time_damage"})
	tm.notify_actions_finished()
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_SETTLE, "Enters Settle Time after Turn 4 Action Time")
	model.on_settle_time_resolved()
	tm.notify_settle_finished()

	assert_false(model.get_state().get("tags", {}).has(19), "Goal tag disappears after Settle Time")
	assert_true(model.get_state().get("tags", {}).has(7), "Only after disappearing from the goal does the tag reset to turns=12 (ready to glide into slot 11 on the next Turn)")
	assert_eq(uim.get_unit("u_guard").hit_level, 2, "Hit Level (2) PERSISTS after Turn 4 Settle Time (only resets at Turn 12)")
	assert_eq(uim.get_unit("u_guard").next_action_turns, 4, "Acted Guard resets its personal Action Countdown to 4 at end of Settle Time")

	# 5. Advance through Turn 5..12 (completing any triggered Action/Settle along the way) ->
	#    After Turn 12's Settle Time, Hit Level resets to 0 on all units!
	for turn_num in range(5, 13):
		tm.complete_charge_slot()
		if tm.get_current_timing() == TimingManager.TIMING_ACTION:
			tm.record_settle_event({"type": "turn_%d" % turn_num})
			tm.notify_actions_finished()
			if tm.get_current_timing() == TimingManager.TIMING_SETTLE:
				model.on_settle_time_resolved()
				tm.notify_settle_finished()

	assert_eq(uim.get_unit("u_guard").hit_level, 0, "Hit Level resets to 0 after Turn 12's Settle Time (end of 12-turn cycle)")

	# 6. Defeat Acolyte in Settle Time -> future Turn 6 and Turn 12 tag counts decrement by 1!
	uim.push_damage("u_acolyte", 99999.0, "boss_a", "boss_a", "collision")
	model.on_settle_time_resolved()
	assert_true(uim.get_unit("u_acolyte").is_dead, "Acolyte is defeated")
	tags = model.get_state().get("tags", {})
	assert_eq(int(tags.get(13, {}).get("count", -1)), 0, "After Acolyte is defeated, Turn 6 tag (slot 13) count drops to 0 (arrow remains)")
	assert_eq(int(tags.get(7, {}).get("count", -1)), 1, "After Acolyte is defeated, Turn 12 tag (slot 7) count drops from 2 to 1 (Guard only)")

	tree.root.remove_child(usm)
	tree.root.remove_child(uim)
	tree.root.remove_child(tm)
	usm.free()
	uim.free()
	tm.free()


func test_time_board_view_upper_bar_count_circle_zero_count_hiding_and_12_cycle_highlight() -> void:
	var packed := ResourceLoader.load(TIME_BOARD_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "TimeBoard scene loads")
	if packed == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	var board: TimeBoard = packed.instantiate()
	tree.root.add_child(board)

	# 1. Verify 11-slot upper bar (10 Energy slots + 1 empty extension slot), 6 persistent tag nodes,
	#    and 2nd player's secondary bar positioned BELOW LowerBar
	assert_eq(board.get_upper_slot_count(), 11, "Upper bar has 11 slots (10 Energy slots + 1 always-empty extension slot; 12th slot removed)")
	assert_eq(board.get_cycle_tag_node_count(), 6, "TimeBoard uses a fixed list of 6 persistent tag nodes")
	assert_true(board.is_secondary_bar_below_lower_bar(), "Second player's bar (SecondaryBarBox) is positioned below LowerBar")

	# 2. Render a state with 6 tags:
	# - Goal slot 19 (0 turns, stopped at goal): lifted up (`is_lifted_at_goal == true`)
	# - Upper bar tag at slot 16 (3 turns, cycle_step=3) with count = 0 -> count circle HIDDEN
	# - Upper bar tag at slot 15 (4 turns, cycle_step=4) with count = 2 -> light_blue, count circle visible
	# - Upper bar tag at slot 13 (6 turns, cycle_step=6) with count = 2 -> light_red, count circle visible
	# - Upper bar tag at slot 11 (8 turns, cycle_step=8) with count = 2 -> light_blue, count circle visible
	# - Upper bar tag at slot 8  (11 turns, cycle_step=12) with count = 4 -> light_purple, +20% larger (scale_mult = 1.2), visible at slot 11!
	board.render_state({
		"energy": 10.0,
		"charge": 0.0,
		"tags": {
			19: {"count": 1, "turns": 0, "cycle_step": 9},
			16: {"count": 0, "turns": 3, "cycle_step": 3},
			15: {"count": 2, "turns": 4, "cycle_step": 4},
			13: {"count": 2, "turns": 6, "cycle_step": 6},
			11: {"count": 2, "turns": 8, "cycle_step": 8},
			8: {"count": 4, "turns": 11, "cycle_step": 12, "is_cycle_12": true},
		},
	})

	var info_19 := board.tag_info(19)
	assert_true(bool(info_19.get("is_lifted_at_goal", false)), "Tag standing at the goal (slot 19) is lifted up to highlight it")

	var info_15 := board.tag_info(15)
	assert_true(bool(info_15.get("count_circle_visible", false)), "Upper-bar tag with count > 0 displays the count circle")
	assert_false(bool(info_15.get("turns_label_visible", true)), "Time Board tag does not display a redundant turns-to-goal integer")
	assert_eq(str(info_15.get("highlight_kind", "")), "light_blue", "4th tag is highlighted with light blue")

	var info_13 := board.tag_info(13)
	assert_eq(str(info_13.get("highlight_kind", "")), "light_red", "6th tag is highlighted with light red")

	var info_16 := board.tag_info(16)
	assert_false(bool(info_16.get("count_circle_visible", true)), "Upper-bar tag with count == 0 hides the count circle and number")

	var info_11 := board.tag_info(11)
	assert_true(bool(info_11.get("count_circle_visible", false)), "8th tag with count > 0 displays the count circle")
	assert_eq(str(info_11.get("highlight_kind", "")), "light_blue", "8th tag is highlighted with light blue")

	var info_8 := board.tag_info(8)
	assert_true(bool(info_8.get("visible_on_board", false)), "Tag at 11 turns (slot 8, right edge of 11th slot) is visible on the upper bar")
	assert_true(bool(info_8.get("count_circle_visible", false)), "12th cycle tag displays its count circle")
	assert_eq(str(info_8.get("highlight_kind", "")), "light_purple", "12th tag is highlighted with light purple (red + blue)")
	assert_true(is_equal_approx(float(info_8.get("scale_mult", 1.0)), 1.2), "12th tag is 20% larger than other tags")

	# 3. Verify that:
	#    (a) A tag at turns=12 (slot 7) is hidden off-bar, and when the next Turn advances it to turns=11 (slot 8),
	#        it GLIDES IN smoothly to slot 11!
	#    (b) A tag advancing from turns=1 (slot 18) to turns=0 (slot 19, the Goal) starts at y = 0.0 (NOT lifted while gliding)
	#        and only lifts up after stopping at the goal!
	#    (c) Adjacent tags (e.g. turns 4 & 3 at slots 15 & 16) both glide independently via the 6 persistent tag nodes!
	board.render_state({
		"energy": 10.0,
		"charge": 0.0,
		"tags": {
			18: {"count": 1, "turns": 1, "cycle_step": 3},
			15: {"count": 2, "turns": 4, "cycle_step": 4},
			13: {"count": 2, "turns": 6, "cycle_step": 6},
			11: {"count": 2, "turns": 8, "cycle_step": 8},
			10: {"count": 1, "turns": 9, "cycle_step": 9},
			7: {"count": 4, "turns": 12, "cycle_step": 12, "is_cycle_12": true},
		},
	})
	assert_false(bool(board.tag_info(7).get("visible_on_board", true)), "Tag at turns=12 (slot 7) is waiting off-bar before gliding into slot 11")

	board.apply_state({
		"energy": 11.0,
		"charge": 0.0,
		"tags": {
			19: {"count": 1, "turns": 0, "cycle_step": 3},
			16: {"count": 2, "turns": 3, "cycle_step": 4},
			14: {"count": 2, "turns": 5, "cycle_step": 6},
			12: {"count": 2, "turns": 7, "cycle_step": 8},
			11: {"count": 1, "turns": 8, "cycle_step": 9},
			8: {"count": 4, "turns": 11, "cycle_step": 12, "is_cycle_12": true},
		},
	})
	assert_true(board.is_tag_gliding_at_slot(19), "Tag arriving at goal (18->19) is gliding")
	assert_true(is_equal_approx(float(board.tag_info(19).get("mover_y", -99.0)), 0.0),
		"Tag gliding into goal (18->19) stays at y=0.0 while moving and only lifts up after stopping at goal")
	assert_true(board.is_tag_gliding_at_slot(8), "Replacement tag (turns 12->11, slot 7->8) glides in smoothly to slot 11")
	assert_true(board.is_tag_gliding_at_slot(12), "Tag 11->12 glides smoothly")
	assert_true(board.is_tag_gliding_at_slot(11), "Adjacent trailing tag 10->11 ALSO glides smoothly without depending on slot 11's previous occupant")

	# Per-frame charge progress update while tags are unchanged must NOT kill the running tag tweens!
	board.apply_state({
		"energy": 11.0,
		"charge": 0.25,
		"tags": {
			19: {"count": 1, "turns": 0, "cycle_step": 3},
			16: {"count": 2, "turns": 3, "cycle_step": 4},
			14: {"count": 2, "turns": 5, "cycle_step": 6},
			12: {"count": 2, "turns": 7, "cycle_step": 8},
			11: {"count": 1, "turns": 8, "cycle_step": 9},
			8: {"count": 4, "turns": 11, "cycle_step": 12, "is_cycle_12": true},
		},
	})
	assert_true(board.is_tag_gliding_at_slot(8), "Per-frame charge update preserves in-flight glide-in tween at slot 11 (index 8)")
	assert_true(board.is_tag_gliding_at_slot(11), "Per-frame charge update preserves in-flight glide tween on slot 11")

	tree.root.remove_child(board)
	board.free()
