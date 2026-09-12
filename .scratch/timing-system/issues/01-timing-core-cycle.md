# 01 — TimingManager core cycle

**What to build:** the battle clock — one TimingManager state machine holding the six Timings (Prepare, Charging, Play, Action, Puck-puck Time!, Settle), exactly one active at a time, with its full signal surface. The core loop works: Charging fills one Energy slot per configurable Turn (default 1s); Play allows exactly one action — a Cue-Shot (→ Puck-puck Time!), a card (→ transition per the card's effect), or cancel (→ Charging); entry to Play is limited to once per charged slot; Puck-puck Time! runs until all pucks are at rest; Settle applies staged damage and is skipped entirely when nothing settle-worthy happened; the cycle returns to Charging.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] All six Timings exist with names per `.docs/contexts/battlefield.md` (including "Puck-puck Time!")
- [ ] Exactly one Timing is active at any moment; the manager is the only writer of the clock
- [ ] Charging fills one slot per configurable Turn (default 1s)
- [ ] Play entry is limited to once per charged slot; cancel returns to Charging without penalty
- [ ] Cue-Shot from Play transitions to Puck-puck Time!; a card may instead redirect to Charging or Action per its effect
- [ ] Puck-puck Time! ends when all pucks are at rest
- [ ] Staged damage accumulates during Puck-puck Time! and is applied in Settle
- [ ] Settle is skipped (straight to Charging) when nothing settle-worthy happened
- [ ] Tests drive the manager's signal/input surface and assert Timing transitions only
