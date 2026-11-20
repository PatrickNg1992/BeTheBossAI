# 06 — Live Drag Aiming Line & Energy Cost Preview Sync (`action_aim_update` & `sync_aiming`)

**What to build:** Wire `action_aim_update` (Peer → Host) and `sync_aiming()` (Host → All Peers) during `Play Time` so that while the `active_player` drags from their Boss Monster to aim a Cue-Shot, the other player and Spectators see the `active_player`'s live 3D first-rebound aiming line and Time Board Energy cost preview (including red over-drag state), and see it clear immediately when the drag is cancelled or released.

**Blocked by:** 02 — Two-Player Time Board Display & `sync_time_board` (UI-First Slice), 03 — `sync_timing`, Two-Player `Prepare Time` Readiness & Competing for the Playing Right, 04 — Boss Monster & Unit Stats Sync (`sync_boss_stats` & `sync_units`)

**Status:** ready-for-agent

- [x] During `Play Time`, when the `active_player` drags to aim from their Boss Monster, their client sends `action_aim_update` (`UNRELIABLE_ORDERED` while dragging; `RELIABLE` when cancelled/cleared) to the Host with the aiming origin/direction, quantized Energy cost (`1.0..9.0` in `0.5` steps), and over-dragged/deadzone status.
- [x] The Host validates that `action_aim_update` comes from the current `active_player` in `Play Time` (ignoring requests from the non-active player or Spectators) and calls `sync_aiming()` (`UNRELIABLE_ORDERED` while dragging; `RELIABLE` when cleared/cancelled).
- [x] On all Peers (`Player A`, `Player B`, and `Spectator`s), receiving `sync_aiming()` renders the 3D first-rebound aiming line (including contact ring and post-hit arrows) from the `active_player`'s Boss Monster and highlights the required Energy cost preview on the Time Board (turning red when over-dragged or in the cancel deadzone).
- [x] When the `active_player` releases the drag inside the cancel deadzone, releases while over-dragged, or cancels `Play Time`, `sync_aiming()` (`RELIABLE` with `active = false`) clears the 3D aiming line and Time Board Energy cost preview on all Peers while keeping the game in `Play Time` (or returning to `Charging Time` on cancel).
