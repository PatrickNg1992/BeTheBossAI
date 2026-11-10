extends McpTestSuite

## Tests for TimingManager (ticket 01): the six canonical Timings, Charging
## Turn progression, Play once-per-slot rule + cancel, Cue-Shot / Card
## transitions, Puck-puck Time! at-rest resolution, staged damage and
## Settle Time (skipped when nothing settle-worthy happened), Pause/Resume
## preserving active Timing and fractional progress, and Fast Play scaling.

var _mgr: TimingManager = null


func suite_name() -> String:
	return "timing-manager"


func setup() -> void:
	_mgr = TimingManager.new()


func teardown() -> void:
	if is_instance_valid(_mgr):
		_mgr.free()
	_mgr = null


func test_six_canonical_timings_and_single_active_timing() -> void:
	assert_eq(TimingManager.TIMING_PREPARE, "Prepare Time", "Canonical Prepare Time name")
	assert_eq(TimingManager.TIMING_CHARGING, "Charging Time", "Canonical Charging Time name")
	assert_eq(TimingManager.TIMING_PLAY, "Play Time", "Canonical Play Time name")
	assert_eq(TimingManager.TIMING_ACTION, "Action Time", "Canonical Action Time name")
	assert_eq(TimingManager.TIMING_PUCK_PUCK, "Puck-puck Time!", "Canonical Puck-puck Time! name with exclamation mark")
	assert_eq(TimingManager.TIMING_SETTLE, "Settle Time", "Canonical Settle Time name")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Starts in Charging Time")


func test_charging_fills_one_slot_per_configurable_turn_and_caps_at_20() -> void:
	assert_eq(_mgr.turn_duration, 1.0, "Default Turn duration is 1.0s")
	assert_eq(_mgr.get_energy(), 0, "Energy starts at 0 before slots complete")
	var completed: Array[int] = []
	_mgr.charge_slot_completed.connect(func(e: int) -> void: completed.append(e))
	_mgr.advance_time(0.4)
	assert_eq(_mgr.get_charge_progress(), 0.4, "40% through a 1s Turn")
	assert_eq(_mgr.get_energy(), 0, "Slot not yet completed")
	_mgr.advance_time(0.6)
	assert_eq(_mgr.get_energy(), 1, "Completing 1.0s Turn adds 1 Energy")
	assert_eq(_mgr.get_charge_progress(), 0.0, "Charge progress resets on Turn completion")
	assert_eq(completed.size(), 1, "charge_slot_completed emitted once")
	assert_eq(completed[0], 1, "Signal reports new energy of 1")

	# Custom configurable turn_duration = 2.0s
	_mgr.turn_duration = 2.0
	_mgr.advance_time(1.0)
	assert_eq(_mgr.get_charge_progress(), 0.5, "1s of a 2s Turn is 0.5 progress")
	assert_eq(_mgr.get_energy(), 1, "Still at 1 Energy mid-Turn")
	_mgr.advance_time(1.0)
	assert_eq(_mgr.get_energy(), 2, "Completing 2s Turn adds 1 Energy")

	# Cap at 20 while Turns still complete
	_mgr.set_energy(20)
	_mgr.complete_charge_slot()
	assert_eq(_mgr.get_energy(), 20, "Energy caps at 20")
	assert_eq(completed.back(), 20, "Turns continue ticking at cap")

	# Half-slot completion: when Energy is at 3.5, charging 0.5 of a Turn completes slot 3 (3.5 -> 4.0), then full 1.0 Turns continue (4.0 -> 5.0)
	_mgr.turn_duration = 1.0
	_mgr.set_energy(3.5)
	_mgr.advance_time(0.25)
	assert_true(is_equal_approx(_mgr.get_energy(), 3.5), "Still at 3.5 Energy after 0.25s")
	assert_true(is_equal_approx(_mgr.get_charge_progress(), 0.25), "0.25 charge progress toward completing the half-slot")
	_mgr.advance_time(0.25)
	assert_true(is_equal_approx(_mgr.get_energy(), 4.0), "Half-slot finishes at 0.5s (3.5 -> 4.0)")
	assert_true(is_equal_approx(_mgr.get_charge_progress(), 0.0), "Charge progress resets at the 4.0 slot boundary")
	_mgr.advance_time(1.0)
	assert_true(is_equal_approx(_mgr.get_energy(), 5.0), "Subsequent full slot completes after 1.0s (4.0 -> 5.0)")


func test_play_entry_limited_to_once_per_charged_slot_and_cancel_preserves_progress() -> void:
	var transitions: Array[String] = []
	_mgr.timing_changed.connect(func(new_t: String, _old_t: String) -> void: transitions.append(new_t))

	_mgr.advance_time(0.35)
	assert_true(_mgr.can_enter_play(), "Can enter Play before using the current slot's entry")
	assert_true(_mgr.request_play(), "First Play request in the slot succeeds")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PLAY, "Entered Play Time")
	assert_eq(transitions, [TimingManager.TIMING_PLAY], "Emitted transition to Play Time")

	# Advancing time in Play Time does not advance charging
	_mgr.advance_time(5.0)
	assert_eq(_mgr.get_charge_progress(), 0.35, "Charge progress is frozen in Play Time")
	assert_eq(_mgr.get_energy(), 0, "No Energy gained in Play Time")

	# Cancel returns to Charging Time without losing progress, but cannot re-enter Play in the same slot
	assert_true(_mgr.cancel_play(), "Cancel from Play Time succeeds")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Returned to Charging Time")
	assert_eq(_mgr.get_charge_progress(), 0.35, "Fractional Turn progress preserved after cancel")
	assert_false(_mgr.can_enter_play(), "Cannot re-enter Play in the same charged slot")
	assert_false(_mgr.request_play(), "Second Play request in the same slot is rejected")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Remains in Charging Time")

	# Finishing the current slot unlocks Play entry for the new slot
	_mgr.advance_time(0.65)
	assert_eq(_mgr.get_energy(), 1, "Current slot finished charging")
	assert_true(_mgr.can_enter_play(), "New slot unlocks Play entry")
	assert_true(_mgr.request_play(), "Play request succeeds in the next slot")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PLAY, "Entered Play Time again")


func test_cue_shot_and_card_transitions_from_play_and_settle_skip_vs_apply() -> void:
	var transitions: Array[String] = []
	var applied_batches: Array = []
	_mgr.timing_changed.connect(func(new_t: String, _old_t: String) -> void: transitions.append(new_t))
	_mgr.staged_damage_applied.connect(func(dmg: Dictionary, _ev: Array) -> void: applied_batches.append(dmg.duplicate(true)))

	# 1. Card from Play -> Charging
	_mgr.request_play()
	assert_true(_mgr.play_card(TimingManager.TIMING_CHARGING), "Card redirects Play -> Charging")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Now in Charging Time")

	# 2. Card from Play -> Action -> actions_finished (nothing settle-worthy) -> skips Settle -> Charging
	_mgr.complete_charge_slot()
	_mgr.request_play()
	assert_true(_mgr.play_card(TimingManager.TIMING_ACTION), "Card redirects Play -> Action")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_ACTION, "Now in Action Time")
	_mgr.notify_actions_finished()
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Action Time with no events skips Settle -> Charging")
	assert_false(transitions.has(TimingManager.TIMING_SETTLE), "Settle Time was skipped")

	# 3. Cue-Shot from Play -> Puck-puck Time! -> all pucks at rest (nothing happened) -> skips Settle -> Charging
	transitions.clear()
	_mgr.complete_charge_slot()
	_mgr.request_play()
	assert_true(_mgr.fire_cue_shot(), "Cue-Shot transitions Play -> Puck-puck Time!")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Now in Puck-puck Time!")
	_mgr.notify_all_pucks_at_rest()
	assert_eq(transitions, [TimingManager.TIMING_PLAY, TimingManager.TIMING_PUCK_PUCK, TimingManager.TIMING_CHARGING],
		"Puck-puck Time! with no staged damage/events skips Settle straight to Charging")
	assert_eq(applied_batches.size(), 0, "No staged damage applied when nothing happened")

	# 4. Cue-Shot from Play -> Puck-puck Time! with staged damage -> Settle Time -> Charging
	transitions.clear()
	_mgr.complete_charge_slot()
	_mgr.request_play()
	_mgr.fire_cue_shot()
	_mgr.stage_damage("hero_1", 25)
	_mgr.stage_damage("hero_1", 15)
	_mgr.stage_damage("hero_2", 30)
	_mgr.record_settle_event({"type": "defeated", "target_id": "hero_1"})
	assert_eq(_mgr.get_staged_damage_for("hero_1"), 40, "Staged damage accumulates during Puck-puck Time!")
	assert_eq(applied_batches.size(), 0, "Staged damage is NOT applied during Puck-puck Time!")

	_mgr.notify_all_pucks_at_rest()
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_SETTLE, "Enters Settle Time when damage/events were staged")
	assert_eq(applied_batches.size(), 1, "Staged damage applied once on entering Settle Time")
	assert_eq(applied_batches[0].get("hero_1"), 40, "Accumulated damage for hero_1 applied at Settle")
	assert_eq(applied_batches[0].get("hero_2"), 30, "Accumulated damage for hero_2 applied at Settle")
	assert_eq(_mgr.get_staged_damage_for("hero_1"), 0, "Accumulator cleared after Settle applies it")

	_mgr.notify_settle_finished()
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Settle finishes into Charging Time")


func test_pause_and_resume_at_any_timing_preserves_state_and_fractional_progress() -> void:
	var pause_events: Array[bool] = []
	_mgr.pause_changed.connect(func(p: bool) -> void: pause_events.append(p))

	# Pause mid-Turn in Charging Time
	_mgr.advance_time(0.6)
	_mgr.pause()
	assert_true(_mgr.is_paused(), "Manager is paused")
	assert_eq(pause_events, [true], "pause_changed(true) emitted")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Paused in Charging Time")
	_mgr.advance_time(3.0)
	assert_eq(_mgr.get_charge_progress(), 0.6, "Fractional Turn progress frozen while paused")
	assert_eq(_mgr.get_energy(), 0, "No Energy gained while paused")
	assert_false(_mgr.request_play(), "Transitions blocked while paused")

	_mgr.resume()
	assert_false(_mgr.is_paused(), "Manager is unpaused")
	assert_eq(pause_events, [true, false], "pause_changed(false) emitted")
	assert_eq(_mgr.get_charge_progress(), 0.6, "Fractional Turn progress intact on resume")
	_mgr.advance_time(0.4)
	assert_eq(_mgr.get_energy(), 1, "Remaining 0.4s completes the Turn after resume")

	# Pause in Play Time, Puck-puck Time!, Action Time, Settle Time, Prepare Time
	_mgr.request_play()
	_mgr.set_paused(true)
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PLAY, "Paused in Play Time")
	assert_false(_mgr.fire_cue_shot(), "Cue-shot blocked while paused")
	_mgr.set_paused(false)
	assert_true(_mgr.fire_cue_shot(), "Cue-shot works after unpausing")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Now in Puck-puck Time!")

	_mgr.stage_damage("hero_1", 10)
	_mgr.pause()
	assert_false(_mgr.notify_all_pucks_at_rest(), "At-rest transition blocked while paused")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Still in Puck-puck Time! while paused")
	_mgr.resume()
	assert_true(_mgr.notify_all_pucks_at_rest(), "Transitions to Settle after resume")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_SETTLE, "Now in Settle Time")

	_mgr.pause()
	assert_false(_mgr.notify_settle_finished(), "Settle completion blocked while paused")
	_mgr.resume()
	assert_true(_mgr.notify_settle_finished(), "Settle completes after resume")
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_CHARGING, "Back to Charging Time")


func test_fast_play_scales_time_driven_timings_and_leaves_play_and_prepare_unaffected() -> void:
	var fp_events: Array[bool] = []
	_mgr.fast_play_changed.connect(func(enabled: bool) -> void: fp_events.append(enabled))

	assert_false(_mgr.is_fast_play(), "Fast Play starts off")
	assert_eq(_mgr.get_effective_time_scale(), 1.0, "Normal time scale is 1.0")

	_mgr.fast_play_multiplier = 2.0
	_mgr.set_fast_play(true)
	assert_true(_mgr.is_fast_play(), "Fast Play enabled in single-player")
	assert_eq(fp_events, [true], "fast_play_changed(true) emitted")

	# Charging Time is accelerated: 0.5s wall time completes a 1.0s Turn at 2x
	assert_eq(_mgr.get_effective_time_scale(), 2.0, "Charging Time runs at 2x in Fast Play")
	_mgr.advance_time(0.25)
	assert_eq(_mgr.get_charge_progress(), 0.5, "0.25s wall time gives 0.5 Turn progress at 2x")
	_mgr.advance_time(0.25)
	assert_eq(_mgr.get_energy(), 1, "0.5s total wall time completes a 1s Turn at 2x")

	# Play Time is unaffected (time scale 1.0, waiting for user input)
	_mgr.request_play()
	assert_eq(_mgr.get_effective_time_scale(), 1.0, "Play Time is unaffected by Fast Play")

	# Action Time is accelerated
	_mgr.play_card(TimingManager.TIMING_ACTION)
	assert_eq(_mgr.get_effective_time_scale(), 2.0, "Action Time is accelerated by Fast Play")
	_mgr.notify_actions_finished()

	# Puck-puck Time! and Settle Time are accelerated
	_mgr.complete_charge_slot()
	_mgr.request_play()
	_mgr.fire_cue_shot()
	assert_eq(_mgr.get_effective_time_scale(), 2.0, "Puck-puck Time! is accelerated by Fast Play")
	_mgr.stage_damage("hero_1", 10)
	_mgr.notify_all_pucks_at_rest()
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_SETTLE, "Entered Settle Time")
	assert_eq(_mgr.get_effective_time_scale(), 2.0, "Settle Time is accelerated by Fast Play")
	_mgr.notify_settle_finished()

	# Prepare Time is unaffected
	_mgr.enter_prepare()
	assert_eq(_mgr.get_current_timing(), TimingManager.TIMING_PREPARE, "Entered Prepare Time")
	assert_eq(_mgr.get_effective_time_scale(), 1.0, "Prepare Time is unaffected by Fast Play")

	# Single-player only: disabling single_player_mode turns off and rejects Fast Play
	_mgr.set_single_player_mode(false)
	assert_false(_mgr.is_fast_play(), "Fast Play disabled outside single-player")
	assert_false(_mgr.set_fast_play(true), "Cannot enable Fast Play in multiplayer")
	assert_eq(_mgr.get_effective_time_scale(), 1.0, "Multiplayer always runs at 1.0 scale")


func test_battlefield_starts_in_charging_and_wires_play_button_space_and_5s_puck_puck_time() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	var packed := ResourceLoader.load("res://src/demo_bettlefield.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Battlefield scene loads")
	if packed == null:
		return
	var bf := packed.instantiate()
	tree.root.add_child(bf)

	var tm: TimingManager = bf.timing_manager
	assert_true(tm != null, "Battlefield mounts a TimingManager")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Battlefield starts with Charging Time")
	assert_true(bf.play_button != null and bf.play_button.visible, "Play button exists on battlefield screen")
	assert_eq(bf.play_button.text, Loc.t("timing_play"), "Play button shows localized Play label in Charging Time")
	assert_true(bf.fast_play_button != null and bf.fast_play_button.visible, "Fast Play switch button visible in single-player")
	var enemy_bars: Control = bf.get_node("Canvas/EnemyHealthBars") as Control
	assert_true(enemy_bars != null and enemy_bars.visible, "Enemy health bars visible during Charging Time")

	# Pressing Play button enters Play Time and updates button to Cancel
	bf.play_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PLAY, "Play button transitions to Play Time")
	assert_eq(bf.play_button.text, Loc.t("timing_cancel"), "Play button becomes Cancel in Play Time")
	assert_false(enemy_bars.visible, "Enemy health bars are hidden during Play Time")

	# Pressing Play button again in Play Time cancels back to Charging Time and disables Play for this slot
	bf.play_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Cancel returns to Charging Time")
	assert_true(bf.play_button.disabled, "Play button disabled after using the current slot's Play entry")
	assert_true(enemy_bars.visible, "Enemy health bars reappear on cancel to Charging Time")

	# Completing the slot re-enables Play button
	tm.complete_charge_slot()
	assert_false(bf.play_button.disabled, "Play button re-enabled on new slot")

	# Re-enter Play Time, then press Space -> transitions to Puck-puck Time! and ends after 5s
	bf.play_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PLAY, "In Play Time again")
	var space_event := InputEventKey.new()
	space_event.keycode = KEY_SPACE
	space_event.physical_keycode = KEY_SPACE
	space_event.pressed = true
	bf._unhandled_input(space_event)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Space in Play Time transitions to Puck-puck Time!")
	assert_false(enemy_bars.visible, "Enemy health bars are hidden during Puck-puck Time!")

	# Advance 3s -> still in Puck-puck Time!
	bf._process(3.0)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Still in Puck-puck Time! at 3s")

	# Advance 2s (total 5s) -> ends Puck-puck Time! and returns to Charging Time
	bf._process(2.0)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Puck-puck Time! ends after 5 seconds")
	assert_true(enemy_bars.visible, "Enemy health bars reappear after Puck-puck Time! ends")

	# Fast Play button cycles x1 -> x1.5 -> x2 -> x2.5 -> x1 with double-arrow icon
	assert_true(bf.fast_play_button.icon != null, "Fast Play button has double-arrow icon")
	assert_eq(bf.fast_play_button.text, "x1", "Fast Play starts at x1")
	assert_eq(tm.get_effective_time_scale(), 1.0, "Time scale is 1.0 at x1")
	bf.fast_play_button.emit_signal("pressed")
	assert_eq(bf.fast_play_button.text, "x1.5", "1st click shows x1.5")
	assert_eq(tm.get_effective_time_scale(), 1.5, "Time scale is 1.5 at x1.5")
	bf.fast_play_button.emit_signal("pressed")
	assert_eq(bf.fast_play_button.text, "x2", "2nd click shows x2")
	assert_eq(tm.get_effective_time_scale(), 2.0, "Time scale is 2.0 at x2")
	bf.fast_play_button.emit_signal("pressed")
	assert_eq(bf.fast_play_button.text, "x2.5", "3rd click shows x2.5")
	assert_eq(tm.get_effective_time_scale(), 2.5, "Time scale is 2.5 at x2.5")
	bf.fast_play_button.emit_signal("pressed")
	assert_eq(bf.fast_play_button.text, "x1", "4th click cycles back to x1")
	assert_eq(tm.get_effective_time_scale(), 1.0, "Time scale returns to 1.0 at x1")

	# Temporary Action button enters Action Time and runs for 5 seconds before returning to Charging
	assert_true(bf.action_button != null and bf.action_button.visible, "Temporary Action button exists")
	assert_eq(bf.action_button.text, Loc.t("timing_action"), "Action button label is localized")
	bf.action_button.emit_signal("pressed")
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_ACTION, "Action button enters Action Time")
	bf._process(3.0)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_ACTION, "Still in Action Time after 3s")
	bf._process(2.0)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Action Time ends after 5s and transitions to next timing phase")

	tree.root.remove_child(bf)
	bf.queue_free()
	tree.get_multiplayer().multiplayer_peer = null


func test_enemy_heroes_only_move_and_attack_during_action_time() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	var packed := ResourceLoader.load("res://src/demo_bettlefield.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Battlefield scene loads")
	if packed == null:
		return
	var bf := packed.instantiate()
	tree.root.add_child(bf)

	var tm: TimingManager = bf.timing_manager
	var enemy1 := bf.get_node("Enemy1") as BaseEnemy
	var player := bf.get_node("Player") as BasePuck
	assert_true(enemy1 != null and player != null, "Enemy1 and Player exist")

	# Put Enemy1 right next to Player so it would normally chase/attack
	enemy1.global_position = player.global_position + Vector3(1.5, 0.0, 0.0)
	var start_pos := enemy1.global_position
	var start_hp := player.current_hp

	# In Charging Time: enemy does NOT move or attack
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "In Charging Time")
	assert_false(enemy1.is_ai_active(), "Enemy AI is disabled in Charging Time")
	enemy1._physics_process(0.5)
	assert_eq(enemy1.global_position.x, start_pos.x, "Enemy X does not move in Charging Time")
	assert_eq(enemy1.global_position.z, start_pos.z, "Enemy Z does not move in Charging Time")
	assert_eq(player.current_hp, start_hp, "Enemy does not attack in Charging Time")

	# In Play Time: enemy does NOT move or attack
	tm.request_play()
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_PLAY, "In Play Time")
	assert_false(enemy1.is_ai_active(), "Enemy AI is disabled in Play Time")
	enemy1._physics_process(0.5)
	assert_eq(player.current_hp, start_hp, "Enemy does not attack in Play Time")

	# Transition to Action Time: enemy CAN move and attack
	tm.play_card(TimingManager.TIMING_ACTION)
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_ACTION, "In Action Time")
	assert_true(enemy1.is_ai_active(), "Enemy AI is active in Action Time")
	enemy1._physics_process(0.5)
	assert_true(player.current_hp < start_hp, "Enemy attacks during Action Time")

	# Pause during Action Time: enemy stops acting while paused
	var hp_after_attack := player.current_hp
	enemy1._attack_timer = 0.0
	tm.pause()
	assert_false(enemy1.is_ai_active(), "Enemy AI is disabled while paused even in Action Time")
	enemy1._physics_process(0.5)
	assert_eq(player.current_hp, hp_after_attack, "Enemy does not attack while paused")
	tm.resume()

	# Leaving Action Time disables enemy AI again
	tm.notify_actions_finished()
	assert_eq(tm.get_current_timing(), TimingManager.TIMING_CHARGING, "Returned to Charging Time")
	assert_false(enemy1.is_ai_active(), "Enemy AI is disabled again outside Action Time")

	tree.root.remove_child(bf)
	bf.queue_free()
	tree.get_multiplayer().multiplayer_peer = null






