# 03 — Action Tag sequencing and Action Time ordering

**What to build:** per-unit Action Tags on the Time Board — each Enemy Hero (and future Minion) places a tag that advances one slot per Turn; a completed slot landing tags on the goal triggers Action Time. In Action Time only the tagged units act, one action each, ordered: buff/debuff actions first (priority TBC), then normal actions in spawn order, then cue-shot actions last; a cue-shot action diverts to Puck-puck Time! and the queue resumes after. After acting, a unit re-places its next tag a unit-specific slot offset back from the goal (faster units, smaller offsets). A pocketed unit's tag is cancelled and replaced with a return tag at goal−5. "Shot Resolution" naming is retired everywhere.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** ready-for-agent

- [ ] Charging past a tag placed on the goal slot triggers Action Time
- [ ] Only tagged units act — buff/debuff first, then spawn order, then cue-shot actions last
- [ ] A cue-shot action transitions to Puck-puck Time!; the remaining queue resumes afterwards
- [ ] After acting, the unit re-places its tag a unit-specific offset back from the goal
- [ ] A pocketed unit's planned tag is cancelled and replaced by a return tag at goal−5
- [ ] Membership changes apply in Settle Time per the spec
- [ ] Remove the temporary `Action` test button (`%ActionButton` in `demo_bettlefield.tscn`) and the 5-second `Action Time` placeholder timer (`ACTION_PLACEHOLDER_SECONDS` in `demo_battlefield.gd`), replacing them with true Action Tag arrival and unit action execution
- [ ] No code or docs still use "Shot Resolution"
