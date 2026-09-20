extends McpTestSuite

## Tests for the Multiplayer Scene manager: sub-scene swapping, Role
## Selector flow, and Waiting Room behavior. All network behavior is driven
## through the injected FakeTransport — no real sockets.

const SCENE_PATH := "res://src/multiplayer_scene.tscn"
const MENU_SCENE_PATH := "res://src/menu/menu.tscn"

var _scene: Node = null


func suite_name() -> String:
	return "multiplayer-manager"


func setup() -> void:
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func teardown() -> void:
	if is_instance_valid(_scene):
		_scene.get_parent().remove_child(_scene)
		_scene.queue_free()
	_scene = null
	FakeTransport.reset_registry()
	PendingNotification.take_pending()


func _tree() -> SceneTree:
	return Engine.get_main_loop()


## Instantiate the Multiplayer Scene and mount it, with a fake host
## transport pre-injected. Returns the manager.
func _boot() -> Node:
	var packed := ResourceLoader.load(SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Multiplayer Scene failed to load")
	if packed == null:
		return null
	_scene = packed.instantiate()
	_tree().root.add_child(_scene)
	return _scene


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
func _boot_joining_peer() -> Array:
	var manager := _boot()
	if manager == null:
		return []
	var host_fake := FakeTransport.create_host()
	host_fake.serve(8910)
	var peer_fake := FakeTransport.create_peer()
	manager.transport = peer_fake
	manager.role_selector.join_button.emit_signal("pressed")
	return [manager, host_fake, peer_fake]


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
	var manager: Node = parts[0]
	_submit_join_form(manager, "Bob")
	assert_eq(manager.role_selector.status_label.text, Loc.t("join_connecting"),
		"While connecting the inline Connecting… state shows")
	assert_true(manager.role_selector.join_form_button.disabled,
		"Join button disabled while connecting")


func test_join_failure_shows_message_and_allows_retry() -> void:
	var parts := _boot_joining_peer()
	if parts.is_empty():
		return
	var manager: Node = parts[0]
	var peer_fake: FakeTransport = parts[2]
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
	var manager: Node = parts[0]
	var host_fake: FakeTransport = parts[1]
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
