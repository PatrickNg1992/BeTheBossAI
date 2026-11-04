# 03 — `sync_timing`, Two-Player `Prepare Time` Readiness & Competing for the Playing Right

**What to build:** Wire `sync_timing()` (`RELIABLE`) and the player action messages `action_start_wave`, `action_request_play`, and `action_cancel_play` so that all seated players must finish preparation before a Wave begins in `Prepare Time`, and seated players compete for the **Playing Right** by pressing the Play button during `Charging Time` (the first request to reach the Host enters `Play Time` as `active_player`).

**Blocked by:** 01 — Transport Unreliable-Ordered Support, Single-Player Loopback & Battlefield Sync Scaffold, 02 — Two-Player Time Board Display & `sync_time_board` (UI-First Slice)

**Status:** ready-for-agent

- [ ] `sync_timing()` broadcasts the authoritative Timing (`Prepare`, `Charging`, `Play`, `Action`, `Puck-puck Time!`, `Settle`), current `active_player` (`""`, `"a"`, or `"b"`), Stage/Wave index, and `Prepare Time` ready seats to all Peers using `RELIABLE`.
- [ ] In `Prepare Time` when `Player B` is empty (Single-Player), `Player A` sending `action_start_wave` (`RELIABLE`) immediately transitions the Host to `Charging Time` and syncs all Peers via `sync_timing()` and `sync_time_board()`.
- [ ] In `Prepare Time` when both `Player A` and `Player B` are seated, the Host stays in `Prepare Time` after only one player sends `action_start_wave` and transitions to `Charging Time` only once both `Player A` and `Player B` have sent `action_start_wave`.
- [ ] During `Charging Time`, when `Player A` or `Player B` presses the Play button (`action_request_play`, `RELIABLE`), the Host validates that the game is in `Charging Time` and that the requesting player has not already used their once-per-slot Play entry for the current Turn, then transitions to `Play Time` with `active_player` set to that player's seat.
- [ ] When both `Player A` and `Player B` send `action_request_play` during `Charging Time`, the first request to reach the Host claims the **Playing Right** (`active_player`), and the second request is ignored while in `Play Time` (preserving the second player's ability to request Play once the game returns to `Charging Time`).
- [ ] In `Play Time`, `action_cancel_play` (`RELIABLE`) is accepted only from the current `active_player`, returning the game to `Charging Time` and preserving fractional Turn charge progress.
- [ ] Spectators and non-active players are rejected if they attempt to send `action_start_wave` (Spectators), `action_request_play` (Spectators), or `action_cancel_play` (non-active player or Spectators).
