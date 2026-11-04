# 07 — Authoritative Cue-Shot Launch Action (`action_cue_shot`)

**What to build:** Wire `action_cue_shot` (`RELIABLE`, Peer → Host) in `Play Time` so that when the `active_player` releases a valid drag, the Host validates the Energy cost against the `active_player`'s owned Energy, deducts the Energy, clears the aiming preview via `sync_aiming()`, applies the launch Impulse ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$) to the `active_player`'s Boss Monster, and transitions all Peers to `Puck-puck Time!` via `sync_timing()` and `sync_time_board()`.

**Blocked by:** 03 — `sync_timing`, Two-Player `Prepare Time` Readiness & Competing for the Playing Right, 04 — Boss Monster & Unit Stats Sync (`sync_boss_stats` & `sync_units`), 06 — Live Drag Aiming Line & Energy Cost Preview Sync (`action_aim_update` & `sync_aiming`)

**Status:** ready-for-agent

- [ ] Releasing a valid drag in `Play Time` sends `action_cue_shot` (`RELIABLE`) with the shot direction and quantized Energy cost (`1.0..9.0` in `0.5` steps) to the Host instead of launching the local Boss Monster directly.
- [ ] The Host validates that the game is in `Play Time`, the sender is the current `active_player`, the Energy cost is within `[1.0, 9.0]` in `0.5`-slot increments, and the `active_player` owns enough Energy (`energy_cost <= owned_energy`); invalid requests or requests from the non-active player / Spectators are rejected.
- [ ] On a valid `action_cue_shot`, the Host deducts `energy_cost` from `active_player`'s Energy, clears the active aiming state via `sync_aiming()` (`RELIABLE`), applies the Impulse $\vec{J} \propto E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$) to `active_player`'s Boss Monster on the Host, and transitions the battle to `Puck-puck Time!`.
- [ ] The Host broadcasts the updated Energy via `sync_time_board()` (`RELIABLE`, triggering the Energy spend rewind animation on all Peers) and the transition to `Puck-puck Time!` via `sync_timing()` (`RELIABLE`, triggering the "Puck-puck Time!" banner on all Peers).
