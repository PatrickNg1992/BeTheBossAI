# 03 — Waiting Room: seats, role choice, Game Config, start gating, leave / close

**What to build:** the Waiting Room sub-scene, laid out per `.docmanual/multiplayer/waitingRoomUI.md`: two clickable Players' Seats in the middle (Player A left, Player B right), a Spectator list on the right (displays up to 6 names), and the Room Configuration at the top. Default assignment: the Host takes Player A, the first joiner takes Player B, later joiners become Spectators. Any Peer can click an empty seat to take it; a seated player can click the Spectator list to step down. The Host edits the Game Config — Host's name and Room Capacity (2–6), both editable only before the room opens, plus the Dev-mode port — and clicks Confirm to start serving; joins beyond capacity are rejected. The Host's edits and every role change replicate to all Peers' screens as read-only mirrors (role-change clicks are requests the Host validates). "Start Game" is Host-only and enabled exactly while both seats are taken; "Close Room" is Host-only and kicks all Peers to the Menu with a localized "host closed the room" Notification; non-Host Peers see "Leave" (disconnect → Menu). If a connected Peer detects the Host went offline while waiting, they return to the Menu with a Notification.

**Blocked by:** 02 — Role Selector flow.

**Status:** in progress (uncommitted on `ai_backup`) — UI built + approved by user, render/gating skeleton in manager, behavior mostly TODO

**Progress notes (resume here):**
- DONE: `src/multiplayer/waiting_room.tscn` + `waiting_room.gd` view — Room Config top bar (HostNameEdit, CapacitySpin 2–6, PortEdit, ConfirmButton), SeatA/SeatB buttons (title + name labels, mouse_filter=2 children), SpectatorPanel ItemList, BottomBar (StartGameButton / CloseRoomButton / LeaveButton). User approved the layout visually.
- DONE: manager room-state model (`peers {id:{name,role}}`, `host_name`, `capacity`, `room_port`, `room_open`) + `_apply_room_state()` + `_render_room()` (seats, spectator list, config fields, Host-only Start/Close, Leave for Peers, Start disabled unless both seats taken).
- TODO (next TDD cycles, in order): Host entry defaults (seat A, config editable, Confirm gated on non-empty host name) → `confirm_room_config()` locks config + `transport.serve(port)` → host `_on_peer_joined` default assignment (B else Spectator) + broadcast → capacity rejection (`{"type":"rejected"}` → Peer: leave + Menu + `notif_room_full`) → seat click / step-down requests (Host validates, rebroadcasts) → drop empties seat + disables Start → Leave (`transport.leave()` → Menu) → Close Room (`transport.close_room()` → Peers: Menu + `notif_host_closed`) → `host_lost` → Menu + `notif_host_offline`.
- Stub handlers already in manager: `_on_peer_joined/_on_peer_dropped/_on_host_lost/_on_room_closed` (marked "Ticket 03").
- Waiting-room view button handlers + tscn signal connections NOT yet wired.
- Test helpers already in suite: `_boot()`, `_boot_joining_peer()`, `_submit_join_form()`. Add a `_boot_host()` helper.
- Before commit: delete throwaway `tests/test_ui_preview_sanity.gd`, update `.docs/CodeMap.md`, run full suite, then /code-review.
- Reminder: Start Game press itself does nothing yet (battlefield loading = ticket 05; only gating here).

- [ ] Two clickable seats (Player A left, Player B right) + Spectator list showing up to 6 names
- [ ] Defaults: Host → Player A, first joiner → Player B, later joiners → Spectator
- [ ] Clicking an empty seat takes it; a seated player clicking the Spectator list steps down
- [ ] Only one Player A and one Player B at a time
- [ ] The Host can edit the Game Config (Host's name, Room Capacity 2–6, port) and Confirm to serve
- [ ] Host's name and Room Capacity are editable only before the room opens; they lock once Confirm starts serving
- [ ] Joins beyond Room Capacity are rejected
- [ ] Room state and role changes replicate Host→Peers; Peer screens show read-only mirrors
- [ ] "Start Game" is Host-only, enabled iff both seats are taken, and disables if a seat empties while waiting
- [ ] Non-Host Peers' "Leave" disconnects and returns them to the Menu
- [ ] Host "Close Room" kicks all Peers; Peers land on the Menu with the "host closed the room" Notification
- [ ] A Peer who detects the Host offline while waiting returns to the Menu with a Notification
- [x] All display text comes from the multiLang holder (EN/ZH) — keys added; view applies them (behavior wiring still TODO)
