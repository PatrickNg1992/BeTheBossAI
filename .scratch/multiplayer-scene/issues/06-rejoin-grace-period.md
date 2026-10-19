# 06 — Rejoin Grace Period for mid-battle disconnects (ADR-0004)

**What to build:** the manager-side orchestration for a dropped player during battle: when Player A or Player B drops, the battle freezes behind a "Connecting…" message shown to everyone in the room, with a 30-second grace timer. The dropped player can rejoin through the Role Selector (Version Check applies) and lands directly in the frozen battle, skipping the Waiting Room. A "Leave" button on the frozen screen ends the grace early; on expiry or early end, still-connected Peers return to the Waiting Room and the dropped Peer lands on the Menu. A late joiner after expiry is rejected with a Notification. A Spectator dropping never freezes the game — the game tries to reconnect and shows a "Connecting…" message only to the disconnected Spectator. (Battle-snapshot content is out of scope per the spec; this covers freeze, timer, message, routing.)

**Blocked by:** 05 — Start Game and return to the Waiting Room.

**Status:** implemented (59/59 tests green)

**Progress notes:**
- Frozen overlay (`FrozenOverlay` in `multiplayer_scene.tscn`, approved wireframe): dim + centered panel, "Connecting…" title, `frozen_waiting` desc with `{seconds}`, Leave button. All text via multiLang (EN/ZH; new keys: `frozen_waiting`, `notif_rejoin_only`, `notif_grace_expired`).
- Player A/B drop mid-battle → Host keeps the seat reserved by name, broadcasts `battle_frozen`, freezes the battlefield (`process_mode=DISABLED`), 30s `grace_timer` (tests drive `timeout` directly).
- Dropped player: `host_lost` mid-battle → torn down locally → Role Selector Join form with `notif_connection_lost` status; rejoin with the same name (Version Check first) → `_accept_rejoin` re-keys the seat to the new peer id → `rejoin_battle` (loads frozen battle, skips Waiting Room) → `battle_resumed` + fresh room state → everyone unfreezes.
- Grace end (timer or frozen-screen Leave): broadcast `grace_ended` → connected Peers → Waiting Room, seat emptied; the dropped name joins a rejection list → late join rejected with `notif_grace_expired` (cleared on the next Start Game).
- During grace, non-matching names are rejected with `notif_rejoin_only`.
- Spectator drop: no freeze; the Spectator auto-retries the join once with saved credentials (`_last_join`) and lands in the Waiting Room; Host side treats it as a normal mid-battle join (both seats taken → Spectator).
- Battle-overlay Leave visibility centralized in `_update_battle_overlay()` (hides while frozen; recomputed when mid-battle room state arrives, so the rejoiner's role renders correctly).

- [x] A Player A / Player B drop during battle freezes the game and shows "Connecting…" to everyone in the room
- [x] A 30-second grace timer runs; the dropped player can rejoin via the Role Selector and lands in the frozen battle
- [x] "Leave" on the frozen screen ends the grace immediately
- [x] On expiry or early end, connected Peers go to the Waiting Room and the dropped Peer lands on the Menu
- [x] Join attempts after expiry are rejected with a localized Notification
- [x] A Spectator disconnect never freezes the game; "Connecting…" shows only to the disconnected Spectator
- [x] All display text comes from the multiLang holder (EN/ZH)
