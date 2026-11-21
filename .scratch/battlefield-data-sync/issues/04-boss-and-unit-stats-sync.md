# 04 — Boss Monster & Unit Stats Sync (`sync_boss_stats` & `sync_units`)

**What to build:** Support `Player A`'s Boss Monster and an optional second Boss Monster for `Player B` (absent when the `Player B` seat is empty), and wire `sync_boss_stats()` (`RELIABLE`) and `sync_units()` (`RELIABLE`) so that Boss Monster HP/Health Bars and Enemy Adventurer / Minion spawns, removals, stats, Focusing states, and pocketed states stay synchronized across all Peers.

**Blocked by:** 01 — Transport Unreliable-Ordered Support, Single-Player Loopback & Battlefield Sync Scaffold

**Status:** completed

- [x] When `Player B` is empty (Single-Player), only `Player A`'s Boss Monster puck and HUD health bars are spawned and tracked; when both `Player A` and `Player B` are seated, a second Boss Monster for `Player B` is spawned and tracked alongside `Player A`'s Boss Monster.
- [x] `sync_boss_stats()` broadcasts (`RELIABLE`) each seated Boss Monster's `puck_id`, `current_hp`, `bar_max_hp`, `bars_remaining`, `max_bars`, `is_invincible`, and `is_dead` to all Peers.
- [x] When `sync_boss_stats()` updates a Boss Monster's HP or reduces `bars_remaining`, each Peer's HUD updates its health bar fill/labels and automatically plays the damage flash or Health Bar break shake/flash locally from the state change.
- [x] `sync_units()` broadcasts (`RELIABLE`) the authoritative list/state of Enemy Adventurers and Minions (`puck_id`, `unit_kind`, `owner_seat`, `adventurer_class`, `current_hp`, `max_hp`, `is_focusing`, `is_pocketed`, `pocket_return_turns`, `is_dead`, `position`) to all Peers.
- [x] Peers spawn, update, hide (when pocketed), or remove Enemy Adventurer and Minion pucks and 2D health bars to match `sync_units()`, and automatically trigger Focusing visual state locally when `is_focusing` transitions to `true`.
