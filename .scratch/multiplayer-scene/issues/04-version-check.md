# 04 — Version Check on connect

**What to build:** the Host checks a joining Peer's version string against its own during connect. On mismatch the join is rejected and both sides receive a localized "version mismatch" Notification, so incompatible builds can't silently desync. On match the join proceeds into the Waiting Room as normal.

**Blocked by:** 02 — Role Selector flow.

**Status:** implemented (41/41 tests green)

**Progress notes:**
- Version travels with the connect handshake: `join(ip, port, name, version)` / `peer_joined(id, name, version)` (seam + FakeTransport updated; DevTransport inherits it for ticket 07).
- `const GAME_VERSION := "0.1.0"` on `MultiplayerManager` (+ instance var `game_version` so tests can simulate a mismatch).
- Host validates before any seat assignment; mismatch → `{"type":"rejected","reason":"version_mismatch"}` + `kick()` + Host-side `AcceptDialog` popup (`_show_notification()`, same pattern as the Menu's pending Notification).
- Peer side reuses the existing rejected path → Menu + `notif_version_mismatch` (key already existed).

- [x] A version string constant exists and is compared on every connect
- [x] A mismatching Peer is rejected and never lands in the Waiting Room
- [x] Both the Host and the rejected Peer get a localized "version mismatch" message
- [x] A matching Peer connects and lands in the Waiting Room exactly as before this check
