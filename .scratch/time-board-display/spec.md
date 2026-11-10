# Spec: Time Board Display

Status: ready-for-agent

The HUD board at the top of the battlefield canvas that visualizes battle time — the Energy Bar (fill + charging progress) and the Action Tags on two 10-slot bars. Vocabulary per `.docs/contexts/battlefield.md` (Time Board, Energy Bar, Action Tag, Turn, the six Timings); settled in the grilling session; raw sources `.docmanual/battleField/timingSystem/timeBoardDisplay.md` and `timingSystem.md`. Depends on the TimingManager signal surface from `.scratch/timing-system/spec.md`, but is not blocked by its implementation (the model seam can be driven directly).

## Problem Statement

Battle time is governed by six Timings, Energy charging, and per-unit Action Tags — but none of it is visible. Without a board, the player cannot tell how much Energy they have, when the next slot finishes charging, or which turn each Enemy Adventurer acts on — the "anticipate and plan" core of the auto-battler half of the game. The design also has display-specific rules (two bars, goal at upper-left, tags independent of Energy, membership updates in Settle Time) that need a single home rather than being re-derived inside the HUD.

## Solution

A Time Board component on the battlefield canvas, split into a pure **model** (the board's logical state: energy, charge progress, per-slot aggregated tags, freeze state) and a dumb **view** (slots, fill, tag arrows, integers, animations). The model translates TimingManager signals into board state and is the single place where many units become one visual tag; the view renders model state and runs all motion (smooth glide, fades, teleport wrap, spend rewind) locally. Unit icons on the canvas show the same Turns-to-goal integer, driven from the same model so the board and the battlefield never disagree.

## User Stories

1. As a player, I want a Time Board at the top of the battlefield canvas, so that I can read the battle's timing state at a glance.
2. As a player, I want the board laid out as two bars of 10 slots (upper and lower), so that 20 slots fit the screen width.
3. As a player, I want contents to travel left→right on the lower bar, cross at the right end, then travel right→left on the upper bar toward a goal at the upper-left slot, so that there is one legible path through the board.
4. As a player, I want my Energy shown as a fill along that path starting from the lower-left, so that I can see how much I own.
5. As a player, I want the currently charging slot to fill progressively over the Turn, so that I can feel the clock's pace.
6. As a player, I want everything on the board to glide smoothly at one slot per Turn, so that the board feels alive during my thinking time.
7. As a player, I want a slot completing to clearly mean "a new Energy is ready" or "an Action Tag arrived," so that events read as consequences of the same tick.
8. As a player, I want the fill to stop at 20 while tags keep moving, so that a full board doesn't freeze time.
9. As a player, I want spending Energy to rewind the fill with a quick animation — even though the board is otherwise frozen outside Charging Time — so that the cost of my shot is visible feedback, not a silent number change.
10. As a player, I want Action Tags drawn as simple arrows pointing into the bar (above the upper bar, below the lower bar), so that I can distinguish tags from the energy fill.
11. As a player, I want each tag to show how many Turns until it reaches the goal, so that I know when units act.
12. As a player, I want each tag to show how many units share it, so that one arrival can read as a big moment.
13. As a player, I want tags to NOT name their units, so that the board stays readable with many units in play.
14. As a player, I want the same Turns integer on each unit's icon on the battlefield, so that I can connect "my Knight's 4" to the tag showing 4.
15. As a player, I want a tag crossing from the lower bar to the upper bar to fade out and fade in at the upper-right, so that the wrap is a readable transition rather than a jump cut.
16. As a player, I want tags to count down as they glide, so that the integers always match the board.
17. As a player, I want a tag arriving at the goal to fire Action Time, so that the board predicts the battle's rhythm.
18. As a player, I want firing tags pinned at the goal during Action Time with their unit count ticking down as each unit acts, so that I can follow who has acted and who is left.
19. As a player, I want each unit's replacement tag to fade in as its action completes, so that the board refills in the same rhythm as the action sequence.
20. As a player, I want firing tags to vanish when Action Time ends, so that the board resets cleanly to Charging Time.
21. As a player, I want the board to freeze instantly when I press Play mid-Turn and resume the same Turn when I cancel, so that pausing never grants or steals charge progress.
22. As a player, I want tag changes from units being defeated or entering the table to apply during Settle Time, so that the board updates in the same beat as the event display.
23. As a player, I want a tag whose last unit is gone to disappear, so that the board never promises an action that can't happen.
24. As a player, I want a unit entering the table to join an existing tag for its acting slot when there is one, so that the board stays compact.
25. As a player, I want a pocketed unit's planned tag cancelled and replaced by a "return" tag 5 Turns ahead, so that I can see when it comes back.
26. As a player, I want the returning unit to place a fresh Action Tag after re-entering, so that its rhythm restarts visibly.
27. As a player, I want the board to animate to the next Wave's opening state when Prepare Time begins — Energy to 10, old tags cleared, the new team's tags placed — then freeze, so that I can read the board and plan before pressing Start Wave.
28. As a player, I want no text on the board beyond the integers, so that the display stays language-neutral (revisit after the demo).
29. As a developer, I want the board's logical state in a pure model with no rendering, so that I can test every rule without a viewport.
30. As a developer, I want the model to aggregate per-unit tag events into per-slot tags, so that the "many units, one arrow" rule lives in exactly one place.
31. As a developer, I want the view driven only by model state/signals, so that animation code never contains rules.
32. As a developer, I want unit-icon integers sourced from the same model, so that board and canvas can never disagree.
33. As a developer, I want the model fed by the TimingManager signal surface (faked in tests), so that this feature stays unblocked until the clock exists.
34. As a designer, I want the Turn duration to remain the single configurable knob (default 1s), so that pocket returns (5 Turns), tag cadence and charging all retune together.

## Implementation Decisions

- **Two modules: a pure model and a dumb view.** The model owns all board state and rules: Energy amount, current-slot charge progress (fractional, so a mid-Turn freeze can resume), per-slot aggregated tags, freeze state. The view owns only rendering and animation: slot layout, fill, tag arrows, integers, glide tweens, fades, the spend-rewind animation. No rule in the view; no node reference in the model. (User-chosen architecture: split model from view, tested separately.)
- **Model is fed by the TimingManager signal surface** from the timing-system spec (Timing changes, per-Turn ticks, per-unit tag events: placed / acted / defeated / pocketed / added). The model translates those unit-level events into board-level state; battle systems are faked behind the signals in tests, per the existing seam.
- **One tag per slot.** The model aggregates units sharing a slot into a single tag carrying a unit count and a Turns-to-goal integer (= its slot distance to the goal). Unit identity is tracked only to keep counts and replacements correct — never displayed.
- **Tags are independent of Energy.** They share the board and the Turn tick, nothing else. Tag placement is goal-anchored: a unit acting at offset N places its next tag N slots back from the goal, so integer = distance-to-goal = offset. (Corrects the timing spec's original "ahead of the current slot" wording — already updated there.)
- **Serpentine geometry.** Slot 0 at the lower-left, slot 9 at the lower-right, slot 10 at the upper-right, slot 19 (the goal) at the upper-left. The energy fill grows from slot 0; tags travel toward slot 19. Crossing 9→10 is a fade-out/fade-in teleport, not a slide; everything else glides smoothly at one slot per Turn.
- **Energy cap.** At 20 the fill stops but Turns keep ticking and tags keep moving; overcharged Energy is discarded.
- **Spend rewind is an effect, not time.** Spending Energy rewinds the fill with a quick animation wherever it happens (normally Play Time); the board otherwise does not move over time outside Charging Time. Future effects (gain/drain/shift) move the board the same way.
- **Action Time lifecycle.** Firing tags pin at the goal; the unit count decrements as each unit acts; each acting unit's replacement tag fades in when its action completes; firing tags vanish when Action Time ends.
- **Membership changes apply in Settle Time.** Defeated units decrement their tag; count reaching zero removes the tag. A unit entering the table joins an existing tag on its acting slot or creates a new tag there.
- **Pocket rule (display half).** A pocketed unit's planned tag is cancelled and replaced by a "return" tag placed 5 slots ahead of the goal (5 Turns — follows the configurable per-slot time, no wall-clock durations). When the return tag fires, the puck re-enters at the nearest free Tile and places its next Action Tag normally. Cancellations/replacements apply in Settle Time per the membership rule.
- **Prepare Time display.** On Prepare entry the board animates to the coming Wave's opening state — Energy to exactly 10, all old tags removed, the incoming Adventurer Team's initial tags placed — then freezes for the rest of the phase so the player can plan. (Already corrected in the timing spec.)
- **Unit-icon integers.** The Turns integer on each unit's canvas icon is driven from the same model (per-unit lookup of its tag's distance-to-goal), following the existing unproject-to-screen pattern used for enemy health bars.
- **Board state per Timing:** Charging = running; Play / Action / Puck-puck / Settle = frozen except effect-driven moves and the lifecycle updates above; Prepare = animate-once-then-frozen as above.
- **No text on the board** beyond the two integers per tag — nothing added to `src/multiLang` for this feature; revisit after the demo.
- **Timings and names** come from `.docs/contexts/battlefield.md` verbatim (Time Board, Energy Bar, Action Tag, Turn, goal, Puck-puck Time!).

## Testing Decisions

- **Seams (user-approved): two.** (1) The TimingManager signal surface — faked in model tests, per the timing spec's existing seam. (2) The model→view boundary — the view is tested against crafted model states. No deeper seams; rendering internals (tweens, node names, layout constants) are never asserted.
- **A good model test asserts logical state only**: energy amount, current-slot progress fraction, the per-slot tag map (position, count, turns-to-goal), freeze state — given a scripted sequence of TimingManager-shaped signals. E.g. wave-start state (10 Energy + initial tags at goal−N), a tick landing a tag on the goal, count decrement on a unit-acted event, zero-count removal, join-or-create on a unit-added event, pocketed → return tag at goal−5, Prepare-entry opening state, freeze/resume mid-Turn preserving the progress fraction, cap behavior at 20.
- **A good view test asserts renderable output for a crafted model state**: a tag on slot 3 renders below the lower bar showing that slot's count and distance-to-goal; slot 14 renders above the upper bar; arrows point into the bar; slot 19 is the goal; a model change requests the right animation kind (glide vs fade-teleport vs rewind) without asserting tween parameters. External observation only.
- **Unit-icon integers**: test the model's per-unit turns lookup, not the unprojection math (prior art for the projection itself: enemy health bars on the canvas).
- **Prior art**: the timing-system spec introduced `res://tests/` with `test_*.gd` suites run by the MCP test runner — same discovery convention, same signal-faking approach; `card_manager.gd` (logic + signals) rendered by `card_canvas.gd` (view) is the architectural precedent for the model/view split.
- Animation timing, fade curves, colors and sizes are explicitly NOT tested — they are tuned visually in the editor.

## Out of Scope

- The TimingManager itself and all Timing transition logic (the timing-system spec) — this feature only consumes its signal surface.
- The actions themselves (auto-attacks, AI, Knight cue-shot, buff/debuff priority), card effects, defeat/game-over flow, pocket damage values (other specs).
- All VFX and final styling: colors, fade durations, exact animation parameters, tag/arrow art.
- Any text or localization for the board (deferred until after the demo).
- The CanvasLayer boss/enemy health bars (existing canvas feature; only the unit-icon Turns integer is added there).
- Non-battlefield scenes.

## Further Notes

- No code exists yet for either module; this is a new subsystem, not a refactor. It lands in the HUD area alongside the existing canvas scripts.
- The model/view split was the user's explicit choice over testing through a single signal seam — keep both seams narrow and resist adding a third.
- Parked during grilling (not blocking): per-unit slot offsets are tuned per Class (timing spec); whether board text labels return post-demo; visual treatment of the goal slot itself.
- If the timing-system implementation changes its signal surface, update this spec's model inputs to match rather than inventing a parallel wiring.
