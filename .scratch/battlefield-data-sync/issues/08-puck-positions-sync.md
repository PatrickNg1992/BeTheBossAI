# 08 — Host Physics Authority & Puck Positions Sync (`sync_puck_positions`)

**What to build:** Run `Puck-puck Time!` collision physics and `Action Time` scripted glides exclusively on the Host, disable autonomous physics simulation on non-Host Peers so client positions never drift, and stream `sync_puck_positions()` (`UNRELIABLE_ORDERED` during continuous motion; `RELIABLE` when pucks come to rest / snap) from the Host to all Peers.

**Blocked by:** 04 — Boss Monster & Unit Stats Sync (`sync_boss_stats` & `sync_units`), 07 — Authoritative Cue-Shot Launch Action (`action_cue_shot`)

**Status:** ready-for-agent

- [ ] Only the Host executes physics movement, friction deceleration, puck–puck / puck–cushion rebounds in `Puck-puck Time!`, and scripted unit glides in `Action Time`; non-Host Peers do not run autonomous physics integration that could diverge from the Host.
- [ ] While pucks are moving in `Puck-puck Time!` or gliding in `Action Time`, the Host streams `sync_puck_positions()` using `UNRELIABLE_ORDERED` carrying `{ puck_id, position, velocity }` for all pucks on the Cue Table.
- [ ] When all pucks come to rest at the end of `Puck-puck Time!` (or at the end of an `Action Time` glide / `Settle Time` / `Prepare Time`), the Host sends a final `sync_puck_positions()` using `RELIABLE` so every Peer snaps to the exact authoritative resting positions before the next Timing begins.
- [ ] All Peers (`Player A`, `Player B`, and `Spectator`s) update their Boss Monster, Enemy Adventurer, and Minion 3D puck positions to match `sync_puck_positions()`.
