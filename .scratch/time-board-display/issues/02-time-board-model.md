# 02 — Time Board model (pure logic, fed by signals)

**What to build:** the pure model that owns every board rule — energy amount and 20-cap, current-slot charge progress as a resumable fraction, per-slot cycle Action Tags at turns `3, 4, 6, 8, 9, 12` of each repeating 12-turn Action Cycle (tags exist even with `0` count; every non-defeated unit with fixed Action Countdown `3`, `4`, or `6` contributes `+1` to all multiples of its interval; 12-interval tags are flagged for highlight; upper-bar tags within 10 turns show their count circle when `count > 0`, hiding the circle when `count == 0`, with no turns-to-goal integer on the Time Board tag), freeze state per Timing, Action Time & Settle Time lifecycle (`0`-count tags clear at the goal without firing Action Time; `> 0`-count tags pin at the goal during Action Time and clear at the end of Settle Time while acted units reset their personal Action Countdown), membership changes applied in Settle Time (defeated units decrement future cycle tag counts), and the pocket rule (pocketed non-defeated units keep their Action Tag counts and Action Countdown unchanged and return at their next Action Time). The view from ticket 01 is rewired to this model, replacing its placeholder states.

**Blocked by:** None — can start immediately (fakes the TimingManager signal surface per the spec), though the view rewiring completes once the model lands.

**Status:** implemented (covered with enemy-adventurers/02)

- [x] The model holds energy, charge-progress fraction, the per-slot cycle tag map (`3, 4, 6, 8, 9, 12`), and freeze state with no rendering dependencies
- [x] Every non-defeated unit contributes `+1` to all multiples of its fixed Action Countdown (`3`, `4`, or `6`) across the 12-turn cycle (with 12-interval tags flagged for highlight); upper-bar tags show a count circle only when `count > 0` (no turns-to-goal number on the Time Board tag)
- [x] Freeze/resume mid-Turn preserves the charge-progress fraction exactly
- [x] Energy caps at 20 while tags keep advancing per Turn tick
- [x] A `0`-count tag reaching the goal clears without entering Action Time; a `> 0`-count tag pins at the goal during Action Time and clears at the end of Settle Time while acted units reset their personal Action Countdown
- [x] Defeated units decrement future cycle tag counts in Settle Time; non-defeated pocketed units keep their Action Tag counts unchanged and return at their next Action Time
- [x] Prepare-entry input shapes the model to the wave-opening state (Energy 10, old tags cleared, new cycle tags placed)
- [x] The view is driven only by the model's state/signals; placeholder states are gone
