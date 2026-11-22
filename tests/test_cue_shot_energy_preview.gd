extends McpTestSuite

## Tests for CueShotManager (ticket 01 of cue-shot-energy):
## - Drag-to-shot is ONLY available during Play Time (gated via TimingManager signals)
## - Drag distance quantizes required Energy to 1.0..9.0 in 0.5-slot steps
## - Live drag updates TimeBoard preview_cost (bottom-left consume preview + red over-drag)
## - Releasing inside deadzone or while over-dragged cancels without spending Energy and stays in Play Time
## - Releasing a valid affordable drag spends the half-slot Energy and transitions to Puck-puck Time!

var _root: Node3D = null
var _tm: TimingManager = null
var _board: TimeBoard = null
var _boss: Node3D = null
var _cue_mgr: CueShotManager = null


func suite_name() -> String:
	return "cue-shot-energy-preview"


func setup() -> void:
	_root = Node3D.new()
	_tm = TimingManager.new()
	_tm.name = "TimingManager"
	_root.add_child(_tm)

	var packed_board := ResourceLoader.load("res://src/canvas/time_board.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	_board = packed_board.instantiate()
	_root.add_child(_board)

	_boss = Node3D.new()
	_boss.name = "Player"
	_root.add_child(_boss)

	_cue_mgr = CueShotManager.new()
	_cue_mgr.name = "CueShotManager"
	_cue_mgr.timing_manager = _tm
	_cue_mgr.time_board = _board
	_cue_mgr.boss_puck = _boss
	_root.add_child(_cue_mgr)

	(Engine.get_main_loop() as SceneTree).root.add_child(_root)
	_boss.global_position = Vector3(0.0, 1.75, 0.0)
	_tm.energy_changed.connect(func(e: float, c: float) -> void:
		_board.render_state({"energy": e, "charge": c, "preview_cost": _board.get_preview_cost(), "tags": {}})
	)


func teardown() -> void:
	if is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_tm = null
	_board = null
	_boss = null
	_cue_mgr = null


func test_drag_to_shot_is_blocked_outside_play_time() -> void:
	_tm.set_energy(10.0)
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Starts in Charging Time")
	assert_false(_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0)), "Cannot begin drag in Charging Time")
	assert_false(_cue_mgr.is_dragging(), "Not dragging in Charging Time")

	# Enter Action Time -> still blocked
	_tm.enter_action_time()
	assert_false(_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0)), "Cannot begin drag in Action Time")
	_tm.notify_actions_finished()

	# Enter Play Time -> allowed
	_tm.request_play()
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PLAY, "In Play Time")
	assert_true(_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0)), "Can begin drag in Play Time")
	assert_true(_cue_mgr.is_dragging(), "Dragging active in Play Time")

	# Pausing during Play Time cancels active drag and blocks new drags
	_tm.pause()
	assert_false(_cue_mgr.is_dragging(), "Pausing cancels active drag")
	assert_eq(_board.get_preview_cost(), 0.0, "Preview cleared on pause")
	assert_false(_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0)), "Cannot begin drag while paused")
	_tm.resume()


func test_drag_quantizes_energy_in_half_slot_steps_and_updates_time_board_preview() -> void:
	_tm.set_energy(5.5)
	_tm.request_play()
	_cue_mgr.deadzone_radius = 0.6
	_cue_mgr.drag_distance_per_energy = 1.0

	assert_true(_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0)), "Start drag on boss at origin")

	# Drag inside deadzone (distance 0.4 <= 0.6) -> preview_cost = 0.0, in_deadzone = true
	_cue_mgr.update_drag(Vector3(0.4, 1.5, 0.0))
	assert_true(_cue_mgr.is_in_deadzone(), "Inside deadzone at 0.4")
	assert_eq(_cue_mgr.get_required_energy(), 0.0, "0 required energy inside deadzone")
	assert_eq(_board.get_preview_cost(), 0.0, "TimeBoard preview_cost is 0 inside deadzone")

	# Just outside deadzone (distance 0.7 -> 0.1 past deadzone -> minimum 1.0)
	_cue_mgr.update_drag(Vector3(0.7, 1.5, 0.0))
	assert_false(_cue_mgr.is_in_deadzone(), "Outside deadzone at 0.7")
	assert_eq(_cue_mgr.get_required_energy(), 1.0, "Minimum shot cost is 1.0")
	assert_eq(_cue_mgr.get_shot_direction(), Vector3(-1.0, 0.0, 0.0), "Shot direction is opposite drag direction")
	assert_eq(_board.slot_consume_ratio(0), 1.0, "TimeBoard slot 0 highlighted in consume preview")

	# Drag for 2.5 energy (0.6 deadzone + 1.5 = 2.1 distance -> 1.0 + 1.5 = 2.5 energy)
	_cue_mgr.update_drag(Vector3(2.1, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 2.5, "Quantized to 2.5 energy")
	assert_eq(_board.slot_consume_ratio(0), 1.0, "Slot 0 full consume preview")
	assert_eq(_board.slot_consume_ratio(1), 1.0, "Slot 1 full consume preview")
	assert_eq(_board.slot_consume_ratio(2), 0.5, "Slot 2 half consume preview")
	assert_eq(_board.slot_overdrag_ratio(2), 0.0, "No overdrag when 2.5 <= 5.5 owned energy")

	# Over-drag for 7.5 energy (0.6 + 6.5 = 7.1 distance -> 7.5 > 5.5 owned energy)
	_cue_mgr.update_drag(Vector3(7.1, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 7.5, "Quantized to 7.5 energy")
	assert_true(_cue_mgr.is_overdragged(), "Marked over-dragged when 7.5 > 5.5")
	assert_eq(_board.slot_consume_ratio(5), 0.5, "Slot 5 first half is consume preview (up to 5.5 owned)")
	assert_eq(_board.slot_overdrag_ratio(5), 0.5, "Slot 5 second half is red overdrag")
	assert_eq(_board.slot_overdrag_ratio(6), 1.0, "Slot 6 is full red overdrag")
	assert_eq(_board.slot_overdrag_ratio(7), 0.5, "Slot 7 first half is red overdrag (up to 7.5)")

	# Cap at 9.0 maximum shot cost
	_cue_mgr.update_drag(Vector3(20.0, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 9.0, "Shot cost caps at 9.0")

	# Player B seat energy check: when Player A has 1.0 Energy but Player B has 6.0 Energy,
	# a drag costing 3.5 Energy is NOT over-dragged when aiming as Player B ("b")
	_cue_mgr.cancel_drag(false)
	_tm.set_energy(1.0)
	_tm.set_energy_b(6.0)
	_board.set_perspective_role("b")
	_board.render_state({"has_player_b": true, "energy_a": 1.0, "energy_b": 6.0, "charge": 0.0, "tags": {}})
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(3.1, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 3.5, "Selected 3.5 Energy")
	assert_false(_cue_mgr.is_overdragged(), "Not over-dragged for Player B who owns 6.0 Energy (even though Player A has 1.0)")
	assert_false(_cue_mgr.get_aim_line_state().get("is_invalid_red", true), "Aiming line is valid colour for Player B")
	_board.set_perspective_role("a")


func test_release_in_deadzone_or_overdrag_cancels_while_valid_release_spends_energy_and_enters_puck_puck() -> void:
	_tm.set_energy(5.0)
	_tm.request_play()
	_cue_mgr.deadzone_radius = 0.6
	_cue_mgr.drag_distance_per_energy = 1.0

	# 1. Release inside deadzone -> cancels, stays in Play Time, spends 0
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(0.3, 1.5, 0.0))
	assert_false(_cue_mgr.release_drag(), "Releasing in deadzone cancels the shot")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PLAY, "Stays in Play Time after deadzone cancel")
	assert_eq(_tm.get_energy(), 5.0, "No Energy spent on deadzone cancel")
	assert_eq(_board.get_preview_cost(), 0.0, "Preview cleared on cancel")

	# 2. Release while over-dragged (cost 6.5 > 5.0) -> cancels, stays in Play Time, spends 0
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(6.1, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 6.5, "Selected 6.5 > 5.0 owned")
	assert_false(_cue_mgr.release_drag(), "Releasing while over-dragged cancels the shot")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PLAY, "Stays in Play Time after over-drag cancel")
	assert_eq(_tm.get_energy(), 5.0, "No Energy spent on over-drag cancel")
	assert_eq(_board.get_preview_cost(), 0.0, "Preview cleared on over-drag cancel")

	# 3. Release valid drag (cost 3.5 <= 5.0) -> spends 3.5 (leaving 1.5) and transitions to Puck-puck Time!
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(3.1, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 3.5, "Selected affordable 3.5 Energy")
	assert_true(_cue_mgr.release_drag(), "Valid release launches shot")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Transitions to Puck-puck Time!")
	assert_eq(_tm.get_energy(), 1.5, "Half-slot Energy (5.0 - 3.5 = 1.5) remaining")
	assert_eq(_board.get_preview_cost(), 0.0, "Preview cleared after shot launch")
	assert_eq(_board.slot_fill_ratio(0), 1.0, "Slot 0 remains filled")
	assert_eq(_board.slot_fill_ratio(1), 0.5, "Slot 1 shows remaining 0.5 Energy")
	assert_eq(_board.slot_fill_ratio(2), 0.0, "Slot 2 is now empty")


func test_demo_battlefield_mounts_cue_shot_manager_and_wires_play_time_energy_preview() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	var packed := ResourceLoader.load("res://src/demo_bettlefield.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Battlefield scene loads")
	if packed == null:
		return
	var bf := packed.instantiate()
	tree.root.add_child(bf)

	var csm: CueShotManager = bf.cue_shot_manager
	var pvm: PuckVelocityManager = bf.puck_velocity_manager
	var tm: TimingManager = bf.timing_manager
	var tb: TimeBoard = bf.time_board
	var boss: BasePuck = bf.get_node("Player") as BasePuck
	assert_true(csm != null, "Battlefield scene mounts CueShotManager")
	assert_true(pvm != null, "Battlefield scene mounts PuckVelocityManager")
	assert_eq(tm.get_energy(), 15.0, "Demo battlefield starts with 15.0 Energy")

	tm.set_energy(4.0)
	assert_false(csm.begin_drag(Vector3(0.0, 1.5, 0.0)), "Cannot drag in Charging Time")

	bf.play_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PLAY, "In Play Time")
	assert_true(csm.begin_drag(Vector3(0.0, 1.5, 0.0)), "Can drag in Play Time")
	csm.update_drag(Vector3(2.65, 1.5, 0.0))
	assert_eq(csm.get_required_energy(), 3.0, "Drag selects 3.0 Energy")
	assert_eq(tb.slot_consume_ratio(0), 1.0, "TimeBoard highlights slot 0")
	assert_eq(tb.slot_consume_ratio(2), 1.0, "TimeBoard highlights up to slot 2")
	assert_true(csm.release_drag(), "Release launches Cue-Shot")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Entered Puck-puck Time!")
	assert_eq(tm.get_energy(), 1.0, "Remaining Energy is 1.0")
	assert_true(boss.velocity.x < -5.5, "Boss Monster launched with impulse velocity along -X")

	# Step PuckVelocityManager until Boss Monster decelerates to rest -> returns to Charging Time
	for _i in range(130):
		pvm.step_positions(0.05)
		pvm.step_velocities(0.05)
	assert_true(boss.velocity.is_zero_approx(), "Boss Monster decelerated to rest")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Returns to Charging Time when Boss Monster comes to rest")

	# Charge next slot, enter Play Time again, and verify we can drag-to-shot a second time from the Boss Monster's new position
	tm.complete_charge_slot()
	bf.play_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PLAY, "Entered Play Time for 2nd shot")
	var new_boss_pos := boss.global_position
	assert_true(csm.begin_drag(Vector3(new_boss_pos.x, 1.5, new_boss_pos.z)), "Can begin 2nd drag at Boss Monster's new position")
	csm.update_drag(Vector3(new_boss_pos.x - 1.5, 1.5, new_boss_pos.z))
	assert_eq(csm.get_required_energy(), 1.5, "2nd drag selects 1.5 Energy")
	assert_true(csm.release_drag(), "2nd shot launches")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Entered Puck-puck Time! for 2nd shot")
	assert_true(boss.velocity.x > 2.7, "Boss Monster launched along +X on 2nd shot")

	tree.root.remove_child(bf)
	bf.queue_free()
	tree.get_multiplayer().multiplayer_peer = null


# ----- Ticket 02: Puck mass/radius/impulse, TableBlock ground friction (-1.0 unit/sec^2), PuckVelocityManager (20 Hz), 3D aiming line & launch -----


func test_puck_mass_radius_and_table_block_ground_friction_deceleration() -> void:
	var puck := DragonPlayer.new()
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.8
	col.shape = cyl
	puck.add_child(col)
	_root.add_child(puck)

	assert_true(puck.is_in_group("pucks"), "BasePuck registers in the 'pucks' group")
	assert_true(is_equal_approx(puck.mass, 3.2), "Boss Monster default mass is 3.2")
	assert_true(is_equal_approx(puck.radius, 0.8), "Puck auto-detects radius from CylinderShape3D")

	# Mass-dependent impulse: J = 16 -> v_0 = 16 / 3.2 = 5.0 units/sec
	puck.apply_impulse(Vector3(16.0, 0.0, 0.0))
	assert_true(is_equal_approx(puck.velocity.x, 5.0), "apply_impulse divides impulse by mass (16 / 3.2 = 5.0)")

	# Standard grass TableBlock decelerates at -1.2 unit/sec^2 (5.0 -> 3.8 after 1.0s of 20 Hz ticks)
	var grass_block := TableBlock.new()
	grass_block.block_type = TableBlock.BlockType.GRASS_DARK
	_root.add_child(grass_block)
	assert_true(is_equal_approx(grass_block.base_deceleration, 1.2), "Default base_deceleration is 1.2 unit/sec^2")
	for _i in range(20):
		grass_block.apply_ground_effect(puck, 0.05, 1.0)
	assert_true(is_equal_approx(puck.velocity.x, 3.8), "5.0 units/sec slows to 3.8 units/sec after 1s at -1.2 unit/sec^2")

	# Decelerate the remaining time -> clamps cleanly to Vector3.ZERO without reversing direction
	for _i in range(90):
		grass_block.apply_ground_effect(puck, 0.05, 1.0)
	assert_eq(puck.velocity, Vector3.ZERO, "Friction clamps velocity to Vector3.ZERO and never reverses direction")

	# Block-type friction scaling: MUD (2.0) decelerates faster than ICE (0.2)
	var mud_block := TableBlock.new()
	mud_block.block_type = TableBlock.BlockType.MUD
	var ice_block := TableBlock.new()
	ice_block.block_type = TableBlock.BlockType.ICE
	puck.velocity = Vector3(5.0, 0.0, 0.0)
	var mud_dv := mud_block.calculate_ground_velocity_delta(puck, 0.5)
	var ice_dv := ice_block.calculate_ground_velocity_delta(puck, 0.5)
	assert_true(is_equal_approx(mud_dv.x, -1.2), "MUD (2.0 factor * 1.2 base * 0.5s) reduces speed by 1.2")
	assert_true(is_equal_approx(ice_dv.x, -0.12), "ICE (0.2 factor * 1.2 base * 0.5s) reduces speed by 0.12")
	mud_block.free()
	ice_block.free()


func test_puck_velocity_manager_steps_positions_and_20hz_ground_friction_to_rest() -> void:
	var packed_table := ResourceLoader.load("res://src/battlefield/cue_table.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var table := packed_table.instantiate() as Battlefield
	_root.add_child(table)

	var puck := DragonPlayer.new()
	_root.add_child(puck)
	puck.global_position = Vector3(0.0, 1.75, 0.0)

	var pvm := PuckVelocityManager.new()
	pvm.battlefield = table
	pvm.timing_manager = _tm
	_root.add_child(pvm)

	assert_eq(PuckVelocityManager.TICK_INTERVAL, 0.05, "20 Hz velocity update interval is 0.05s")
	assert_true(pvm.are_all_pucks_at_rest(), "Puck starts at rest")

	# Launch with speed 2.4 units/sec along +X in Puck-puck Time!
	_tm.set_energy(5.0)
	_tm.request_play()
	_tm.fire_cue_shot(1.0)
	puck.velocity = Vector3(2.4, 0.0, 0.0)
	assert_false(pvm.are_all_pucks_at_rest(), "Puck is moving after launch")

	# Step 1.0s via 20 frames of 0.05s -> speed drops from 2.4 to 1.2, position advances along +X
	for _i in range(20):
		pvm.step_positions(0.05, 1.0)
		pvm.step_velocities(0.05, 1.0)
	assert_true(is_equal_approx(puck.velocity.x, 1.2), "Speed after 1.0s on grass is 1.2 unit/sec")
	assert_true(puck.global_position.x > 1.7 and puck.global_position.x < 1.9, "Position advanced ~1.8 units in 1.0s")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Still in Puck-puck Time! while moving")

	# Step remaining 1.0s -> speed reaches 0.0, all_pucks_at_rest triggers transition back to Charging Time
	for _i in range(20):
		pvm.step_positions(0.05, 1.0)
		pvm.step_velocities(0.05, 1.0)
	assert_true(puck.velocity.is_zero_approx(), "Puck decelerated to rest after 2.0s")
	assert_true(pvm.are_all_pucks_at_rest(), "All pucks are at rest")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Automatically transitions out of Puck-puck Time! when at rest")

	# Verify apply_force and calculate_position adopt fast_play_ratio (e.g. x2.0)
	puck.global_position = Vector3(0.0, 1.75, 0.0)
	puck.velocity = Vector3.ZERO
	pvm.apply_impulse_to_puck(puck, Vector3(2.4 * puck.mass, 0.0, 0.0))
	assert_true(is_equal_approx(puck.velocity.x, 2.4), "apply_impulse_to_puck sets v = J / m = 2.4")

	# At fast_play_ratio = 2.0: 0.5s of wall time (10 ticks of 0.05s) advances the same distance and deceleration as 1.0s at x1.0
	for _i in range(10):
		pvm.calculate_puck_position(puck, 0.05, 2.0)
		pvm.apply_force_to_puck(puck, Vector3(-1.2 * puck.mass, 0.0, 0.0), 0.05, 2.0)
	assert_true(is_equal_approx(puck.velocity.x, 1.2), "At x2.0 fast play, 10 ticks of 0.05s decelerates from 2.4 to 1.2")
	assert_true(puck.global_position.x > 1.7 and puck.global_position.x < 1.9, "At x2.0 fast play, 10 ticks of 0.05s advances ~1.8 units")


func test_aiming_line_at_y_1_55_red_on_deadzone_or_overdrag_and_mass_dependent_impulse_launch() -> void:
	var boss := DragonPlayer.new()
	boss.name = "BossTest"
	_root.add_child(boss)
	boss.global_position = Vector3(0.0, 1.75, 0.0)
	_cue_mgr.boss_puck = boss
	_cue_mgr.deadzone_radius = 0.6
	_cue_mgr.drag_distance_per_energy = 1.0
	_cue_mgr.impulse_per_energy = 6.0
	_cue_mgr.aim_length_per_impulse = 0.5

	_tm.set_energy(4.0)
	_tm.request_play()

	# Start drag and move inside deadzone -> aiming line is visible at Y = 1.55 and coloured red
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(0.3, 1.5, 0.0))
	var state_dz := _cue_mgr.get_aim_line_state()
	assert_true(state_dz.get("visible", false), "Aiming line visible during drag")
	assert_true(is_equal_approx(float(state_dz.get("y", 0.0)), 1.55), "Aiming line renders at Y = 1.55")
	assert_true(state_dz.get("is_invalid_red", false), "Aiming line turns red inside cancel deadzone")

	# Valid drag for E = 2.0 (distance 1.6 -> J = 6.0 * 2.0 = 12.0 -> length = 12.0 * 0.5 = 6.0)
	_cue_mgr.update_drag(Vector3(-1.6, 1.5, 0.0))
	var state_valid := _cue_mgr.get_aim_line_state()
	assert_false(state_valid.get("is_invalid_red", true), "Aiming line is valid colour when affordable and outside deadzone")
	assert_true(is_equal_approx(float(state_valid.get("impulse", 0.0)), 12.0), "Impulse J = k * E = 12.0")
	assert_true(is_equal_approx(float(state_valid.get("length", 0.0)), 6.0), "Aiming line length proportional to Impulse (12.0 * 0.5 = 6.0)")

	# Over-drag for E = 5.0 (> 4.0 owned) -> aiming line turns red and release plays cancel sound
	_cue_mgr.update_drag(Vector3(-4.6, 1.5, 0.0))
	var state_over := _cue_mgr.get_aim_line_state()
	assert_true(state_over.get("is_invalid_red", false), "Aiming line turns red when over-dragged")
	assert_false(_cue_mgr.release_drag(), "Over-drag release cancels")
	assert_eq(_cue_mgr.cancel_sound_play_count, 1, "Cancellation sound played on cancelled release")
	assert_false(_cue_mgr.get_aim_line_state().get("visible", true), "Aiming line hides after release")

	# Mass-dependent launch speed: E = 3.0 -> J = 18.0 -> for mass 3.0, v_0 = 6.0; for mass 6.0, v_0 = 3.0
	boss.mass = 3.0
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(-2.6, 1.5, 0.0))
	assert_eq(_cue_mgr.get_required_energy(), 3.0, "Selected 3.0 Energy")
	assert_true(_cue_mgr.release_drag(), "Valid release launches Boss Monster")
	assert_true(is_equal_approx(boss.velocity.x, 6.0), "Boss with mass 3.0 launches at v_0 = J / m = 18 / 3 = 6.0")

	# Reset to Play Time and test heavier Boss Monster (mass = 6.0 -> slower launch speed v_0 = 18 / 6 = 3.0)
	boss.velocity = Vector3.ZERO
	boss.global_position = Vector3(0.0, 1.75, 0.0)
	boss.mass = 6.0
	_tm.notify_all_pucks_at_rest()
	_tm.complete_charge_slot()
	_tm.set_energy(5.0)
	_tm.request_play()
	_cue_mgr.begin_drag(Vector3(0.0, 1.5, 0.0))
	_cue_mgr.update_drag(Vector3(-2.6, 1.5, 0.0))
	assert_true(_cue_mgr.release_drag(), "Valid release launches heavier Boss Monster")
	assert_true(is_equal_approx(boss.velocity.x, 3.0), "Heavier Boss (mass 6.0) starts slower at v_0 = 18 / 6 = 3.0 for same Impulse")


# ----- Ticket 03 (first 3 points): Default masses/radii per Puck type, 20 Hz swept/overlap check, and Puck-Puck 4-step classical impulse exchange -----


func test_default_relative_masses_and_radii_per_puck_type() -> void:
	var boss := DragonPlayer.new()
	var knight := EnemyAdventurer.new()
	knight.adventurer_class = EnemyAdventurer.AdventurerClass.GUARD
	var warrior := EnemyAdventurer.new()
	warrior.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	var ranger := EnemyAdventurer.new()
	ranger.adventurer_class = EnemyAdventurer.AdventurerClass.SCOUT
	var mage := EnemyAdventurer.new()
	mage.adventurer_class = EnemyAdventurer.AdventurerClass.ACOLYTE

	for p in [boss, knight, warrior, ranger, mage]:
		_root.add_child(p)

	assert_true(absf(boss.mass - 3.2) < 0.02, "Boss Monster mass is 3.2 (1.5 * (0.8/0.6)^2 * 1.2)")
	assert_true(absf(boss.radius - 0.8) < 0.001, "Boss Monster radius is 0.8")
	assert_true(absf(knight.mass - 1.5 * (0.65 * 0.65) / (0.6 * 0.6)) < 0.02, "Knight mass is ~1.75 (1.5 * (0.65/0.6)^2)")
	assert_true(absf(knight.radius - 0.65) < 0.001, "Knight radius is 0.65")
	assert_true(absf(warrior.mass - 1.5) < 0.02, "Warrior mass is 1.5")
	assert_true(absf(warrior.radius - 0.6) < 0.001, "Warrior radius is 0.6")
	assert_true(absf(ranger.mass - 1.5 * (0.57 * 0.57) / (0.6 * 0.6)) < 0.02, "Ranger mass is ~1.35 (1.5 * (0.57/0.6)^2)")
	assert_true(absf(ranger.radius - 0.57) < 0.001, "Ranger radius is 0.57")
	assert_true(absf(mage.mass - 1.5 * (0.55 * 0.55) / (0.6 * 0.6)) < 0.02, "Mage mass is ~1.25 (1.5 * (0.55/0.6)^2)")
	assert_true(absf(mage.radius - 0.55) < 0.001, "Mage radius is 0.55")


func test_puck_puck_collision_impulse_transfer_and_swept_20hz_check() -> void:
	var pvm := PuckVelocityManager.new()
	pvm.timing_manager = _tm
	_root.add_child(pvm)

	# 1. Head-on collision between Boss Monster (m1 = 3.0, v1 = 4.0) and stationary Mage (m2 = 1.0, v2 = 0.0), e = 0.8
	# Classical 4-step impulse:
	#   n = (-1, 0, 0) (from Mage at +X to Boss at origin), v_rel = (4 - 0) . (-1) = -4.0 < 0
	#   J = -(1 + 0.8) * (-4.0) / (1/3 + 1/1) = 7.2 / (4/3) = 5.4
	#   v1f = 4.0 - 5.4 / 3.0 = 2.2
	#   v2f = 0.0 + 5.4 / 1.0 = 5.4
	var boss := DragonPlayer.new()
	boss.restitution = 0.8
	var mage := EnemyAdventurer.new()
	mage.adventurer_class = EnemyAdventurer.AdventurerClass.MAGE
	mage.restitution = 0.8
	_root.add_child(boss)
	_root.add_child(mage)
	boss.mass = 3.0
	boss.radius = 0.75
	mage.mass = 1.0
	mage.radius = 0.45

	boss.global_position = Vector3(0.0, 1.75, 0.0)
	# Combined radius = 0.75 + 0.45 = 1.20. Place Mage at x = 1.15 (slight overlap / contact)
	mage.global_position = Vector3(1.15, 1.675, 0.0)
	boss.velocity = Vector3(4.0, 0.0, 0.0)
	mage.velocity = Vector3.ZERO

	assert_true(pvm.resolve_puck_puck_collision(boss, mage), "Approaching pucks resolve collision")
	assert_true(is_equal_approx(boss.velocity.x, 2.2), "Heavy Boss retains forward velocity v1f = 2.2")
	assert_true(is_equal_approx(mage.velocity.x, 5.4), "Light Mage is launched faster at v2f = 5.4")
	var dist_after := Vector2(boss.global_position.x - mage.global_position.x, boss.global_position.z - mage.global_position.z).length()
	assert_true(dist_after >= boss.radius + mage.radius - 0.001, "Positional overlap separated along collision normal")

	# 2. Separating pucks (v_rel >= 0) do NOT exchange impulse again
	assert_false(pvm.resolve_puck_puck_collision(boss, mage), "Separating pucks do not re-trigger impulse")

	# 3. Swept 20 Hz collision check during step_velocities: fast Boss hits Knight along its path within a 0.05s tick
	var knight := EnemyAdventurer.new()
	knight.adventurer_class = EnemyAdventurer.AdventurerClass.KNIGHT
	_root.add_child(knight)
	boss.global_position = Vector3(-5.0, 1.75, 0.0)
	boss.velocity = Vector3(10.0, 0.0, 0.0)
	# Combined radius = 0.75 + 0.6 = 1.35. Place Knight at x = -3.70 (within swept 0.05s * 10 = 0.5 reach)
	knight.global_position = Vector3(-3.70, 1.7, 0.0)
	knight.velocity = Vector3.ZERO

	pvm.step_positions(0.05, 1.0)
	pvm.step_velocities(0.05, 1.0)
	assert_true(knight.velocity.x > 5.0, "20 Hz swept/overlap check transfers momentum to Knight")
	assert_true(boss.velocity.x < 10.0, "Boss slows down after transferring momentum to Knight")

	# 4. Verify BaseEnemy._physics_process in Puck-puck Time! does NOT zero out knocked EnemyAdventurer velocity
	_tm.set_energy(5.0)
	_tm.request_play()
	_tm.fire_cue_shot(1.0)
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "In Puck-puck Time!")
	knight._physics_process(0.016)
	assert_true(knight.velocity.x > 5.0, "EnemyAdventurer keeps its collision velocity during Puck-puck Time! physics frames")
	pvm.step_positions(0.05, 1.0)
	assert_true(knight.global_position.x > -3.5, "Struck EnemyAdventurer is pushed away across the table")

	# 5. Simulate full demo_bettlefield.tscn 60 FPS _process loop where Boss Monster shoots into Enemy1 (Warrior at (6, 1.675, 3))
	var tree := Engine.get_main_loop() as SceneTree
	tree.get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	var packed := ResourceLoader.load("res://src/demo_bettlefield.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var bf := packed.instantiate()
	tree.root.add_child(bf)

	var bf_tm: TimingManager = bf.timing_manager
	var bf_csm: CueShotManager = bf.cue_shot_manager
	var bf_pvm: PuckVelocityManager = bf.puck_velocity_manager
	var bf_boss: BasePuck = bf.get_node("Player") as BasePuck
	var bf_enemy1: BasePuck = bf.get_node("Enemy1") as BasePuck

	var enemy1_start_pos := bf_enemy1.global_position
	bf_tm.set_energy(15.0)
	bf.play_button.emit_signal("pressed")

	# Aim directly from Boss (0, 0) toward Enemy1 (6, 3) -> drag opposite toward (-4, -2)
	var to_enemy := Vector3(enemy1_start_pos.x - bf_boss.global_position.x, 0.0, enemy1_start_pos.z - bf_boss.global_position.z).normalized()
	bf_csm.begin_drag(Vector3(0.0, 1.75, 0.0))
	bf_csm.update_drag(-to_enemy * 5.0 + Vector3(0.0, 1.5, 0.0))
	assert_true(bf_csm.release_drag(), "Shot launched toward Enemy1")

	var enemy1_max_speed := 0.0
	for _frame in range(60):
		bf_pvm._process(1.0 / 60.0)
		var spd := Vector2(bf_enemy1.velocity.x, bf_enemy1.velocity.z).length()
		if spd > enemy1_max_speed:
			enemy1_max_speed = spd

	var enemy1_moved_dist := Vector2(
		bf_enemy1.global_position.x - enemy1_start_pos.x,
		bf_enemy1.global_position.z - enemy1_start_pos.z
	).length()
	assert_true(enemy1_max_speed > 3.0, "Enemy1 gained high speed from Boss collision (got %.2f)" % enemy1_max_speed)
	assert_true(enemy1_moved_dist > 2.0, "Enemy1 was pushed away across the table (moved %.2f units)" % enemy1_moved_dist)
	var final_sep := Vector2(
		bf_boss.global_position.x - bf_enemy1.global_position.x,
		bf_boss.global_position.z - bf_enemy1.global_position.z
	).length()
	assert_true(final_sep > bf_boss.radius + bf_enemy1.radius + 0.2, "Boss and Enemy1 do not stick together (sep %.2f)" % final_sep)

	tree.root.remove_child(bf)
	bf.queue_free()
	tree.get_multiplayer().multiplayer_peer = null


# ----- Ticket 03 (remaining points): CushionBlock extendable impact rebound during motion & pocketed Puck respawn after all Pucks come to rest -----


func test_cushion_block_extendable_impact_rebound_and_pocket_respawn_at_rest() -> void:
	var packed_table := ResourceLoader.load("res://src/battlefield/cue_table.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var table := packed_table.instantiate() as Battlefield
	_root.add_child(table)

	var pvm := PuckVelocityManager.new()
	pvm.battlefield = table
	pvm.timing_manager = _tm
	_root.add_child(pvm)

	# 1. CushionBlock extendable impact function: mass-independent rebound
	#   v1f = (1 - fc) * (v1 - (v1 . n) * n) - e * (v1 . n) * n
	var top_cushion := table.get_cushion_block(8) # Top rail at z = -11, inward_normal = (0, 0, 1)
	top_cushion.restitution = 0.8
	top_cushion.cushion_friction = 0.1

	var boss := DragonPlayer.new()
	boss.mass = 3.0
	var mage := EnemyAdventurer.new()
	mage.adventurer_class = EnemyAdventurer.AdventurerClass.MAGE
	mage.mass = 1.0
	_root.add_child(boss)
	_root.add_child(mage)

	boss.velocity = Vector3(10.0, 0.0, -5.0)
	mage.velocity = Vector3(10.0, 0.0, -5.0)
	var dv_boss := top_cushion.calculate_cushion_impact(boss, Vector3(0.0, 0.0, 1.0))
	var dv_mage := top_cushion.calculate_cushion_impact(mage, Vector3(0.0, 0.0, 1.0))
	# Expected v1f = (9.0, 0.0, 4.0) -> dv = (-1.0, 0.0, 9.0) for both regardless of mass
	assert_true(is_equal_approx(dv_boss.x, -1.0) and is_equal_approx(dv_boss.z, 9.0),
		"CushionBlock.calculate_cushion_impact returns (-1.0, 0, 9.0)")
	assert_true(dv_boss.is_equal_approx(dv_mage),
		"Cushion impact velocity delta is mass-independent in the normal case")

	top_cushion.apply_cushion_impact(boss, Vector3(0.0, 0.0, 1.0))
	assert_true(is_equal_approx(boss.velocity.x, 9.0) and is_equal_approx(boss.velocity.z, 4.0),
		"apply_cushion_impact updates puck velocity to (9.0, 0.0, 4.0)")

	# 2. Moving Puck hitting top Cushion during PuckVelocityManager tick calls CushionBlock impact
	boss.global_position = Vector3(0.0, 1.75, -9.1)
	boss.velocity = Vector3(10.0, 0.0, -5.0)
	mage.global_position = Vector3(0.0, 1.675, 0.0)
	mage.velocity = Vector3.ZERO
	pvm.step_positions(0.05, 1.0)
	pvm.step_velocities(0.05, 1.0)
	assert_true(boss.velocity.z > 2.5, "Boss rebounded off top Cushion with positive Z velocity")
	assert_true(boss.velocity.x < 9.5, "Parallel X speed was reduced by cushion_friction (fc) as well as ground friction")

	# 3. Pocketed Puck respawns at a random unoccupied non-pocket Tile inside the middle 80% of the Cue Table once all Pucks come to rest
	# Corner block 1 is a Pocket Area at (-14, 0, -9). Drop mage into that pocket while boss is still moving
	_tm.set_energy(5.0)
	_tm.request_play()
	_tm.fire_cue_shot(1.0)
	mage.global_position = Vector3(-14.0, 0.2, -9.0)
	mage.velocity = Vector3(0.0, -5.0, 0.0)
	boss.global_position = Vector3(0.0, 1.75, 0.0)
	boss.velocity = Vector3(1.2, 0.0, 0.0)

	# Step 0.5s (10 ticks): boss is still moving (speed ~0.6), so mage has NOT respawned yet
	for _i in range(10):
		pvm.step_positions(0.05, 1.0)
		pvm.step_velocities(0.05, 1.0)
	assert_false(pvm.are_all_pucks_at_rest(), "Boss is still moving at 0.5s")

	# Step another 0.6s (12 ticks): boss comes to rest -> mage respawns at a free non-pocket Tile in the middle 80%!
	for _i in range(12):
		pvm.step_positions(0.05, 1.0)
		pvm.step_velocities(0.05, 1.0)
	assert_true(pvm.are_all_pucks_at_rest(), "All pucks are now at rest")
	assert_false(table.is_pocket_at_world(mage.global_position), "Pocketed puck respawned onto a non-pocket Tile")
	assert_true(mage.global_position.y >= 1.5, "Respawned puck is back on top of the table floor")
	assert_true(mage.velocity.is_zero_approx(), "Respawned puck has zero velocity")
	# Middle 80% of 30x20 Cue Table: |x| <= 12.0 and |z| <= 8.0, and not overlapping Boss
	assert_true(absf(mage.global_position.x) <= 12.01 and absf(mage.global_position.z) <= 8.01,
		"Respawned inside the middle 80%% of the Cue Table (got (%.2f, %.2f))" % [mage.global_position.x, mage.global_position.z])
	var dist_to_boss := Vector2(mage.global_position.x - boss.global_position.x, mage.global_position.z - boss.global_position.z).length()
	assert_true(dist_to_boss >= mage.radius + boss.radius, "Respawned tile is empty and does not overlap other pucks")


# ----- Ticket 04: 3D first-rebound and struck-puck aiming line preview -----


func test_first_rebound_aiming_preview_for_open_table_cushion_and_enemy_puck() -> void:
	var packed_table := ResourceLoader.load("res://src/battlefield/cue_table.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var table := packed_table.instantiate() as Battlefield
	_root.add_child(table)

	var boss := DragonPlayer.new()
	boss.name = "BossAimTest"
	boss.restitution = 0.8
	_root.add_child(boss)
	boss.mass = 3.0
	boss.radius = 0.75
	boss.global_position = Vector3(0.0, 1.75, 0.0)

	_cue_mgr.battlefield = table
	_cue_mgr.boss_puck = boss
	_cue_mgr.deadzone_radius = 0.6
	_cue_mgr.drag_distance_per_energy = 1.0
	_cue_mgr.impulse_per_energy = 6.0
	_cue_mgr.aim_length_per_impulse = 0.5
	_cue_mgr.post_hit_length_per_speed = 0.5

	_tm.set_energy(8.0)
	_tm.request_play()

	# 1. Open table (no Cushion or Puck within reach): E = 1.0 -> J = 6.0 -> reach = 3.0 along +X (Cushion is at 15 - 0.75 = 14.25)
	_cue_mgr.begin_drag(Vector3(0.0, 1.75, 0.0))
	_cue_mgr.update_drag(Vector3(-0.7, 1.5, 0.0))
	var state_open := _cue_mgr.get_aim_line_state()
	assert_eq(state_open.get("hit_type"), "none", "No hit when target is beyond reach")
	assert_false(state_open.get("has_contact_ring", true), "No ghost contact ring when nothing hit")
	assert_true(is_equal_approx(float(state_open.get("primary_length", 0.0)), 3.0), "Primary arrow extends full reach 3.0")

	# 2. Cushion hit within reach: Place Boss at (0, 1.75, -6.25), aim toward top-left at (-3, 0, -4)/5 so it hits top Cushion at z = -10 + 0.75 = -9.25
	# Distance along Z is 3.0; with dir = (0.6, 0, -0.8), hit distance = 3.0 / 0.8 = 3.75 (contact at (2.25, 1.55, -9.25))
	_cue_mgr.cancel_drag(false)
	boss.global_position = Vector3(0.0, 1.75, -6.25)
	var dir_cush := Vector3(0.6, 0.0, -0.8) # normalized (0.6^2 + 0.8^2 = 1)
	_cue_mgr.begin_drag(boss.global_position)
	# Drag for E = 3.0 -> J = 18.0 -> reach = 9.0 (> 3.75), v0 = 18 / 3 = 6.0 -> v_in = (3.6, 0, -4.8)
	_cue_mgr.update_drag(boss.global_position - dir_cush * 2.6)
	var state_cush := _cue_mgr.get_aim_line_state()
	assert_eq(state_cush.get("hit_type"), "cushion", "Detects Cushion hit within reach")
	assert_true(state_cush.get("has_contact_ring", false), "Renders ghost contact ring on Cushion hit")
	assert_true(is_equal_approx(float(state_cush.get("contact_ring_radius", 0.0)), 0.75), "Contact ring radius matches R_boss (0.75)")
	var c_pt: Vector3 = state_cush.get("contact_center", Vector3.ZERO)
	assert_true(is_equal_approx(c_pt.x, 2.25) and is_equal_approx(c_pt.z, -9.25), "Swept contact center accounts for R_boss against top Cushion")
	var v1f_cush: Vector3 = state_cush.get("v1f", Vector3.ZERO)
	assert_true(v1f_cush.x > 0.0 and v1f_cush.z > 0.0, "Boss first-rebound vector v1f reflects inward (+X, +Z)")
	assert_true(is_equal_approx(float(state_cush.get("rebound_length", 0.0)), v1f_cush.length() * 0.5),
		"Boss rebound arrow length scales proportionally to ||v1f||")
	assert_false(state_cush.get("has_struck_puck_arrow", true), "No second arrow when hitting a Cushion")

	# 3. Enemy Adventurer Puck hit within reach: Place Boss at (0, 1.75, 0) and Mage (m2 = 1.0, r2 = 0.45, e = 0.8) at (3.2, 1.675, 0.0)
	# Combined radius = 0.75 + 0.45 = 1.20 -> head-on contact center at x = 3.2 - 1.2 = 2.0 (primary_length = 2.0)
	_cue_mgr.cancel_drag(false)
	boss.global_position = Vector3(0.0, 1.75, 0.0)
	var mage := EnemyAdventurer.new()
	mage.adventurer_class = EnemyAdventurer.AdventurerClass.MAGE
	mage.restitution = 0.8
	_root.add_child(mage)
	mage.mass = 1.0
	mage.radius = 0.45
	mage.global_position = Vector3(3.2, 1.675, 0.0)

	_cue_mgr.begin_drag(Vector3(0.0, 1.75, 0.0))
	# Drag for E = 2.0 -> J = 12.0 -> reach = 6.0 (> 2.0), v0 = 12 / 3 = 4.0 along +X
	# From ticket 03 equations: v1f = 2.2 along +X, v2f = 5.4 along +X
	_cue_mgr.update_drag(Vector3(-1.6, 1.5, 0.0))
	var state_puck := _cue_mgr.get_aim_line_state()
	assert_eq(state_puck.get("hit_type"), "puck", "Detects Enemy Adventurer Puck hit within reach")
	assert_true(state_puck.get("has_contact_ring", false), "Renders ghost contact ring at Puck impact point")
	assert_true(is_equal_approx(float(state_puck.get("primary_length", 0.0)), 2.0),
		"Primary aiming line stops at swept contact center x = 2.0 (3.2 - (0.75 + 0.45))")
	var v1f_puck: Vector3 = state_puck.get("v1f", Vector3.ZERO)
	var v2f_puck: Vector3 = state_puck.get("v2f", Vector3.ZERO)
	assert_true(is_equal_approx(v1f_puck.x, 2.2), "Boss post-hit velocity v1f matches collision equation (2.2)")
	assert_true(is_equal_approx(v2f_puck.x, 5.4), "Struck Puck outgoing velocity v2f matches collision equation (5.4)")
	assert_true(state_puck.get("has_struck_puck_arrow", false), "Draws second contrasting arrow from struck Puck center")
	assert_true(is_equal_approx(float(state_puck.get("rebound_length", 0.0)), 2.2 * 0.5),
		"Boss post-hit arrow length proportional to ||v1f||")
	assert_true(is_equal_approx(float(state_puck.get("struck_puck_length", 0.0)), 5.4 * 0.5),
		"Struck Puck arrow length proportional to ||v2f||")
	assert_true(state_puck.get("struck_puck_color") != state_puck.get("primary_color"),
		"Struck Puck arrow uses a contrasting colour when valid")

	# 4. Over-drag turns ALL aiming visuals (primary, contact ring, v1f, and v2f) red
	_tm.set_energy(1.5) # Now E = 2.0 is over-dragged!
	_cue_mgr.update_drag(Vector3(-1.6, 1.5, 0.0))
	var state_red := _cue_mgr.get_aim_line_state()
	assert_true(state_red.get("is_invalid_red", false), "Over-drag marks aiming state invalid red")
	assert_eq(state_red.get("primary_color"), _cue_mgr.aim_invalid_color, "Primary and rebound arrows turn red")
	assert_eq(state_red.get("struck_puck_color"), _cue_mgr.aim_invalid_color, "Struck Puck arrow also turns red when over-dragged")


func test_pocket_swirl_block_captures_fast_puck_within_three_quarter_zone_disables_collider_and_rotates() -> void:
	var packed_table := ResourceLoader.load("res://src/battlefield/cue_table.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var table := packed_table.instantiate() as Battlefield
	_root.add_child(table)

	var pvm := PuckVelocityManager.new()
	pvm.battlefield = table
	pvm.timing_manager = _tm
	_root.add_child(pvm)

	var fast_puck := EnemyAdventurer.new()
	fast_puck.adventurer_class = EnemyAdventurer.AdventurerClass.RANGER
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.5
	cyl.height = 0.35
	col.shape = cyl
	fast_puck.add_child(col)
	_root.add_child(fast_puck)

	# Add a moving non-pocketed puck so the falling animation plays out before all-at-rest respawn triggers
	var active_puck := DragonPlayer.new()
	_root.add_child(active_puck)
	active_puck.global_position = Vector3(0.0, 1.75, 0.0)
	active_puck.velocity = Vector3(4.0, 0.0, 0.0)

	# Place fast_puck entering the 3/4 capture zone of Pocket Block 1 (centered at (-14.0, 0, -9.0))
	# At (-13.4, 1.675, -9.0), |dx| = 0.6 <= 0.75 (3/4 of half-width 1.0)
	fast_puck.global_position = Vector3(-13.4, 1.675, -9.0)
	fast_puck.velocity = Vector3(-12.0, 0.0, 0.0) # Very fast horizontal velocity

	var pocket_blk := table.get_table_block(1)
	assert_true(pocket_blk.is_within_pocket_capture_zone(fast_puck.global_position), "Puck at (-13.4, -9.0) is inside the 3/4 capture zone")

	# Step 1 tick of 0.05s: pocket ground effect triggers capture, disables collider, decelerates horizontal speed dramatically, and starts vertical fall + rotation
	pvm.step_velocities(0.05, 1.0)
	pvm.step_positions(0.05, 1.0)

	assert_true(fast_puck.is_falling_in_pocket, "Fast puck is captured by the pocket swirl")
	assert_true(col.disabled, "Puck collider is disabled so it passes through the floor")
	assert_eq(fast_puck.collision_layer, 0, "Puck collision_layer set to 0 while falling")
	assert_eq(fast_puck.collision_mask, 0, "Puck collision_mask set to 0 while falling")
	assert_true(absf(fast_puck.velocity.x) < 6.0, "Horizontal velocity decelerated dramatically inside pocket capture zone")
	assert_true(fast_puck.velocity.y < 0.0, "Puck started falling vertically through the floor")

	# Step a few more frames: verify vertical tilt (side near center falls first) followed by orthogonal clockwise rotation
	for _i in range(8):
		pvm.step_velocities(0.05, 1.0)
		pvm.step_positions(0.05, 1.0)
	assert_true(fast_puck.global_position.y < 1.3, "Puck passed through the floor vertically")
	assert_true(fast_puck.rotation.length() > 0.2, "Puck rotated vertically toward pocket center and spun clockwise")









