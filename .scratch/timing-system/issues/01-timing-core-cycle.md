# 01 — TimingManager core cycle, Pause, and Fast Play

**What to build:** the battle clock — one TimingManager state machine holding the six Timings (Prepare, Charging, Play, Action, Puck-puck Time!, Settle), exactly one active at a time, with its full signal surface, plus Pause and single-player Fast Play. The core loop works: Charging fills one Energy slot per configurable Turn (default 1s); Play allows exactly one action — a Cue-Shot (→ Puck-puck Time!), a card (→ transition per the card's effect), or cancel (→ Charging); entry to Play is limited to once per charged slot; Puck-puck Time! runs until all pucks are at rest; Settle applies staged damage and is skipped entirely when nothing settle-worthy happened; the cycle returns to Charging. At any Timing, the player can pause and resume without losing state or fractional Turn progress. A Fast Play switch button on the battlefield screen (in single-player games) accelerates all Timings except Play Time and Prepare Time (which wait for user actions).

**Blocked by:** None — can start immediately.

**Status:** implemented (83/83 tests green — UI verified by user)

**Progress notes & temporary scaffolding to clean up in later tickets:**
- Core clock implemented in `src/battlefield/timing_manager.gd` (`class_name TimingManager`) with unit/integration tests in `tests/test_timing_manager.gd`.
- UI controls added to `src/demo_bettlefield.tscn` and wired in `src/battlefield/demo_battlefield.gd`: centered **Play / Cancel** button below the Time Board, top-right **Pause** button, top-right **Fast Play** speed-cycle button (`x1` → `x1.5` → `x2` → `x2.5` → `x1` with double-arrow icon), and bottom **"Puck-puck Time!"** slide-in/hold/slide-out ribbon banner (`src/resource/battlefield/puck_puck_banner.png`).
- Enemy Heroes (`src/pucks/base_enemy.gd`) are gated via `TimingManager` signals so they only move and attack during `Action Time`.
- **Temporary test scaffolding (tracked in 03 and 04 to remove later):**
  1. Temporary `Action` button (`%ActionButton` below Pause) + 5-second `Action Time` timer (`ACTION_PLACEHOLDER_SECONDS = 5.0`) -> remove in **03** when Action Tags & true unit actions are implemented.
  2. Temporary `Space` key press in `Play Time` (`_unhandled_input` `KEY_SPACE` -> `fire_cue_shot()`) + 5-second `Puck-puck Time!` timer (`PUCK_PUCK_PLACEHOLDER_SECONDS = 5.0`) -> remove in **04** / `cue-shot-energy` when real Cue-Shot launch and all-pucks-at-rest detection land.

- [x] All six Timings exist with names per `.docs/contexts/battlefield.md` (including "Puck-puck Time!")
- [x] Exactly one Timing is active at any moment; the manager is the only writer of the clock
- [x] Charging fills one slot per configurable Turn (default 1s)
- [x] Play entry is limited to once per charged slot; cancel returns to Charging without penalty
- [x] Cue-Shot from Play transitions to Puck-puck Time!; a card may instead redirect to Charging or Action per its effect
- [x] Puck-puck Time! ends when all pucks are at rest
- [x] Staged damage accumulates during Puck-puck Time! and is applied in Settle
- [x] Settle is skipped (straight to Charging) when nothing settle-worthy happened
- [x] Pause is allowed at any Timing, freezing clock progression in place and resuming cleanly when unpaused
- [x] A Fast Play switch button on the battlefield screen (single-player only) speeds up Charging, Action, Puck-puck Time!, and Settle while leaving Play Time and Prepare Time unaffected
- [x] Tests drive the manager's signal/input surface and assert Timing transitions, Pause/resume behaviour, and Fast Play scaling
