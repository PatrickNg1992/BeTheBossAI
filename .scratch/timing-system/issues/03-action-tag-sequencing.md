# 03 — Action Tag sequencing and Action Time ordering

**What to build:** per-unit Action Tags on the Time Board under the **Fixed 12-Turn Action Cycle** — each Enemy Adventurer (and future Minion) has a single fixed Action Countdown that is a factor of 12 (`3`, `4`, or `6`), placing a tag that advances one slot per Turn; a completed slot landing tags on the goal triggers Action Time (at turns `3, 4, 6, 8, 9, 12` of the 12-turn cycle). In Action Time only the tagged units act in a deterministic order — buff/debuff actions first (priority TBC), then normal actions in spawn order, then cue-shot actions last — **without waiting for the previous unit's animation or movement to finish before starting the next unit's action**; a cue-shot action diverts to Puck-puck Time! and the queue resumes after. At the end of Settle Time, acted units reset their Action Tags to their fixed Action Countdown. A pocketed unit's tag is cancelled and replaced with a return tag at goal−5 (respawning at a random empty Tile inside the middle 80% of the Cue Table). "Shot Resolution" naming is retired everywhere.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** ready-for-agent

- [ ] Charging past a tag placed on the goal slot triggers Action Time (following the Fixed 12-Turn Action Cycle with `3`, `4`, or `6` Action Countdowns)
- [ ] Only tagged units act — buff/debuff first, then spawn order, then cue-shot actions last, without waiting for the previous unit's animation or movement to finish
- [ ] A cue-shot action transitions to Puck-puck Time!; the remaining queue resumes afterwards
- [ ] At the end of Settle Time, acted units reset their Action Tag to their fixed Action Countdown back from the goal
- [ ] A pocketed unit's planned tag is cancelled and replaced by a return tag at goal−5
- [ ] Membership changes apply in Settle Time per the spec
- [ ] Remove the temporary `Action` test button (`%ActionButton` in `demo_bettlefield.tscn`) and the 5-second `Action Time` placeholder timer (`ACTION_PLACEHOLDER_SECONDS` in `demo_battlefield.gd`), replacing them with true Action Tag arrival and unit action execution
- [ ] No code or docs still use "Shot Resolution"
