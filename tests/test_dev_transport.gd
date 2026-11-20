extends McpTestSuite

## Thin integration smoke test for the Dev ENet transport: two in-process
## instances over localhost. All behavioural testing lives in the
## multiplayer-manager suite against the fake; this only proves the real
## transport honours the seam.

const TEST_PORT := 18910

var _transports: Array[DevTransport] = []


func suite_name() -> String:
	return "dev-transport"


func teardown() -> void:
	for t in _transports:
		t.dispose()
	_transports.clear()


## Pump both transports manually (no frames in tests) for up to `seconds`.
func _pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		for t in _transports:
			t.poll()
		OS.delay_msec(2)


func test_localhost_host_join_smoke() -> void:
	var host := DevTransport.new()
	var client := DevTransport.new()
	_transports = [host, client]
	client.connect_timeout_ms = 1000

	var joined := {}
	host.peer_joined.connect(func(id: int, peer_name: String, version: String) -> void:
		joined["id"] = id
		joined["name"] = peer_name
		joined["version"] = version
	)
	var client_connected := [false]
	client.join_succeeded.connect(func() -> void: client_connected[0] = true)

	host.serve(TEST_PORT)
	assert_true(host.is_serving, "Host should be serving after serve()")
	client.join("127.0.0.1", TEST_PORT, "Bob", "0.1.0")
	_pump(2.0)
	assert_true(client_connected[0], "Client join should succeed over localhost")
	assert_eq(joined.get("id", 0), 2, "First Peer gets id 2")
	assert_eq(joined.get("name", ""), "Bob", "Handshake carries the Player Name")
	assert_eq(joined.get("version", ""), "0.1.0", "Handshake carries the version")

	var host_got := []
	host.message_received.connect(func(_from: int, msg: Dictionary) -> void: host_got.append(msg))
	var client_got := []
	client.message_received.connect(func(_from: int, msg: Dictionary) -> void: client_got.append(msg))
	client.send_to_host({"type": "take_seat", "seat": "b"})
	host.broadcast({"type": "room_state", "host_name": "Alice"})
	client.send_to_host({"type": "aim_update", "cost": 2.5}, MpTransport.UNRELIABLE_ORDERED)
	host.broadcast({"type": "puck_pos", "x": 1.0}, MpTransport.UNRELIABLE_ORDERED)
	host.send_to_peer(2, {"type": "direct_unreliable"}, MpTransport.UNRELIABLE_ORDERED)
	_pump(0.5)
	assert_eq(host_got.size(), 2, "Host received both reliable and unreliable_ordered messages")
	assert_eq(client_got.size(), 3, "Peer received reliable broadcast, unreliable broadcast, and unreliable direct")
	if client_got.size() >= 1:
		assert_eq(client_got[0].get("host_name", ""), "Alice", "Broadcast payload intact")

	var closed := [false]
	client.room_closed.connect(func() -> void: closed[0] = true)
	host.close_room()
	_pump(0.5)
	assert_true(closed[0], "Peer sees a clean Close Room")


func test_join_without_a_server_fails() -> void:
	var client := DevTransport.new()
	_transports = [client]
	client.connect_timeout_ms = 200
	var failed := [false]
	client.join_failed.connect(func() -> void: failed[0] = true)
	client.join("127.0.0.1", TEST_PORT + 1, "Bob", "0.1.0")
	_pump(1.5)
	assert_true(failed[0], "Joining with no listener must emit join_failed")
