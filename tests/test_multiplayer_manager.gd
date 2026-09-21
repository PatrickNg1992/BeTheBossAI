extends McpTestSuite

## Tests for the Multiplayer Scene manager: sub-scene swapping, Role
## Selector flow, and Waiting Room behavior. All network behavior is driven
## through the injected FakeTransport — no real sockets.

const SCENE_PATH := "res://src/multiplayer_scene.tscn"
const MENU_SCENE_PATH := "res://src/menu/menu.tscn"

var _scenes: Array[Node] = []


func suite_name() -> String:
	return "multiplayer-manager"


func setup() -> void:
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func teardown() -> void:
	for scene in _scenes:
		if is_instance_valid(scene) and scene.get_parent() != null:
			scene.get_parent().remove_child(scene)
			scene.queue_free()
	_scenes.clear()
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func _tree() -> SceneTree:
	return Engine.get_main_loop()


## Instantiate the Multiplayer Scene and mount it. Returns the manager.
func _boot() -> Node:
	var packed := ResourceLoader.load(SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Multiplayer Scene failed to load")
	if packed == null:
		return null
	var scene := packed.instantiate()
	_scenes.append(scene)
	_tree().root.add_child(scene)
	return scene


func test_role_selector_is_the_first_visible_sub_scene() -> void:
	var manager := _boot()
	if manager == null:
		return
	assert_true(manager.role_selector.visible, "Role Selector should be visible on entry")
	assert_false(manager.waiting_room.visible, "Waiting Room should start hidden")


func test_back_returns_to_menu_without_connecting() -> void:
	var manager := _boot()
	if manager == null:
		return
	manager.role_selector.back_button.emit_signal("pressed")
	assert_eq(manager.chosen_target.resource_path, MENU_SCENE_PATH,
		"Back must navigate to the Menu")
	assert_true(manager.transport == null, "Back must not attempt a connection")


func test_host_choice_swaps_to_waiting_room_as_host() -> void:
	var manager := _boot()
	if manager == null:
		return
	manager.role_selector.host_button.emit_signal("pressed")
	assert_false(manager.role_selector.visible, "Role Selector should hide after hosting")
	assert_true(manager.waiting_room.visible, "Waiting Room should show after hosting")
	assert_true(manager.is_host, "The hosting player is the Host")


func test_join_choice_shows_the_join_form() -> void:
	var manager := _boot()
	if manager == null:
		return
	manager.role_selector.join_button.emit_signal("pressed")
	assert_false(manager.role_selector.choice_box.visible, "Choices should hide")
	assert_true(manager.role_selector.join_form.visible, "Join form should show")


## Boots as a joining Peer with an injected fake transport, and parks a
## serving fake Host in the registry for join() to find.
func _boot_joining_peer() -> Dictionary:
	var manager := _boot()
	if manager == null:
		return {}
	var host_fake := FakeTransport.create_host()
	host_fake.serve(8910)
	var peer_fake := FakeTransport.create_peer()
	manager.transport = peer_fake
	manager.role_selector.join_button.emit_signal("pressed")
	return {"manager": manager, "host_fake": host_fake, "peer_fake": peer_fake}


func _submit_join_form(manager: Node, player_name: String) -> void:
	manager.role_selector.name_edit.text = player_name
	manager.role_selector.ip_edit.text = "127.0.0.1"
	manager.role_selector.port_edit.text = "8910"
	manager.role_selector.join_form_button.emit_signal("pressed")


func test_player_name_is_capped_at_32_chars() -> void:
	var manager := _boot()
	if manager == null:
		return
	assert_eq(manager.role_selector.name_edit.max_length, 32,
		"Player Name field must cap at 32 characters")


func test_join_with_empty_name_shows_required_message() -> void:
	var manager := _boot()
	if manager == null:
		return
	var peer_fake := FakeTransport.create_peer()
	manager.transport = peer_fake
	manager.role_selector.join_button.emit_signal("pressed")
	_submit_join_form(manager, "   ")
	assert_eq(manager.role_selector.status_label.text, Loc.t("join_name_required"),
		"Empty Player Name must show the required message")
	assert_eq(peer_fake.join_attempts, 0, "No connection should be attempted without a name")


func test_join_while_connecting_shows_connecting_state() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts["manager"]
	_submit_join_form(manager, "Bob")
	assert_eq(manager.role_selector.status_label.text, Loc.t("join_connecting"),
		"While connecting the inline Connecting… state shows")
	assert_true(manager.role_selector.join_form_button.disabled,
		"Join button disabled while connecting")


func test_join_failure_shows_message_and_allows_retry() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts["manager"]
	var peer_fake: FakeTransport = parts["peer_fake"]
	_submit_join_form(manager, "Bob")
	peer_fake.simulate_join_timeout()
	assert_eq(manager.role_selector.status_label.text, Loc.t("join_failed"),
		"A failed connection shows the localized failure message in place")
	assert_false(manager.role_selector.join_form_button.disabled,
		"Join button re-enabled so the player can retry")
	assert_false(manager.waiting_room.visible, "Peer stays in the Role Selector")


func test_successful_connect_swaps_to_the_waiting_room() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts["manager"]
	var host_fake: FakeTransport = parts["host_fake"]
	_submit_join_form(manager, "Bob")
	# The Host answers the join by broadcasting its room state.
	host_fake.broadcast({
		"type": "room_state",
		"host_name": "Alice",
		"capacity": 4,
		"port": 8910,
		"peers": {
			"1": {"name": "Alice", "role": "a"},
			"2": {"name": "Bob", "role": "b"},
		},
	})
	assert_true(manager.waiting_room.visible, "A successful connect lands in the Waiting Room")
	assert_false(manager.role_selector.visible, "Role Selector hides after connecting")
	assert_eq(manager.waiting_room.seat_a_name.text, "Alice", "Player A seat shows the Host")
	assert_eq(manager.waiting_room.seat_b_name.text, "Bob", "Player B seat shows the joiner")


# ----- Waiting Room: Host entry + Room Configuration -----


## Boots the scene and chooses "Host a game room", with a fake host
## transport pre-injected for Confirm to serve on.
func _boot_host() -> Node:
	var manager := _boot()
	if manager == null:
		return null
	manager.transport = FakeTransport.create_host()
	manager.role_selector.host_button.emit_signal("pressed")
	return manager


func test_host_takes_player_a_seat_by_default() -> void:
	var manager := _boot_host()
	if manager == null:
		return
	var wr: WaitingRoom = manager.waiting_room
	assert_true(wr.host_name_edit.editable, "Host name editable before the room opens")
	assert_true(wr.capacity_spin.editable, "Capacity editable before the room opens")
	assert_true(wr.port_edit.editable, "Port editable before the room opens")
	assert_true(wr.start_game_button.visible, "Host sees Start Game")
	assert_true(wr.close_room_button.visible, "Host sees Close Room")
	assert_false(wr.leave_button.visible, "Host never sees Leave")
	assert_true(wr.start_game_button.disabled, "Start disabled while Player B seat is empty")
	assert_eq(wr.seat_b_name.text, Loc.t("wr_seat_empty"), "Player B seat starts empty")


func test_host_seat_label_follows_the_typed_name() -> void:
	var manager := _boot_host()
	if manager == null:
		return
	manager.waiting_room.host_name_edit.text = "Alice"
	manager.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	assert_eq(manager.waiting_room.seat_a_name.text, "Alice",
		"Player A seat shows the Host's name as typed")


func test_confirm_requires_a_host_name() -> void:
	var manager := _boot_host()
	if manager == null:
		return
	assert_true(manager.waiting_room.confirm_button.disabled,
		"Confirm disabled while the Host name is empty")
	manager.waiting_room.host_name_edit.text = "Alice"
	manager.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	assert_false(manager.waiting_room.confirm_button.disabled,
		"Confirm enabled once a Host name is entered")


func test_confirm_locks_config_and_starts_serving() -> void:
	var manager := _boot_host()
	if manager == null:
		return
	var fake: FakeTransport = manager.transport
	manager.waiting_room.host_name_edit.text = "Alice"
	manager.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	manager.waiting_room.capacity_spin.value = 4
	manager.waiting_room.port_edit.text = "8911"
	manager.waiting_room.confirm_button.emit_signal("pressed")
	assert_true(fake.is_serving, "Confirm starts serving on the transport")
	assert_eq(fake.served_port, 8911, "Serving uses the configured port")
	assert_false(manager.waiting_room.host_name_edit.editable, "Host name locks once the room opens")
	assert_false(manager.waiting_room.capacity_spin.editable, "Capacity locks once the room opens")
	assert_false(manager.waiting_room.port_edit.editable, "Port locks once the room opens")
	assert_true(manager.waiting_room.confirm_button.disabled, "Confirm locks once the room opens")
	assert_eq(manager.waiting_room.seat_a_name.text, "Alice", "Player A seat keeps the confirmed name")


# ----- Waiting Room: Peers joining, defaults, mirrored state -----


## Boots a Host who has typed their name and confirmed the Room Config.
func _boot_confirmed_host(host_name: String = "Alice", room_capacity: int = 2) -> Node:
	var manager := _boot_host()
	if manager == null:
		return null
	manager.waiting_room.host_name_edit.text = host_name
	manager.waiting_room.host_name_edit.emit_signal("text_changed", host_name)
	manager.waiting_room.capacity_spin.value = room_capacity
	manager.waiting_room.confirm_button.emit_signal("pressed")
	return manager


## Boots a second scene as a Peer and submits the Join form. The fake
## transports pair over the registry, so the whole connect + broadcast
## round-trip runs synchronously. Returns the Peer's manager.
func _connect_peer(player_name: String) -> Node:
	var manager := _boot()
	if manager == null:
		return null
	manager.transport = FakeTransport.create_peer()
	manager.role_selector.join_button.emit_signal("pressed")
	_submit_join_form(manager, player_name)
	return manager


func _spectator_names(wr: WaitingRoom) -> Array[String]:
	var names: Array[String] = []
	for i in range(wr.spectator_list.item_count):
		names.append(wr.spectator_list.get_item_text(i))
	return names


func test_first_joiner_takes_player_b_seat() -> void:
	var host := _boot_confirmed_host()
	if host == null:
		return
	var peer := _connect_peer("Bob")
	if peer == null:
		return
	assert_eq(host.waiting_room.seat_b_name.text, "Bob",
		"First joiner takes the Player B seat by default")
	assert_false(host.waiting_room.start_game_button.disabled,
		"Start Game enables once both seats are taken")


func test_peer_sees_mirrored_room_state_read_only() -> void:
	var host := _boot_confirmed_host("Alice", 4)
	if host == null:
		return
	var peer := _connect_peer("Bob")
	if peer == null:
		return
	var wr: WaitingRoom = peer.waiting_room
	assert_eq(wr.seat_a_name.text, "Alice", "Peer mirrors the Host on Player A")
	assert_eq(wr.seat_b_name.text, "Bob", "Peer mirrors themself on Player B")
	assert_eq(wr.host_name_edit.text, "Alice", "Peer mirrors the Host's name")
	assert_false(wr.host_name_edit.editable, "Peer's config is read-only")
	assert_false(wr.capacity_spin.editable, "Peer's capacity is read-only")
	assert_false(wr.port_edit.editable, "Peer's port is read-only")
	assert_false(wr.confirm_button.visible, "Peer never sees Confirm")
	assert_false(wr.start_game_button.visible, "Peer never sees Start Game")
	assert_false(wr.close_room_button.visible, "Peer never sees Close Room")
	assert_true(wr.leave_button.visible, "Peer sees Leave")


func test_later_joiner_becomes_a_spectator() -> void:
	var host := _boot_confirmed_host("Alice", 4)
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	var carol := _connect_peer("Carol")
	if carol == null:
		return
	assert_true("Carol" in _spectator_names(host.waiting_room),
		"Later joiner lands in the Host's Spectator list")
	assert_true("Carol" in _spectator_names(carol.waiting_room),
		"Later joiner sees themself in the Spectator list")
	assert_eq(carol.waiting_room.seat_b_name.text, "Bob",
		"Player B stays with the first joiner")


func test_join_beyond_room_capacity_is_rejected() -> void:
	var host := _boot_confirmed_host("Alice", 2)
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	var carol := _connect_peer("Carol")
	if carol == null:
		return
	assert_eq(carol.chosen_target.resource_path, MENU_SCENE_PATH,
		"A rejected Peer returns to the Menu")
	assert_eq(PendingNotification.take_pending(), "notif_room_full",
		"The rejected Peer gets the localized room-full Notification")
	assert_eq(host.waiting_room.seat_b_name.text, "Bob", "Player B is unchanged")
	assert_false("Carol" in _spectator_names(host.waiting_room),
		"A rejected Peer never enters the room state")


# ----- Waiting Room: role changes -----


## Host Alice (Player A) + Bob (Player B) + Carol (Spectator), capacity 4.
func _boot_room_with_bob_and_carol() -> Dictionary:
	var host := _boot_confirmed_host("Alice", 4)
	if host == null:
		return {}
	var bob := _connect_peer("Bob")
	var carol := _connect_peer("Carol")
	if bob == null or carol == null:
		return {}
	return {"host": host, "bob": bob, "carol": carol}


func test_seated_player_steps_down_via_the_spectator_list() -> void:
	var room := _boot_room_with_bob_and_carol()
	if room.is_empty():
		return
	var host: Node = room["host"]
	var bob: Node = room["bob"]
	bob.waiting_room.spectator_list.emit_signal("item_selected", 0)
	assert_eq(host.waiting_room.seat_b_name.text, Loc.t("wr_seat_empty"),
		"Stepping down empties the seat on the Host's screen")
	assert_true("Bob" in _spectator_names(host.waiting_room),
		"The stepped-down player joins the Spectator list")
	assert_eq(bob.waiting_room.seat_b_name.text, Loc.t("wr_seat_empty"),
		"The Peer's own screen mirrors the empty seat")
	assert_true(host.waiting_room.start_game_button.disabled,
		"Start Game disables when a seat empties while waiting")


func test_spectator_takes_an_empty_seat_by_clicking_it() -> void:
	var room := _boot_room_with_bob_and_carol()
	if room.is_empty():
		return
	var host: Node = room["host"]
	var bob: Node = room["bob"]
	var carol: Node = room["carol"]
	bob.waiting_room.spectator_list.emit_signal("item_selected", 0)
	carol.waiting_room.seat_b_button.emit_signal("pressed")
	assert_eq(host.waiting_room.seat_b_name.text, "Carol",
		"Clicking an empty seat takes it, validated by the Host")
	assert_eq(carol.waiting_room.seat_b_name.text, "Carol",
		"The Peer's own screen mirrors the new seat")
	assert_true("Bob" in _spectator_names(host.waiting_room),
		"The previous seat holder stays a Spectator")
	assert_false(host.waiting_room.start_game_button.disabled,
		"Start Game re-enables once both seats are taken again")


func test_clicking_an_occupied_seat_changes_nothing() -> void:
	var room := _boot_room_with_bob_and_carol()
	if room.is_empty():
		return
	var host: Node = room["host"]
	var carol: Node = room["carol"]
	carol.waiting_room.seat_a_button.emit_signal("pressed")
	assert_eq(host.waiting_room.seat_a_name.text, "Alice",
		"An occupied seat keeps its player — only one Player A")
	assert_true("Carol" in _spectator_names(host.waiting_room),
		"The clicker stays a Spectator")


# ----- Waiting Room: drops, Leave, Close Room, Host offline -----


func test_peer_drop_empties_the_seat_and_disables_start() -> void:
	var host := _boot_confirmed_host()
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	var host_fake: FakeTransport = host.transport
	host_fake.simulate_peer_drop(2)
	assert_eq(host.waiting_room.seat_b_name.text, Loc.t("wr_seat_empty"),
		"A dropped Peer's seat empties")
	assert_false("Bob" in _spectator_names(host.waiting_room),
		"A dropped Peer leaves the Spectator list")
	assert_true(host.waiting_room.start_game_button.disabled,
		"Start Game disables when a seat empties while waiting")


func test_peer_leave_disconnects_and_returns_to_menu() -> void:
	var host := _boot_confirmed_host()
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	bob.waiting_room.leave_button.emit_signal("pressed")
	assert_eq(bob.chosen_target.resource_path, MENU_SCENE_PATH,
		"Leave returns the Peer to the Menu")
	assert_eq(PendingNotification.take_pending(), "",
		"A voluntary Leave shows no Notification")
	assert_eq(host.waiting_room.seat_b_name.text, Loc.t("wr_seat_empty"),
		"The Host sees the seat empty")


func test_close_room_kicks_all_peers_with_notification() -> void:
	var host := _boot_confirmed_host()
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	host.waiting_room.close_room_button.emit_signal("pressed")
	assert_eq(bob.chosen_target.resource_path, MENU_SCENE_PATH,
		"Kicked Peers land on the Menu")
	assert_eq(PendingNotification.take_pending(), "notif_host_closed",
		"Kicked Peers get the localized host-closed Notification")
	assert_eq(host.chosen_target.resource_path, MENU_SCENE_PATH,
		"The Host returns to the Menu too")


func test_host_offline_sends_peer_to_menu_with_notification() -> void:
	var host := _boot_confirmed_host()
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	var bob_fake: FakeTransport = bob.transport
	bob_fake.simulate_host_lost()
	assert_eq(bob.chosen_target.resource_path, MENU_SCENE_PATH,
		"A Peer detecting the Host offline returns to the Menu")
	assert_eq(PendingNotification.take_pending(), "notif_host_offline",
		"The Peer gets the localized host-offline Notification")


# ----- Review fixes -----


func test_joiner_fills_player_a_when_it_is_free() -> void:
	var host := _boot_confirmed_host("Alice", 4)
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	# The Host steps down: Player A free, Player B taken by Bob.
	host.waiting_room.spectator_list.emit_signal("empty_clicked", Vector2.ZERO, 1)
	var carol := _connect_peer("Carol")
	if carol == null:
		return
	assert_eq(host.waiting_room.seat_a_name.text, "Carol",
		"A joiner takes a free Players' Seat instead of spectating")
	assert_eq(carol.waiting_room.seat_a_name.text, "Carol",
		"The joiner's own screen mirrors the assignment")


func test_connecting_state_is_modal() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts["manager"]
	_submit_join_form(manager, "Bob")
	var rs: RoleSelector = manager.role_selector
	assert_true(rs.join_form_button.disabled, "Join disabled while connecting")
	assert_true(rs.join_back_button.disabled, "Back disabled while connecting")
	assert_false(rs.name_edit.editable, "Name field locked while connecting")
	assert_false(rs.ip_edit.editable, "IP field locked while connecting")
	assert_false(rs.port_edit.editable, "Port field locked while connecting")
	parts["peer_fake"].simulate_join_timeout()
	assert_false(rs.join_back_button.disabled, "Back re-enabled after failure")
	assert_true(rs.name_edit.editable, "Name field editable again after failure")


func test_late_room_state_is_ignored_after_a_failed_join() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts["manager"]
	var host_fake: FakeTransport = parts["host_fake"]
	_submit_join_form(manager, "Bob")
	parts["peer_fake"].simulate_join_timeout()
	host_fake.broadcast({
		"type": "room_state",
		"host_name": "Alice",
		"capacity": 4,
		"port": 8910,
		"peers": {"1": {"name": "Alice", "role": "a"}},
	})
	assert_false(manager.waiting_room.visible,
		"A late room-state after a failed join must not pull the player into the room")


func test_room_full_rejection_kicks_the_peer() -> void:
	var host := _boot_confirmed_host("Alice", 2)
	if host == null:
		return
	var bob := _connect_peer("Bob")
	if bob == null:
		return
	var host_fake: FakeTransport = host.transport
	# A raw fake Peer with no manager behind it never complies with the
	# rejection — the Host must force-drop it at the transport level.
	var raw := FakeTransport.create_peer()
	raw.join("127.0.0.1", 8910, "Carol")
	assert_eq(host_fake.peer_count(), 1,
		"The Host force-drops a rejected Peer at the transport level")


# ----- Localization -----


func test_waiting_room_labels_come_from_the_multilang_holder() -> void:
	var manager := _boot_host()
	if manager == null:
		return
	var wr: WaitingRoom = manager.waiting_room
	assert_eq(wr.start_game_button.text, Loc.t("wr_start"), "Start Game label is localized")
	assert_eq(wr.close_room_button.text, Loc.t("wr_close"), "Close Room label is localized")
	assert_eq(wr.seat_a_title.text, Loc.t("wr_seat_a"), "Player A title is localized")
	assert_eq(wr.seat_b_name.text, Loc.t("wr_seat_empty"), "Empty seat label is localized")


func test_role_selector_labels_come_from_the_multilang_holder() -> void:
	var manager := _boot()
	if manager == null:
		return
	var rs: RoleSelector = manager.role_selector
	assert_eq(rs.host_button.text, Loc.t("role_host"), "Host button label is localized")
	assert_eq(rs.join_button.text, Loc.t("role_join"), "Join button label is localized")
	assert_eq(rs.back_button.text, Loc.t("role_back"), "Back button label is localized")
