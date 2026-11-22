# 02 — Time Board model (pure logic, fed by signals)

**What to build:** the pure model that owns every board rule — energy amount and 20-cap, current-slot charge progress as a resumable fraction, per-slot aggregated tags (one arrow per slot carrying unit count + Turns-to-goal under the Fixed 12-Turn Action Cycle with `3`, `4`, or `6` Action Countdowns and 12-interval highlight), freeze state per Timing, Action Time & Settle Time lifecycle (pinned firing tags during Action Time, acted units resetting their Action Tags at the end of Settle Time), membership changes applied in Settle Time (join-or-create, zero-count removal), and the pocket rule (return tag at goal−5). The model is fed by the TimingManager-shaped signal surface — faked in tests — and translates many unit-level events into one tag per slot. The view from ticket 01 is rewired to this model, replacing its placeholder states.

**Blocked by:** None — can start immediately (fakes the TimingManager signal surface per the spec), though the view rewiring completes once the model lands.

**Status:** ready-for-agent

- [ ] The model holds energy, charge-progress fraction, the per-slot tag map, and freeze state with no rendering dependencies
- [ ] Units sharing a slot aggregate into one tag with a count and a Turns-to-goal integer (with 12-interval tags flagged for highlight); unit identity is tracked only for counts/replacements, never displayed
- [ ] Freeze/resume mid-Turn preserves the charge-progress fraction exactly
- [ ] Energy caps at 20 while tags keep advancing per Turn tick
- [ ] Action Time pins firing tags at the goal while units act in deterministic order without waiting for previous animations to finish, and acted units reset their Action Tags at the end of Settle Time
- [ ] Membership events (entered, defeated, pocketed → goal−5 return tag) apply only in Settle Time
- [ ] Prepare-entry input shapes the model to the wave-opening state (Energy 10, old tags cleared, new tags placed)
- [ ] The view is driven only by the model's state/signals; placeholder states are gone
