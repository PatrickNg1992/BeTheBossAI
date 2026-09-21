# 03 — Waiting Room: seats, role choice, Game Config, start gating, leave / close

**What to build:** the Waiting Room sub-scene, laid out per `.docmanual/multiplayer/waitingRoomUI.md`: two clickable Players' Seats in the middle (Player A left, Player B right), a Spectator list on the right (displays up to 6 names), and the Room Configuration at the top. Default assignment: the Host takes Player A, the first joiner takes Player B, later joiners become Spectators. Any Peer can click an empty seat to take it; a seated player can click the Spectator list to step down. The Host edits the Game Config — Host's name and Room Capacity (2–6), both editable only before the room opens, plus the Dev-mode port — and clicks Confirm to start serving; joins beyond capacity are rejected. The Host's edits and every role change replicate to all Peers' screens as read-only mirrors (role-change clicks are requests the Host validates). "Start Game" is Host-only and enabled exactly while both seats are taken; "Close Room" is Host-only and kicks all Peers to the Menu with a localized "host closed the room" Notification; non-Host Peers see "Leave" (disconnect → Menu). If a connected Peer detects the Host went offline while waiting, they return to the Menu with a Notification.

**Blocked by:** 02 — Role Selector flow.

**Status:** implemented (39/39 tests green — code-review fixes applied)

**Progress notes:**
- All behavior implemented in `src/multiplayer/multiplayer_manager.gd` + `waiting_room.gd` view; TDD cycles in `tests/test_multiplayer_manager.gd`.
- Host flow: `choose_host` seats Host at Player A (name live-binds from the config field); Confirm gated on non-empty name; `confirm_room_config()` locks config and `transport.serve(port)`.
- Joins: `_on_peer_joined` → fills the free Players' Seat (Player B first, then A), Spectator only when both seats are taken; capacity rejection sends `{"type":"rejected","reason":"room_full"}` AND `transport.kick(peer_id)` (enforced Host-side, not relying on the Peer leaving).
- Role changes: `request_take_seat`/`request_step_down` — Host applies directly, Peers `send_to_host` a request the Host validates, then `_broadcast_room_state()`; occupied-seat clicks are inert.
- Drops: host `_on_peer_dropped` erases the Peer, rebroadcasts, re-renders (Start re-disables). `leave_room()` / `close_room()` / `_on_room_closed` (`notif_host_closed`) / `_on_host_lost` (`notif_host_offline`) all route to the Menu via `_go_to_menu()`.
- Code-review fixes: Connecting state is modal (fields + buttons locked while connecting; `_join_pending` guard ignores late room-state after a failed join); transport seam gained `kick(peer_id)`; unused `get_local_id()` removed from the seam.
- FakeTransport gained `simulate_peer_drop(peer_id)` (pure Host-side drop) and `kick`.

- [x] Two clickable seats (Player A left, Player B right) + Spectator list showing up to 6 names
- [x] Defaults: Host → Player A, first joiner → Player B, later joiners → Spectator
- [x] Clicking an empty seat takes it; a seated player clicking the Spectator list steps down
- [x] Only one Player A and one Player B at a time
- [x] The Host can edit the Game Config (Host's name, Room Capacity 2–6, port) and Confirm to serve
- [x] Host's name and Room Capacity are editable only before the room opens; they lock once Confirm starts serving
- [x] Joins beyond Room Capacity are rejected
- [x] Room state and role changes replicate Host→Peers; Peer screens show read-only mirrors
- [x] "Start Game" is Host-only, enabled iff both seats are taken, and disables if a seat empties while waiting
- [x] Non-Host Peers' "Leave" disconnects and returns them to the Menu
- [x] Host "Close Room" kicks all Peers; Peers land on the Menu with the "host closed the room" Notification
- [x] A Peer who detects the Host offline while waiting returns to the Menu with a Notification
- [x] All display text comes from the multiLang holder (EN/ZH)
