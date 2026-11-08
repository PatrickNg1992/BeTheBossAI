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
	assert_true(boss.velocity.x < -5.9, "Boss Monster launched with impulse velocity along -X")

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
	assert_true(boss.velocity.x > 2.9, "Boss Monster launched along +X on 2nd shot")

	tree.root.remove_child(bf)
	bf.queue_free()
	tree.get_multiplayer().multiplayer_peer = null


# ----- Ticket 02: Puck mass/radius/impulse, TableBlock ground friction (-1.0 unit/sec^2), PuckVelocityManager (20 Hz), 3D aiming line & launch -----


func test_puck_mass_radius_and_table_block_ground_friction_deceleration() -> void:
	var puck := DragonPlayer.new()
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.75
	col.shape = cyl
	puck.add_child(col)
	_root.add_child(puck)

	assert_true(puck.is_in_group("pucks"), "BasePuck registers in the 'pucks' group")
	assert_eq(puck.mass, 3.0, "Boss Monster default mass is 3.0")
	assert_eq(puck.radius, 0.75, "Puck auto-detects radius from CylinderShape3D")

	# Mass-dependent impulse: J = 15 -> v_0 = 15 / 3 = 5.0 units/sec
	puck.apply_impulse(Vector3(15.0, 0.0, 0.0))
	assert_true(is_equal_approx(puck.velocity.x, 5.0), "apply_impulse divides impulse by mass (15 / 3 = 5.0)")

	# Standard grass TableBlock decelerates at -1.0 unit/sec^2 (5.0 -> 4.0 after 1.0s of 20 Hz ticks)
	var grass_block := TableBlock.new()
	grass_block.block_type = TableBlock.BlockType.GRASS_DARK
	_root.add_child(grass_block)
	for _i in range(20):
		grass_block.apply_ground_effect(puck, 0.05)
	assert_true(is_equal_approx(puck.velocity.x, 4.0), "5.0 units/sec slows to 4.0 units/sec after 1s (20 x 0.05s ticks)")

	# Decelerate the remaining 4s + extra ticks -> clamps cleanly to Vector3.ZERO without reversing direction
	for _i in range(90):
		grass_block.apply_ground_effect(puck, 0.05)
	assert_eq(puck.velocity, Vector3.ZERO, "Friction clamps velocity to Vector3.ZERO and never reverses direction")

	# Block-type friction scaling: MUD (2.0) decelerates faster than ICE (0.2)
	var mud_block := TableBlock.new()
	mud_block.block_type = TableBlock.BlockType.MUD
	var ice_block := TableBlock.new()
	ice_block.block_type = TableBlock.BlockType.ICE
	puck.velocity = Vector3(5.0, 0.0, 0.0)
	var mud_dv := mud_block.calculate_ground_velocity_delta(puck, 0.5)
	var ice_dv := ice_block.calculate_ground_velocity_delta(puck, 0.5)
	assert_true(is_equal_approx(mud_dv.x, -1.0), "MUD (2.0 factor) reduces speed by 1.0 over 0.5s")
	assert_true(is_equal_approx(ice_dv.x, -0.1), "ICE (0.2 factor) reduces speed by 0.1 over 0.5s")
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

	# Launch with speed 2.0 units/sec along +X in Puck-puck Time!
	_tm.set_energy(5.0)
	_tm.request_play()
	_tm.fire_cue_shot(1.0)
	puck.velocity = Vector3(2.0, 0.0, 0.0)
	assert_false(pvm.are_all_pucks_at_rest(), "Puck is moving after launch")

	# Step 1.0s via 20 frames of 0.05s -> speed drops from 2.0 to 1.0, position advances along +X
	for _i in range(20):
		pvm.step_positions(0.05)
		pvm.step_velocities(0.05)
	assert_true(is_equal_approx(puck.velocity.x, 1.0), "Speed after 1.0s on grass is 1.0 unit/sec")
	assert_true(puck.global_position.x > 1.4 and puck.global_position.x < 1.6, "Position advanced ~1.5 units in 1.0s")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Still in Puck-puck Time! while moving")

	# Step remaining 1.0s -> speed reaches 0.0, all_pucks_at_rest triggers transition back to Charging Time
	for _i in range(20):
		pvm.step_positions(0.05)
		pvm.step_velocities(0.05)
	assert_true(puck.velocity.is_zero_approx(), "Puck decelerated to rest after 2.0s")
	assert_true(pvm.are_all_pucks_at_rest(), "All pucks are at rest")
	assert_eq(_tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Automatically transitions out of Puck-puck Time! when at rest")


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




