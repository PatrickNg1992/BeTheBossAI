# 03 — Waiting Room: seats, Game Config, start gating, leave / close

**What to build:** the Waiting Room sub-scene shows two seats (Host seat, Opponent seat) plus a Spectator name list capped at four. The Host edits the Game Config (Dev-mode port, Spectator acceptance toggle) and clicks Confirm to start serving; Spectator joins are rejected when disallowed or the cap is reached. The Host's Game Config edits replicate to every Peer's screen as a read-only mirror. "Start Game" is enabled exactly while the Opponent seat is filled and disables again if the Opponent disconnects while waiting. Opponent/Spectator see "Leave" (disconnect → Menu); the Host sees "Close Room", which kicks all Peers to the Menu with a localized "host closed the room" Notification.

**Blocked by:** 02 — Role Selector flow.

**Status:** ready-for-agent

- [ ] The Waiting Room shows a Host seat, an Opponent seat, and a Spectator list capped at 4
- [ ] The Host can edit the Game Config (port, Spectator toggle) and Confirm to serve
- [ ] Spectator joins are rejected when the toggle is off or the cap is reached
- [ ] Room state replicates Host→Peers; Peer screens show read-only mirrors
- [ ] "Start Game" is enabled iff the Opponent seat is filled, and disables if the Opponent leaves while waiting
- [ ] Opponent/Spectator "Leave" disconnects and returns them to the Menu
- [ ] Host "Close Room" kicks all Peers; Peers land on the Menu with the "host closed the room" Notification
- [ ] All display text comes from the multiLang holder (EN/ZH)
