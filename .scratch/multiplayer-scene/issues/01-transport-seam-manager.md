# 01 — Transport seam + Multiplayer Scene manager skeleton

**What to build:** an invisible Multiplayer Scene whose manager script swaps sub-scenes (Role Selector, Waiting Room, later the Battlefield) inside a container, one visible at a time. The manager talks to a network-transport abstraction (host / join / leave / close room; peer joined / left / connection succeeded / failed / link lost events). Tests inject a fake in-memory transport, so the whole flow is testable without real sockets. The Connection Mode picks which transport is constructed; the Dev ENet transport lands in a later ticket.

**Blocked by:** None — can start immediately.

**Status:** implemented (39/39 tests green — code-review fixes applied; seam also gained `kick(peer_id)`, lost unused `get_local_id()`)

**Progress notes:**
- Transport interface: `src/multiplayer/mp_transport.gd` (`MpTransport`) — ops `serve/join/leave/close_room` + message channel `broadcast` (Host→all) / `send_to_host` / `send_to_peer`; signals `peer_joined(id,name)`, `peer_dropped(id)`, `join_succeeded`, `join_failed`, `host_lost`, `room_closed`, `message_received`. Host local id is always 1.
- Fake: `tests/fake_transport.gd` (`FakeTransport`, class_name) — static `registry` keyed by port (ignores IP), `create_host()/create_peer()`, synchronous deep-duplicated delivery, drivers `simulate_host_lost()/simulate_join_timeout()`, `join_attempts` counter.
- Manager: `src/multiplayer/multiplayer_manager.gd` (`MultiplayerManager`) on the `MultiplayerScene` root; `_show_sub_scene()` swaps Container children (exactly one visible); `connection_mode` + `_create_transport()` factory → `DevTransport` stub (`src/multiplayer/dev_transport.gd`, real ENet = ticket 07).
- Tests: `tests/test_multiplayer_manager.gd`, no real sockets.
- Gotcha: new `class_name` files need `godot --headless --import` before test runs (global class cache). Godot binary: `C:\Users\User\Desktop\godot\bin\Godot_v4.6.3-stable_win64_console.exe`.

- [x] The transport interface declares the host/join/leave/close operations and peer-event notifications above
- [x] A fake in-memory transport implements the interface and can simulate peers joining, dropping and rejoining deterministically
- [x] The manager swaps sub-scenes inside the container, with exactly one visible at a time
- [x] The Connection Mode selects which transport implementation is constructed
- [x] Manager tests run against the fake transport with no real sockets
