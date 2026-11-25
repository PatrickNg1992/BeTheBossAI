# 03 — Action Tag sequencing and Action Time ordering

**What to build:** cycle Action Tags on the Time Board under the **Fixed 12-Turn Action Cycle** — every 12-turn cycle places tags at turns `3, 4, 6, 8, 9, 12` (even if `0` units act on that turn, with 12-interval tags highlighted), and each non-defeated Enemy Adventurer (with fixed Action Countdown `3`, `4`, or `6`) contributes `+1` to all multiples of its interval (`3, 4, 6, 8, 9, 12`). A completed slot landing a tag with `count > 0` on the goal triggers Action Time (`0`-count tags clear at the goal without entering Action Time). In Action Time only the acting units act in a deterministic order — buff/debuff actions first (priority TBC), then normal actions in spawn order, then cue-shot actions last — **without waiting for the previous unit's animation or movement to finish before starting the next unit's action**; a cue-shot action diverts to Puck-puck Time! and the queue resumes after. At the end of Settle Time, acted units reset their personal Action Countdown to their fixed interval, and defeated units are removed from future cycle tag counts. A non-defeated pocketed unit keeps its Action Tag count and Action Countdown unchanged and returns to the table at its next Action Time (at a random empty Tile inside the middle 80% of the Cue Table). "Shot Resolution" naming is retired everywhere.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** implemented (covered with enemy-adventurers/02, 04, 05)

- [x] Cycle Action Tags sit at turns `3, 4, 6, 8, 9, 12` of each 12-turn cycle; charging past a goal tag with `count > 0` triggers Action Time (`0`-count tags clear without entering Action Time)
- [x] Only units whose Action Countdown reaches `0` act across three skill phases — all Active Skills first, then all Attack Skills, then all Move Skills — ordered within each phase by unit `SPD` descending (tie-broken by game order), with Move Skills resolving Adjusted Target Position via Move Glide Logic
- [x] A cue-shot action transitions to Puck-puck Time!; the remaining queue resumes afterwards
- [x] At the end of Settle Time, acted units reset their personal Action Countdown to their fixed interval, and defeated units decrement future cycle tag counts
- [x] A non-defeated pocketed Adventurer keeps its Action Countdown and Action Tag counts unchanged and respawns at its next Action Time (after all on-table acting units finish moving, ordered by `SPD` descending, consuming its action for that turn; a pocketed Boss Monster respawns at the end of that turn's Settle Time)
- [x] Membership changes apply in Settle Time per the spec
- [x] Remove the temporary `Action` test button (`%ActionButton` in `demo_bettlefield.tscn`) and the 5-second `Action Time` placeholder timer (`ACTION_PLACEHOLDER_SECONDS` in `demo_battlefield.gd`), replacing them with true Action Tag arrival and unit action execution
- [x] No code or docs still use "Shot Resolution"
