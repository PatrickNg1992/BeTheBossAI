extends McpTestSuite

## Tests for Ticket 01 — Transport Unreliable-Ordered Support, Single-Player
## Loopback & Battlefield Sync Scaffold:
## - MpTransport / FakeTransport RELIABLE vs UNRELIABLE_ORDERED transfer modes
## - LoopbackTransport in-memory delivery with is_host = true and local peer 1
## - Single-Player Battlefield runs through command -> Host authority -> sync -> display loop
## - MultiplayerManager passes transport, is_host, local_peer_id, and seat assignments
##   (Player A, Player B, Spectators) to the Battlefield on Start Game
## - Host authority works regardless of whether Host is Player A, Player B, or Spectator
##   (including Host as Spectator while Peer 2 is Player A and Peer 3 is Player B)

const MULTIPLAYER_SCENE_PATH := "res://src/multiplayer_scene.tscn"
const SINGLE_PLAYER_SCENE_PATH := "res://src/menu/single_player_scene.tscn"
const BATTLEFIELD_SCENE_PATH := "res://src/demo_bettlefield.tscn"

var _nodes: Array[Node] = []


func suite_name() -> String:
	return "battlefield-sync-scaffold"


func setup() -> void:
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func teardown() -> void:
	for node in _nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	_nodes.clear()
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _mount(node: Node) -> Node:
	_nodes.append(node)
	_tree().root.add_child(node)
	return node


func test_transport_transfer_modes_default_to_reliable_and_record_unreliable_ordered() -> void:
	var host_fake := FakeTransport.create_host()
	host_fake.serve(8910)
	var peer_fake := FakeTransport.create_peer()
	peer_fake.join("127.0.0.1", 8910, "Bob", "0.1.0")

	# Default calls use RELIABLE
	host_fake.broadcast({"type": "hello_all"})
	assert_eq(host_fake.last_transfer_mode, MpTransport.RELIABLE,
		"broadcast defaults to RELIABLE")
	peer_fake.send_to_host({"type": "hello_host"})
	assert_eq(peer_fake.last_transfer_mode, MpTransport.RELIABLE,
		"send_to_host defaults to RELIABLE")
	host_fake.send_to_peer(2, {"type": "hello_peer"})
	assert_eq(host_fake.last_transfer_mode, MpTransport.RELIABLE,
		"send_to_peer defaults to RELIABLE")

	# Explicit UNRELIABLE_ORDERED is recorded on all three methods
	host_fake.broadcast({"type": "stream_pos"}, MpTransport.UNRELIABLE_ORDERED)
	assert_eq(host_fake.last_transfer_mode, MpTransport.UNRELIABLE_ORDERED,
		"broadcast records UNRELIABLE_ORDERED")
	assert_eq(host_fake.sent_records.back()["transfer_mode"], MpTransport.UNRELIABLE_ORDERED,
		"sent_records captures UNRELIABLE_ORDERED on broadcast")

	peer_fake.send_to_host({"type": "aim_drag"}, MpTransport.UNRELIABLE_ORDERED)
	assert_eq(peer_fake.last_transfer_mode, MpTransport.UNRELIABLE_ORDERED,
		"send_to_host records UNRELIABLE_ORDERED")
	assert_eq(peer_fake.sent_records.back()["transfer_mode"], MpTransport.UNRELIABLE_ORDERED,
		"sent_records captures UNRELIABLE_ORDERED on send_to_host")

	host_fake.send_to_peer(2, {"type": "direct_stream"}, MpTransport.UNRELIABLE_ORDERED)
	assert_eq(host_fake.last_transfer_mode, MpTransport.UNRELIABLE_ORDERED,
		"send_to_peer records UNRELIABLE_ORDERED")
	assert_eq(host_fake.sent_records.back()["transfer_mode"], MpTransport.UNRELIABLE_ORDERED,
		"sent_records captures UNRELIABLE_ORDERED on send_to_peer")


func test_loopback_transport_delivers_messages_in_memory_as_host_peer_1() -> void:
	var lo := LoopbackTransport.new()
	assert_true(lo.is_host, "LoopbackTransport has is_host = true")
	assert_eq(lo.get_local_id(), 1, "LoopbackTransport local peer ID is 1")

	var received: Array[Dictionary] = []
	lo.message_received.connect(func(sender_id: int, msg: Dictionary) -> void:
		received.append({"sender_id": sender_id, "msg": msg})
	)

	lo.send_to_host({"type": "cmd", "val": 10}, MpTransport.RELIABLE)
	lo.broadcast({"type": "sync", "val": 20}, MpTransport.UNRELIABLE_ORDERED)
	lo.send_to_peer(1, {"type": "direct", "val": 30}, MpTransport.RELIABLE)

	assert_eq(received.size(), 3, "All 3 loopback messages delivered in-memory")
	assert_eq(received[0]["sender_id"], 1, "Loopback sender ID is 1")
	assert_eq(received[0]["msg"].get("val"), 10, "send_to_host payload delivered")
	assert_eq(received[1]["msg"].get("val"), 20, "broadcast payload delivered")
	assert_eq(received[2]["msg"].get("val"), 30, "send_to_peer(1) payload delivered")
	assert_eq(lo.sent_records[1]["transfer_mode"], MpTransport.UNRELIABLE_ORDERED,
		"LoopbackTransport records transfer mode")


func test_single_player_actions_go_through_command_to_host_to_sync_pipeline() -> void:
	var packed := ResourceLoader.load(SINGLE_PLAYER_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var loader := _mount(packed.instantiate())
	var bf: Node = loader.battlefield
	var lo: LoopbackTransport = loader.transport
	assert_true(bf != null and lo != null, "Single-Player loader mounts Battlefield with LoopbackTransport")
	assert_eq(bf.get_local_role(), "a", "Single-Player local role is Player A")
	assert_false(bf.has_player_b(), "Single-Player has no Player B")

	lo.clear_sent_records()
	var synced_categories: Array[String] = []
	bf.sync_applied.connect(func(cat: String, _payload: Dictionary) -> void:
		synced_categories.append(cat)
	)

	# Pressing Play button in Charging Time sends action_request_play -> Host authority -> sync_timing & sync_time_board
	bf.play_button.emit_signal("pressed")
	assert_eq(bf.timing_manager.get_current_timing(), TimingManager.TIMING_PLAY,
		"Battlefield entered Play Time via Host authority")
	assert_eq(bf.active_player, "a", "Player A holds the Playing Right")
	assert_true(bf.host_received_actions.size() >= 1, "Host authority received action command")
	assert_eq(bf.host_received_actions.back()["action"], "action_request_play",
		"Play button sent action_request_play through transport")
	assert_true("timing" in synced_categories, "Host authority triggered sync_timing callback")
	assert_eq(bf.synced_state["timing"].get("active_player"), "a",
		"Synced timing state records active_player = 'a'")

	# Pressing Cancel (Play button in Play Time) sends action_cancel_play -> Host authority -> sync_timing
	bf.play_button.emit_signal("pressed")
	assert_eq(bf.timing_manager.get_current_timing(), TimingManager.TIMING_CHARGING,
		"Cancel returned to Charging Time via Host authority")
	assert_eq(bf.active_player, "", "active_player cleared on cancel")
	assert_eq(bf.host_received_actions.back()["action"], "action_cancel_play",
		"Cancel button sent action_cancel_play through transport")


func test_multiplayer_start_game_passes_transport_and_seats_and_supports_host_as_spectator() -> void:
	var mp_packed := ResourceLoader.load(MULTIPLAYER_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene

	# 1. Boot Host (Alice, peer 1) with capacity 4
	var host_mgr := _mount(mp_packed.instantiate())
	host_mgr.transport = FakeTransport.create_host()
	host_mgr.role_selector.host_button.emit_signal("pressed")
	host_mgr.waiting_room.host_name_edit.text = "Alice"
	host_mgr.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	host_mgr.waiting_room.capacity_spin.value = 4
	host_mgr.waiting_room.confirm_button.emit_signal("pressed")

	# 2. Boot Peer 2 (Bob) -> takes Player B
	var bob_mgr := _mount(mp_packed.instantiate())
	bob_mgr.transport = FakeTransport.create_peer()
	bob_mgr.role_selector.join_button.emit_signal("pressed")
	bob_mgr.role_selector.name_edit.text = "Bob"
	bob_mgr.role_selector.ip_edit.text = "127.0.0.1"
	bob_mgr.role_selector.port_edit.text = "8910"
	bob_mgr.role_selector.join_form_button.emit_signal("pressed")

	# 3. Host steps down to Spectator, and Peer 3 (Carol) joins -> Carol takes free Player A seat!
	host_mgr.request_step_down()
	var carol_mgr := _mount(mp_packed.instantiate())
	carol_mgr.transport = FakeTransport.create_peer()
	carol_mgr.role_selector.join_button.emit_signal("pressed")
	carol_mgr.role_selector.name_edit.text = "Carol"
	carol_mgr.role_selector.ip_edit.text = "127.0.0.1"
	carol_mgr.role_selector.port_edit.text = "8910"
	carol_mgr.role_selector.join_form_button.emit_signal("pressed")

	# Now: Host (peer 1) = Spectator, Carol (peer 3) = Player A, Bob (peer 2) = Player B
	assert_eq(host_mgr.peers[1]["role"], "spectator", "Host is seated as Spectator")
	assert_eq(host_mgr.peers[3]["role"], "a", "Carol (peer 3) is seated as Player A")
	assert_eq(host_mgr.peers[2]["role"], "b", "Bob (peer 2) is seated as Player B")

	# 4. Host starts the game
	host_mgr.waiting_room.start_game_button.emit_signal("pressed")

	var host_bf: Node = host_mgr.battlefield
	var bob_bf: Node = bob_mgr.battlefield
	var carol_bf: Node = carol_mgr.battlefield
	assert_true(host_bf != null and bob_bf != null and carol_bf != null,
		"All three Peers mounted the Battlefield")

	# Verify session and seat assignments on every Peer's Battlefield
	assert_true(host_bf.is_host, "Host Battlefield knows it is Host")
	assert_false(bob_bf.is_host, "Bob Battlefield knows it is a non-Host Peer")
	assert_false(carol_bf.is_host, "Carol Battlefield knows it is a non-Host Peer")

	assert_eq(host_bf.local_peer_id, 1, "Host local_peer_id is 1")
	assert_eq(bob_bf.local_peer_id, 2, "Bob local_peer_id is 2")
	assert_eq(carol_bf.local_peer_id, 3, "Carol local_peer_id is 3")

	assert_eq(host_bf.get_local_role(), "spectator", "Host Battlefield role is Spectator")
	assert_eq(carol_bf.get_local_role(), "a", "Carol Battlefield role is Player A")
	assert_eq(bob_bf.get_local_role(), "b", "Bob Battlefield role is Player B")

	for bf in [host_bf, bob_bf, carol_bf]:
		assert_eq(bf.player_a_peer_id, 3, "Every Peer knows Player A is peer 3")
		assert_eq(bf.player_b_peer_id, 2, "Every Peer knows Player B is peer 2")
		assert_true(1 in bf.spectator_peer_ids, "Every Peer knows peer 1 is a Spectator")

	# 5. Host (as Spectator) cannot trigger gameplay actions, while Carol (Player A) or Bob (Player B) can!
	host_bf.action_request_play()
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_CHARGING,
		"Spectator Host's gameplay action is rejected by Host authority")

	# Bob (Player B, non-Host Peer 2) presses Play -> sends action_request_play to Host (Spectator Peer 1)
	# -> Host validates and broadcasts sync_timing & sync_time_board to all Peers (Host, Bob, Carol)
	bob_bf.play_button.emit_signal("pressed")
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_PLAY,
		"Host authoritative Timing transitioned to Play Time on Bob's request")
	assert_eq(host_bf.active_player, "b", "Host authority recorded Bob ('b') as active_player")
	assert_eq(bob_bf.timing_manager.get_current_timing(), TimingManager.TIMING_PLAY,
		"Bob synced to Play Time from Host")
	assert_eq(bob_bf.active_player, "b", "Bob synced active_player = 'b'")
	assert_eq(carol_bf.timing_manager.get_current_timing(), TimingManager.TIMING_PLAY,
		"Carol synced to Play Time from Host")
	assert_eq(carol_bf.active_player, "b", "Carol synced active_player = 'b'")

	# 6. Verify sync_all() on Host broadcasts all 7 state sync categories to all Peers
	host_bf.sync_all()
	for cat in ["timing", "time_board", "boss_stats", "units", "puck_positions", "cards", "aiming"]:
		assert_true(int(bob_bf.sync_receive_counts.get(cat, 0)) >= 1,
			"Bob received %s from Host sync_all()" % cat)
		assert_true(int(carol_bf.sync_receive_counts.get(cat, 0)) >= 1,
			"Carol received %s from Host sync_all()" % cat)
		assert_true(int(host_bf.sync_receive_counts.get(cat, 0)) >= 1,
			"Host display received %s from Host sync_all()" % cat)


func test_two_player_time_board_sync_perspective_transfer_modes_and_rewind() -> void:
	var mp_packed := ResourceLoader.load(MULTIPLAYER_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene

	# Boot Host (Alice = Player A), Peer 2 (Bob = Player B), Peer 3 (Carol = Spectator)
	var host_mgr := _mount(mp_packed.instantiate())
	var host_fake := FakeTransport.create_host()
	host_mgr.transport = host_fake
	host_mgr.role_selector.host_button.emit_signal("pressed")
	host_mgr.waiting_room.host_name_edit.text = "Alice"
	host_mgr.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	host_mgr.waiting_room.capacity_spin.value = 4
	host_mgr.waiting_room.confirm_button.emit_signal("pressed")

	var bob_mgr := _mount(mp_packed.instantiate())
	bob_mgr.transport = FakeTransport.create_peer()
	bob_mgr.role_selector.join_button.emit_signal("pressed")
	bob_mgr.role_selector.name_edit.text = "Bob"
	bob_mgr.role_selector.ip_edit.text = "127.0.0.1"
	bob_mgr.role_selector.port_edit.text = "8910"
	bob_mgr.role_selector.join_form_button.emit_signal("pressed")

	var carol_mgr := _mount(mp_packed.instantiate())
	carol_mgr.transport = FakeTransport.create_peer()
	carol_mgr.role_selector.join_button.emit_signal("pressed")
	carol_mgr.role_selector.name_edit.text = "Carol"
	carol_mgr.role_selector.ip_edit.text = "127.0.0.1"
	carol_mgr.role_selector.port_edit.text = "8910"
	carol_mgr.role_selector.join_form_button.emit_signal("pressed")

	host_mgr.waiting_room.start_game_button.emit_signal("pressed")

	var host_bf: Node = host_mgr.battlefield
	var bob_bf: Node = bob_mgr.battlefield
	var carol_bf: Node = carol_mgr.battlefield

	# 1. All 3 Peers render the Time Board in 2-player mode, with perspective-mapped bars
	assert_true(host_bf.time_board.is_two_player_mode(), "Host (Player A) Time Board is in 2-player mode")
	assert_true(bob_bf.time_board.is_two_player_mode(), "Bob (Player B) Time Board is in 2-player mode")
	assert_true(carol_bf.time_board.is_two_player_mode(), "Carol (Spectator) Time Board is in 2-player mode")

	assert_eq(host_bf.time_board.get_perspective_role(), "a", "Host Time Board perspective is Player A")
	assert_eq(bob_bf.time_board.get_perspective_role(), "b", "Bob Time Board perspective is Player B")
	assert_eq(carol_bf.time_board.get_perspective_role(), "spectator", "Carol Time Board perspective is Spectator")

	# 2. Set distinct Energy for Player A (14.5) and Player B (6.5) on Host and call sync_time_board()
	host_bf.set_player_energy("a", 14.5)
	host_bf.set_player_energy("b", 6.5)
	host_fake.clear_sent_records()
	host_bf.sync_time_board()

	# Verify discrete sync_time_board() uses RELIABLE and carries all required fields
	assert_eq(host_fake.last_transfer_mode, MpTransport.RELIABLE,
		"Discrete sync_time_board() uses RELIABLE")
	var synced_tb: Dictionary = bob_bf.synced_state["time_board"]
	assert_true(synced_tb.has("turn_progress") and synced_tb.has("energy_a") and synced_tb.has("energy_b") \
		and synced_tb.has("has_player_b") and synced_tb.has("action_tags") and synced_tb.has("unit_tag_turns"),
		"sync_time_board payload contains turn_progress, energy_a, energy_b, has_player_b, action_tags, unit_tag_turns")
	assert_eq(float(synced_tb["energy_a"]), 14.5, "Synced energy_a is 14.5")
	assert_eq(float(synced_tb["energy_b"]), 6.5, "Synced energy_b is 6.5")
	assert_true(bool(synced_tb["has_player_b"]), "Synced has_player_b is true")

	# Verify perspective rendering on each Peer:
	# - Host (Player A) & Carol (Spectator): Main bar = 14.5 (slot 14 = 0.5), Secondary top bar = 6.5 (slot 6 = 0.5)
	# - Bob (Player B): Main bar = 6.5 (slot 6 = 0.5), Secondary top bar = 14.5 (slot 14 = 0.5)
	assert_eq(host_bf.time_board.slot_fill_ratio(14), 0.5, "Host (Player A) sees own 14.5 Energy on main bar")
	assert_eq(host_bf.time_board.secondary_slot_fill_ratio(6), 0.5, "Host (Player A) sees Player B's 6.5 Energy on top bar")
	assert_eq(carol_bf.time_board.slot_fill_ratio(14), 0.5, "Carol (Spectator) sees Player A's 14.5 Energy on main bar")
	assert_eq(carol_bf.time_board.secondary_slot_fill_ratio(6), 0.5, "Carol (Spectator) sees Player B's 6.5 Energy on top bar")
	assert_eq(bob_bf.time_board.slot_fill_ratio(6), 0.5, "Bob (Player B) sees own 6.5 Energy on main bar")
	assert_eq(bob_bf.time_board.secondary_slot_fill_ratio(14), 0.5, "Bob (Player B) sees Player A's 14.5 Energy on top bar")

	# 3. Continuous fractional Turn charge progress in Charging Time uses UNRELIABLE_ORDERED,
	#    while Turn slot completion uses RELIABLE
	host_fake.clear_sent_records()
	host_bf.timing_manager.advance_time(0.25)
	assert_eq(host_fake.last_transfer_mode, MpTransport.UNRELIABLE_ORDERED,
		"Continuous fractional Turn charge progress is sent with UNRELIABLE_ORDERED")
	assert_true(is_equal_approx(float(bob_bf.synced_state["time_board"].get("turn_progress", 0.0)), 0.25),
		"Peers receive fractional Turn charge progress (0.25)")

	# Advancing another 0.25s completes the half-slot for both 14.5 -> 15.0 and 6.5 -> 7.0 -> sent RELIABLE
	host_fake.clear_sent_records()
	host_bf.timing_manager.advance_time(0.25)
	var found_reliable_tb := false
	for rec in host_fake.sent_records:
		var msg: Dictionary = rec.get("message", {})
		if msg.get("type") == "bf_sync" and msg.get("category") == "time_board" and rec.get("transfer_mode") == MpTransport.RELIABLE:
			found_reliable_tb = true
	assert_true(found_reliable_tb, "Turn slot completion sends sync_time_board with RELIABLE")
	assert_eq(float(bob_bf.synced_state["time_board"].get("energy_a", 0.0)), 15.0, "Player A charged to 15.0")
	assert_eq(float(bob_bf.synced_state["time_board"].get("energy_b", 0.0)), 7.0, "Player B charged to 7.0")

	# 4. Lowering a player's Energy via sync_time_board() triggers the Energy spend rewind animation on all Peers
	host_bf.time_board.last_animation_kind = ""
	bob_bf.time_board.last_animation_kind = ""
	carol_bf.time_board.last_animation_kind = ""
	host_bf.sync_time_board({"energy_b": 4.0})
	assert_eq(host_bf.time_board.last_animation_kind, "rewind", "Host Time Board plays rewind when Player B spends Energy")
	assert_eq(bob_bf.time_board.last_animation_kind, "rewind", "Player B Time Board plays rewind when Player B spends Energy")
	assert_eq(carol_bf.time_board.last_animation_kind, "rewind", "Spectator Time Board plays rewind when Player B spends Energy")

	# 5. Play button sync across Player A, Player B, and Spectator:
	#    - When Player A clicks Play: Player A sees "Cancel" (clickable), Player B sees "Waiting" (disabled)
	#    - When Player A clicks Cancel: both Player A and Player B return to "Play" (clickable)
	#    - When Puck-puck Time! / Settle Time ends: both Player A and Player B return to "Play" (clickable)
	assert_eq(host_bf.play_button.text, Loc.t("timing_play"), "Player A starts with Play button")
	assert_false(host_bf.play_button.disabled, "Player A Play button starts clickable")
	assert_eq(bob_bf.play_button.text, Loc.t("timing_play"), "Player B starts with Play button")
	assert_false(bob_bf.play_button.disabled, "Player B Play button starts clickable")

	# Player A clicks Play
	host_bf.play_button.emit_signal("pressed")
	assert_eq(host_bf.play_button.text, Loc.t("timing_cancel"), "Player A sees Cancel button in Play Time")
	assert_false(host_bf.play_button.disabled, "Player A Cancel button is clickable")
	assert_eq(bob_bf.play_button.text, Loc.t("timing_waiting"), "Player B sees Waiting button while Player A holds Playing Right")
	assert_true(bob_bf.play_button.disabled, "Player B Waiting button is disabled")

	# Player A clicks Cancel -> both return to Play and clickable
	host_bf.play_button.emit_signal("pressed")
	assert_eq(host_bf.play_button.text, Loc.t("timing_play"), "Player A button returns to Play after Cancel")
	assert_false(host_bf.play_button.disabled, "Player A Play button is clickable after Cancel")
	assert_eq(bob_bf.play_button.text, Loc.t("timing_play"), "Player B button returns to Play after Cancel")
	assert_false(bob_bf.play_button.disabled, "Player B Play button is clickable after Cancel")

	# Player B clicks Play, fires a Cue-Shot -> Puck-puck Time! -> Settle Time -> ends back in Charging Time:
	# both players' buttons return to Play and clickable
	bob_bf.play_button.emit_signal("pressed")
	assert_eq(bob_bf.play_button.text, Loc.t("timing_cancel"), "Player B sees Cancel when holding Playing Right")
	assert_eq(host_bf.play_button.text, Loc.t("timing_waiting"), "Player A sees Waiting while Player B holds Playing Right")
	assert_true(host_bf.play_button.disabled, "Player A Waiting button is disabled")

	bob_bf.action_cue_shot(Vector3(1.0, 0.0, 0.0), 1.0)
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_PUCK_PUCK, "Entered Puck-puck Time!")
	host_bf.timing_manager.stage_damage("enemy_1", 10)
	host_bf.timing_manager.notify_all_pucks_at_rest()
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_SETTLE, "Entered Settle Time")
	host_bf.timing_manager.notify_settle_finished()
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_CHARGING, "Returned to Charging Time after Settle Time")
	assert_eq(host_bf.play_button.text, Loc.t("timing_play"), "Player A button returns to Play after Puck-puck & Settle end")
	assert_false(host_bf.play_button.disabled, "Player A Play button is clickable after Puck-puck & Settle end")
	assert_eq(bob_bf.play_button.text, Loc.t("timing_play"), "Player B button returns to Play after Puck-puck & Settle end")
	assert_false(bob_bf.play_button.disabled, "Player B Play button is clickable after Puck-puck & Settle end")

