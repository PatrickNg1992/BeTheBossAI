# 06 — Rejoin Grace Period for mid-battle disconnects (ADR-0004)

**What to build:** the manager-side orchestration for a dropped player during battle: when Player A or Player B drops, the battle freezes behind a "Connecting…" message shown to everyone in the room, with a 30-second grace timer. The dropped player can rejoin through the Role Selector (Version Check applies) and lands directly in the frozen battle, skipping the Waiting Room. A "Leave" button on the frozen screen ends the grace early; on expiry or early end, still-connected Peers return to the Waiting Room and the dropped Peer lands on the Menu. A late joiner after expiry is rejected with a Notification. A Spectator dropping never freezes the game — the game tries to reconnect and shows a "Connecting…" message only to the disconnected Spectator. (Battle-snapshot content is out of scope per the spec; this covers freeze, timer, message, routing.)

**Blocked by:** 05 — Start Game and return to the Waiting Room.

**Status:** ready-for-agent

- [ ] A Player A / Player B drop during battle freezes the game and shows "Connecting…" to everyone in the room
- [ ] A 30-second grace timer runs; the dropped player can rejoin via the Role Selector and lands in the frozen battle
- [ ] "Leave" on the frozen screen ends the grace immediately
- [ ] On expiry or early end, connected Peers go to the Waiting Room and the dropped Peer lands on the Menu
- [ ] Join attempts after expiry are rejected with a localized Notification
- [ ] A Spectator disconnect never freezes the game; "Connecting…" shows only to the disconnected Spectator
- [ ] All display text comes from the multiLang holder (EN/ZH)
