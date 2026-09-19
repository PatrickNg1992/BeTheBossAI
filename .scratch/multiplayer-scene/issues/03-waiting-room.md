# 03 — Waiting Room: seats, role choice, Game Config, start gating, leave / close

**What to build:** the Waiting Room sub-scene, laid out per `.docmanual/multiplayer/waitingRoomUI.md`: two clickable Players' Seats in the middle (Player A left, Player B right), a Spectator list on the right (displays up to 6 names), and the Room Configuration at the top. Default assignment: the Host takes Player A, the first joiner takes Player B, later joiners become Spectators. Any Peer can click an empty seat to take it; a seated player can click the Spectator list to step down. The Host edits the Game Config — Host's name and Room Capacity (2–6), both editable only before the room opens, plus the Dev-mode port — and clicks Confirm to start serving; joins beyond capacity are rejected. The Host's edits and every role change replicate to all Peers' screens as read-only mirrors (role-change clicks are requests the Host validates). "Start Game" is Host-only and enabled exactly while both seats are taken; "Close Room" is Host-only and kicks all Peers to the Menu with a localized "host closed the room" Notification; non-Host Peers see "Leave" (disconnect → Menu). If a connected Peer detects the Host went offline while waiting, they return to the Menu with a Notification.

**Blocked by:** 02 — Role Selector flow.

**Status:** ready-for-agent

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
- [ ] All display text comes from the multiLang holder (EN/ZH)
