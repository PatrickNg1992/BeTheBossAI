# 07 — Dev ENet transport

**What to build:** the real network transport backing the transport seam — ENet over direct IP + port (default 8910) — so an actual two-machine connection works end-to-end through the manager. Covered by at most a thin integration smoke test (two in-process instances over localhost); all behavioural testing stays behind the fake transport.

**Blocked by:** 01 — Transport seam + Multiplayer Scene manager skeleton.

**Status:** implemented (44/44 tests green, incl. real localhost smoke test)

**Progress notes:**
- `src/multiplayer/dev_transport.gd`: raw `ENetConnection` (no MultiplayerAPI). Godot 4.6 gotchas encoded in comments: listening needs `create_host_bound` (`create_host` has no port arg), and RECEIVE events carry no payload — packets come off the `ENetPacketPeer` via `get_packet()`.
- Handshake: client sends `{k:"hello",name,version}` on connect; server replies `{k:"welcome",id}` and only then emits `peer_joined`. Manager messages ride `{k:"msg",d:{...}}`; clean close rides `{k:"closed"}` before disconnect.
- Polling: manager's `_process` calls `transport.poll()` (no-op base on `MpTransport`); tests pump manually — no frames needed.
- Seam additions: `serve_failed()` signal + `is_serving` property (port-busy on Confirm → popup `notif_serve_failed`, config stays editable — supports story 9). Fake honors `fail_next_serve`.
- Legacy `network_autoload.gd` (NetworkManager autoload) deleted; removed from `project.godot`.
- `connect_timeout_ms` = 5000 default (tests shrink it).

- [x] An ENet-based transport implements the transport interface
- [x] Dev Connection Mode constructs this transport (default port 8910)
- [x] Two in-process instances can host and join over localhost in a smoke test
- [x] The rest of the test suite still runs purely against the fake transport
