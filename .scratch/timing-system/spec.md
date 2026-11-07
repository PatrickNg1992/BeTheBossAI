# Spec: Timing System

Status: ready-for-agent

Battle time falls into exactly one of six Timings — Prepare, Charging, Play, Action, Puck-puck Time! or Settle — driven by Energy charging and per-unit Action Tags on the energy bar. Vocabulary per `CONTEXT.md` and `.docs/contexts/battlefield.md`. Settled in the grilling session; raw source `.docmanual/battleField/timingSystem.md`.

## Problem Statement

The game mixes snooker-style physics shots with auto-battler combat, and today nothing keeps them apart: auto-attacks, AI movement and physics all run continuously in the test scene. Without explicit Timings, the player has no calm moment to aim a Cue-Shot, collisions and damage would resolve mid-flight (units could be removed while still needed for chain collisions), and there is no rhythm governing when Enemy Heroes act — the "snooker with cards" fantasy needs a clock.

## Solution

A single battle clock — the timing state machine — that every battle system obeys. The player watches the Energy bar charge during Charging Time (their thinking time), presses Play to take exactly one Cue-Shot or play one card, then watches Puck-puck Time! resolve the physics. Enemy Heroes and Minions act only when the bar charges past an Action Tag they placed, so faster units visibly act more often. Damage caused during Puck-puck Time! is staged and applied afterwards in a short Settle Time, so the collision sequence always plays out completely.

## User Stories

1. As a player, I want the battlefield frozen while I think, so that I can plan my next shot without time pressure.
2. As a player, I want to watch my Energy bar fill one slot at a time, so that I always know when I can afford a shot.
3. As a player, I want the per-slot charge time to be configurable (default 1s), so that the game's pace can be tuned.
4. As a player, I want to press a Play button to enter aiming mode, so that I choose when to act.
5. As a player, I want aiming mode limited to one entry per charged Energy slot, so that I cannot stall the battle forever.
6. As a player, I want exactly one action in aiming mode — a Cue-Shot, a card, or cancel — so that the rules stay simple and readable.
7. As a player, I want to cancel aiming mode before shooting, so that I can reconsider without penalty.
8. As a player, I want drag-to-aim to cost 1–9 Energy (in 0.5-slot steps) depending on power, so that stronger shots cost more.
9. As a player, I want to see "Puck-puck Time!" flash when my shot launches, so that the game's headline moment feels exciting.
10. As a player, I want pucks to finish every collision before anyone dies, so that chain reactions play out completely.
11. As a player, I want running damage numbers during collisions, so that I can follow the damage my shot is causing.
12. As a player, I want a short Settle Time showing defeats and pocket falls after the action, so that I understand what just happened.
13. As a player, I want the game to skip Settle Time when nothing happened, so that the pace never drags.
14. As a player, I want Enemy Heroes to act when the energy bar passes their marker, so that I can anticipate who acts next.
15. As a player, I want faster enemies to act more often than slower ones, so that enemy speed is legible on the bar.
16. As a player, I want enemies acting one at a time in a clear order, so that I can follow the battle.
17. As a player, I want enemy cue-shots (like the Knight's) to resolve after other actions on the same slot, so that the physics moment is not interrupted.
18. As a player, I want to start each Wave with exactly 10 Energy, so that every Wave opens with meaningful but limited options.
19. As a player, I want Energy to not regenerate while I prepare for the next Wave, so that preparation stays a calm interlude.
20. As a developer, I want exactly one Timing active at any moment, so that systems never fight each other.
21. As a developer, I want battle systems (AI, auto-attacks, energy, card input) to key off Timing-change signals, so that the clock is the single authority.
22. As a developer, I want Action Tags to re-place themselves a unit-specific slot offset ahead after acting, so that initiative needs no separate scheduler.
23. As a designer, I want buff/debuff actions to fire before normal actions on the same slot (priority TBC), so that setup effects land before attacks.
24. As a player, I want to pause the game at any Timing and resume where I left off, so that I can step away at any moment.
25. As a player in a single-player game, I want a Fast Play switch button on the battlefield screen that speeds up all Timings except Play Time and Prepare Time, so that Charging, Action, Puck-puck Time!, and Settle run faster while waiting-for-input phases stay unhurried.

## Implementation Decisions

- **One TimingManager module owns the clock.** A new battle-scoped state machine holds the current Timing and every transition rule. It is the only writer of game-time state; all other battle systems (puck AI, auto-attacks, energy display, card input, drag-to-aim input) subscribe to its Timing-change signals and enable/disable themselves accordingly. Signal-first wiring follows the existing `card_manager.gd` precedent.
- **Six Timings**: Prepare, Charging, Play, Action, Puck-puck Time!, Settle. Exactly one is active at a time. Canonical names come from `.docs/contexts/battlefield.md` — including the exclamation mark in "Puck-puck Time!".
- **Prepare Time**: the state machine does not run (no charging, no tag movement). On entry, the Time Board animates to the coming Wave's opening state — Energy set to exactly 10, old Action Tags removed, the incoming team's initial Action Tags placed — then freezes for the rest of the phase, so the player can read the board and plan before pressing Start Wave. Replaces the old "Energy keeps regenerating during preparation" rule.
- **Charging Time**: charges one Energy slot at a time; per-slot duration is a configurable value (default 1s). Play Time may be entered at most once per slot charged. A completed slot that lands one or more Action Tags on the Time Board's goal slot transitions to Action Time.
- **Play Time**: everything waits for the player. Exactly one action is permitted: one Cue-Shot (→ Puck-puck Time!), one card (→ Charging or Action Time, per the card's effect), or cancel (→ Charging Time).
- **Action Time**: only the units whose Action Tags were charged past act — one action each. Order: buff/debuff actions first (priority TBC), then normal actions in spawn order, then cue-shot actions (e.g. the Knight's) last. A cue-shot action transitions to Puck-puck Time!; remaining queued actions resume afterwards. All other units and the player spectate.
- **Puck-puck Time!**: runs until every puck on the table is at rest. All Auto-Attacks and AI behaviours freeze; only physics runs. Damage is staged (accumulated "to be dealt"), never applied, during this Timing — defeated units remain on the table and keep colliding until Settle Time. VFX on entry: the words "Puck-puck Time!" flash; collision effects and running staged-damage numbers display throughout.
- **Settle Time**: applies all staged damage, then displays settle-worthy events (puck defeated, puck pocketed, Boss Monster Health Bar cleared; further triggers TBC). Action Tag membership changes are applied here: a tag whose unit count reaches zero is removed, and a unit entering the table joins an existing tag for its acting slot or places a new one. Skipped entirely — zero cost, straight to the next Timing — when nothing settle-worthy happened during the previous Timing.
- **Action Tags**: each Enemy Hero (and future Minion) places a tag on a Time Board slot; the tag advances one slot per Turn and the unit acts in the Action Time fired when it reaches the goal slot. Tags are independent of the Energy fill — they only share the board. After acting, the unit places its next tag a unit-specific number of slots ahead of the goal — faster units use smaller offsets. Multiple tags reaching the goal on the same Turn resolve in the Action Time order above.
- **Energy**: capacity 20, Cue-Shot cost 1–9 in 0.5-slot steps (minimum 1, no free shots; demo test value), regeneration only via Charging Time slots. Supersedes the stale capacity-12/cost-1–6 draft and the 16-slot note in the old glossary.
- **Damage staging**: one staged-damage accumulator collects pending damage from all sources (collisions, pocket falls, action-time attacks); Settle Time applies the whole accumulator at once.
- **Pocketed units**: a pocketed unit's planned Action Tag is cancelled and replaced by a "return" tag placed 5 slots ahead of the goal — 5 Turns, not seconds, so the return cadence follows the same configurable per-slot time. When the return tag fires, the puck re-enters at the nearest free Tile and places its next Action Tag as usual. (Applied in Settle Time, per the membership-change rule.)
- **Pause**: Allowed at any Timing. Pausing freezes the battle clock and all timing progression in place without changing the active Timing or losing fractional Turn progress; unpausing resumes from the exact paused state.
- **Fast Play (Single-Player)**: A switch button on the battlefield screen (enabled in single-player games) toggles Fast Play. When enabled, time scale / progression speed is accelerated across all time-driven Timings (`Charging Time`, `Action Time`, `Puck-puck Time!`, `Settle Time`), while `Play Time` and `Prepare Time` are unaffected because they wait for user actions.
- **Terminology**: "Shot Resolution" is retired everywhere in favour of "Puck-puck Time!".

## Testing Decisions

- **Seam: the TimingManager's public surface — its signals and its input methods** (charge-slot-completed, play pressed/cancelled, cue-shot fired, all-pucks-at-rest, actions-finished). Tests drive these inputs and assert on emitted Timing transitions. No other seam is introduced; battle systems are faked behind the signals.
- A good test asserts **external behaviour only**: which Timing is active and which transitions fire for a given input sequence — never internal node structure, timers, or private state.
- **Modules tested**: the TimingManager only. Physics, damage numbers, AI and card effects are out of the test harness; pucks' "at rest" state and units' Action Tags are stubbed.
- Key cases: entering Prepare sets Energy to 10 and places initial tags (board then freezes); Charging → Play → cancel → Charging; the once-per-slot Play rule; Charging past a tagged slot → Action; same-slot tag ordering (buff/debuff first, spawn order, cue-shot last); cue-shot from Play or from a Knight → Puck-puck Time! → (events ? Settle : skip) → Charging; staged damage applied only at Settle; pausing/resuming at any Timing preserves active Timing and progress; Fast Play switch accelerates Charging, Action, Puck-puck Time!, and Settle while leaving Play Time and Prepare Time unaffected (single-player only).
- **Prior art**: none in-repo — this introduces `res://tests/` with `test_*.gd` suites, matching the repo's MCP test-runner discovery convention.

## Out of Scope

- Implementing the actions themselves — auto-attacks, AI movement, Knight cue-shot behaviour, buff/debuff effects (tag priority TBC).
- Card effects beyond the transition direction they cause (covered by the card-effects spec).
- The VFX themselves (banner animation, collision particles, damage numbers) — only the Timing transitions that trigger them.
- Pocket Area damage/return mechanics, defeat/game-over flow (covered by the cue-table and stage-wave-loop specs).
- Non-battle scenes (World Map, Codex, Deck-editing, Training) — this clock runs inside the Battlefield Scene only.

## Further Notes

- The timing system has no code yet; this is a new subsystem, not a refactor.
- Once implemented, `dragon_player.gd`'s free movement and `base_enemy.gd`'s always-on AI must be gated by the Timing signals — that wiring is part of this spec, redesigning those behaviours is not.
- Open design points explicitly parked during the grilling session: buff/debuff tag priority, additional Settle triggers, per-unit slot offsets (tuned per Class).

## Temporary Test Scaffolding (To Replace / Remove Later)

The following temporary scaffolding was added in `src/demo_bettlefield.tscn` and `src/battlefield/demo_battlefield.gd` while implementing ticket 01 before Cue-Shot and Action Tags exist:

- [ ] **Temporary `Action` button & 5-second `Action Time` timer (`ActionButton` in `demo_bettlefield.tscn`, `ACTION_PLACEHOLDER_SECONDS` in `demo_battlefield.gd`)**: Added below the Pause button to manually enter `Action Time` and let Enemy Heroes move/attack for 5 seconds before returning to the next timing phase. **Must be removed** once Action Tags on the Time Board and true unit Action Time execution (ticket 03) are implemented.
- [ ] **Temporary `Space`-key transition from `Play Time` → `Puck-puck Time!` and 5-second `Puck-puck Time!` timer (`_unhandled_input` `KEY_SPACE` and `PUCK_PUCK_PLACEHOLDER_SECONDS` in `demo_battlefield.gd`)**: Pressing `Space` in `Play Time` currently triggers `fire_cue_shot()` and ends `Puck-puck Time!` after 5 seconds as a placeholder before Cue-Shot exists. **Must be removed** and replaced by real drag-to-aim Cue-Shot launch and physics all-pucks-at-rest detection (ticket 04 + `cue-shot-energy`).

