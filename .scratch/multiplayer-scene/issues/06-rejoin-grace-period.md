# 06 — Rejoin Grace Period for mid-battle disconnects (ADR-0004)

**What to build:** the manager-side orchestration for a dropped Host↔Opponent link during battle: the battle freezes behind an "Opponent disconnected, waiting…" overlay with a 30-second grace timer. The dropped player can rejoin through the Role Selector (Version Check applies) and lands directly in the frozen battle, skipping the Waiting Room. A "Leave" button on the frozen screen ends the grace early; on expiry or early end, still-connected Peers return to the Waiting Room and the dropped Peer lands on the Menu. A late joiner after expiry is rejected with a Notification. A Spectator dropping frees its slot with no freeze, no timer, no interruption. (Battle-snapshot content is out of scope per the spec; this covers freeze, timer, overlay, routing.)

**Blocked by:** 05 — Start Game and return to the Waiting Room.

**Status:** ready-for-agent

- [ ] A Host↔Opponent link loss during battle freezes the game behind a waiting overlay
- [ ] A 30-second grace timer runs; the dropped player can rejoin via the Role Selector and lands in the frozen battle
- [ ] "Leave" on the frozen screen ends the grace immediately
- [ ] On expiry or early end, connected Peers go to the Waiting Room and the dropped Peer lands on the Menu
- [ ] Join attempts after expiry are rejected with a localized Notification
- [ ] A Spectator disconnect never freezes the game; the slot simply frees up
- [ ] All display text comes from the multiLang holder (EN/ZH)
