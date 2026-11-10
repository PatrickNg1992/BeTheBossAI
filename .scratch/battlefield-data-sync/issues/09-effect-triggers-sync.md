# 09 — One-Shot Visual Effect Start Triggers (`sync_effect_trigger`)

**What to build:** Wire `sync_effect_trigger()` (`RELIABLE`, Host → All Peers) so that the Host sends lightweight one-shot start triggers for discrete collision hits (including running staged-damage popups) in `Puck-puck Time!` and unit action animation starts in `Action Time`, allowing every Peer to play collision and action visual effects locally without syncing frame-by-frame animation details.

**Blocked by:** 04 — Boss Monster & Unit Stats Sync (`sync_boss_stats` & `sync_units`), 07 — Authoritative Cue-Shot Launch Action (`action_cue_shot`), 08 — Host Physics Authority & Puck Positions Sync (`sync_puck_positions`)

**Status:** ready-for-agent

- [ ] When a puck–puck or puck–cushion collision occurs on the Host during `Puck-puck Time!`, the Host broadcasts a one-shot `sync_effect_trigger()` (`RELIABLE`) with `kind = "collision"`, `impact_pos`, `puck_ids`, `impulse`, and `staged_damage_by_puck` (delta and running staged damage total).
- [ ] Receiving a `kind = "collision"` trigger on any Peer spawns the local collision hit effect at `impact_pos` and displays/updates the running staged-damage number on the affected pucks.
- [ ] When an Enemy Adventurer or Minion begins its action on the Host during `Action Time`, the Host broadcasts a one-shot `sync_effect_trigger()` (`RELIABLE`) with `kind = "unit_action"`, `actor_puck_id`, `action_type` (`"move"`, `"attack"`, `"skill"`, or `"cue_shot"`), `target_pos`, and `target_puck_id`.
- [ ] Receiving a `kind = "unit_action"` trigger on any Peer starts the corresponding unit action animation locally on that Peer's Battlefield.
- [ ] Frame-by-frame particle positions or tween progress are never sent over the transport; all ongoing motion of the effect runs locally on each client after the one-shot start trigger arrives.
