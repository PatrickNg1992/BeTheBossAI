# Spec: Enemy Adventurers

Status: ready-for-agent

The Enemy Adventurer logic: stats model, the decide-at-Settle action loop, Focusing and Interrupts, scripted glide movement, and seeded generation. Vocabulary per `CONTEXT.md` and `.docs/contexts/battlefield.md`; movement and damage-channel rules per ADR-0001 and ADR-0002. Settled in the grilling session; raw sources `.docmanual/battleField/enemyAdventurer/`. Supersedes the previous version of this spec (shared wander/chase/attack AI), whose collision matrix is carried forward.

## Problem Statement

Enemy Adventurers are the player's only opposition, and today they are a throwaway prototype: a shared wander/chase/attack state machine with hard-coded stats, running continuously with no regard for the timing system — exactly the design ADR-0001 rejected. There is no connection to Action Tags, no visible warning before attacks, no interrupt counterplay, no level scaling, and no generation logic behind a Stage's Adventurer Teams. Without the real Adventurer logic, the battlefield has no readable threats and the "snooker with cards" fantasy has nothing to knock around.

## Solution

Every Enemy Adventurer lives on the Time Board. A adventurer owns one base-action Action Tag (its next move *or* attack) plus one tag per active skill, so the player can always see who acts when. Adventurers re-decide at every Settle Time from the current table state: if a adventurer's class attack condition holds it enters **Focusing** — a full, board-visible countdown with lighting VFX while the puck stands stationary — and the attack lands only when the tag fires. Collisions hard-interrupt the Focus (with per-class consequences); broken conditions soft-interrupt it at the next Settle Time. Movement is a fast scripted glide (physics disabled) per ADR-0002; attacks are scripted damage events per the Auto-Attack rule — except the Knight, whose attack is a physical self Cue-Shot. Adventurer Teams are rolled when the Stage begins from a seed: same seed, same team; spawn positions and card order stay fresh per attempt.

## User Stories

1. As a player, I want to see each Adventurer's icon, Class, HP bar, team number and colour in the Unit Information Board, so that I can read the enemy team at a glance.
2. As a player, I want each adventurer's box to show the turns until its next basic attack and active skill, so that I know who is dangerous soonest.
3. As a player, I want adventurers acting on the same turn to share one Action Tag with a count, so that the board stays readable with many adventurers.
4. As a player, I want a defeated adventurer's icon greyed with a red cross and its bars hidden, so that I instantly know it is out.
5. As a player, I want a pocketed adventurer greyed with a return countdown, so that I know when it comes back.
6. As a player, I want a Focusing adventurer to show lighting VFX, so that I get a clear warning to react.
7. As a player, I want every enemy attack preceded by a full board-visible countdown, so that I always have time to take appropriate action.
8. As a player, I want colliding with a Focusing Warrior to deal it bonus damage, so that a timely hit is rewarded.
9. As a player, I want colliding with a Focusing Mage to simply cancel its chant, so that I can neutralize the frailest but hardest-hitting class.
10. As a player, I want colliding with a Focusing Ranger to force it to spend an action Recovering, so that a hit costs it tempo.
11. As a player, I want colliding with a Focusing Knight to hurt me and barely hurt it — but still cancel its attack, so that the play is risky yet useful.
12. As a player, I want adventurers to re-decide after every change on the table, so that knocking enemies out of position meaningfully disrupts their plans.
13. As a player, I want a Focusing adventurer whose target left its range to abandon the attack at the next Settle Time, so that repositioning is a real defensive tool.
14. As a player, I want enemy attacks (except the Knight's) to deal damage without applying force, so that the board state stays predictable.
15. As a player, I want the Knight's attack to be a physical self Cue-Shot, so that it produces dramatic, readable physics moments.
16. As a player, I want damage during Puck-puck Time! shown as a ghost HP trail and applied only at Settle Time, so that chain collisions play out completely.
17. As a player, I want adventurer moves to be fast glides, so that Action Time never drags.
18. As a player, I want gliding adventurers to pass through other pucks and Pocket Areas, so that movement never causes surprise physics.
19. As a player, I want adventurers to never end a move on a Pocket Area or overlapping another puck, so that the board stays fair and readable at rest.
20. As a player, I want high-FRQ adventurers to act more often on the Time Board, so that enemy speed is legible.
21. As a player, I want the Mage to reach nearly the whole table, so that it must be prioritized or interrupted.
22. As a player, I want adventurers to target my nearest puck, so that threats are predictable.
23. As a player, I want the same seeded Stage to field the same adventurer compositions, so that I can learn and plan against a known team.
24. As a player, I want spawn positions and card order to vary per attempt, so that the same team still plays differently.
25. As a player, I want every Adventurer Team to contain all four Classes, so that every Wave demands varied tactics.
26. As a player, I want teams of 1-6 adventurer and at most 2 teams for a wave, so that the screen stays readable.
27. As a player, I want each Class to keep a distinct stat identity (ratios), so that I can learn what a Warrior or a Mage means at a glance.
28. As a player, I want higher-LV adventurers to be proportionally tougher and harder-hitting (linear scaling), so that enemy strength is readable.
29. As a player, I want adventurers to carry at most one active skill plus any number of passives, so that same-class adventurers still differ without becoming unreadable.
30. As a player, I want Legendary Heroes to be tailor-made and free to break class rules, so that stages have memorable headline enemies.
31. As a player, I want at most one Settle Time per Turn, so that the pace never fragments.
32. As a player, I want wave-opening Action Tags randomly staggered, so that a wave doesn't open with a wall of simultaneous actions.
33. As a developer, I want adventurer decisions computed from a table snapshot at Settle Time, so that the decision logic is testable without physics or rendering.
34. As a developer, I want generation deterministic per seed, so that battles are reproducible and testable.
35. As a developer, I want the demo seed as a plain code variable, so that QA can pin compositions (daily seed is real-game work).
36. As a developer, I want fixed wave sizes in the demo Stage, so that tests have a stable fixture; budget-driven generation ships with the real game.
37. As a developer, I want a per-stage configurable wave budget hook, so that difficulty tuning is data, not code.
38. As a developer, I want the two puck movement modes (scripted glide / physics) cleanly separated, so that no state bleeds between them (ADR-0002).
39. As a designer, I want the class table to stay relative ratios with ratio→absolute mappings in one place, so that class identity and power level are tuned independently.
40. As a designer, I want LV scaling linear with the formula decided alongside the growth system, so that balancing has one obvious knob.

## Implementation Decisions

- **Rebuild, don't migrate.** The prototype enemy code (shared wander/chase/attack state machine, hard-coded stats, always-on movement) is discarded wholesale. No interface from it survives.
- **Adventurer Brain module.** Computes one adventurer's decision from an immutable table snapshot, evaluated for every adventurer at every Settle Time (the TimingManager exposes a Settle hook). Outputs are plain decisions: place attack tag (enter Focusing), place move tag + destination, cancel/retarget a pending attack, or no-op. No node, physics, or rendering dependencies — this is the primary unit-test surface.
- **Adventurer Action Executor module.** Executes fired tags: scripted constant-speed glides (physics disabled; pass-through allowed; destination must be a free Tile that is not a Pocket Area and keeps separation from all pucks at rest; glide speed scaled to keep Action Time snappy) and scripted attacks (simple animation + staged damage, never force). The Knight's attack is the sole exception: it launches a self Cue-Shot and transitions to Puck-puck Time! per the timing-system spec.
- **Tag model.** One base-action tag (move or attack) plus one tag per active skill; passives never place tags. Tags stay typeless and share purely by turns-remaining, per the Time Board rules. Offsets derive from the class FRQ ratio; wave-opening tags add a small random stagger. Placement, merging, firing, and membership cleanup ride the TimingManager's existing Action Tag machinery.
- **Focusing state.** Entered only at Settle Time when the class condition (usually range to target) holds: place a full-countdown attack tag, VFX on, stationary. While Focusing, in-range target shifts retarget silently; the attack fires when the tag reaches the goal.
- **Interrupts.** Hard (collision with a Focusing puck): cancel tag + Focus immediately at the next Settle Time, with class texture — Warrior takes bonus collision damage; Ranger places a Recovery action tag and is stunned until that tag fires; Mage is plain-cancelled; Knight still deals damage and takes reduced damage on the collision, but loses its Focus like any other class. Soft (condition broken by position changes, card effects): the adventurer abandons the attack and re-decides at the Settle Time evaluation. Tag membership changes apply at Settle Time only.
- **Stats model.** Class table = relative ratios (HP / Power / ATK FRQ / SPD / RNG). Absolute HP and Power = ratio × linear LV scale, landing in the thousands; the formula is decided with the growth system. FRQ → tag offsets, SPD → glide distance per move action, RNG → attack distance (Mage ≈ whole-table reach). All ratio→absolute mappings live in one balancing table.
- **Targeting.** Nearest player-side puck (the Boss Monster only, until Minions exist). Refinement is future work.
- **Generation module.** `generate(seed, stage config) → the full Stage's Adventurer Teams`, rolled once when the Stage begins (per the Stage rule). Follows the documented step order: wave budget → legendary placement → per-wave counts → classes (constraint: every Class present in every team; 4–10 common, hard cap 12) → skills (0–1 active, any passives, from a shared pre-defined pool) → equipment (no-op hook) → LV tuned last to fit budget. The seed pins composition only — never spawn positions (random free Tiles per attempt) nor card order. Demo: seed is a code variable and wave sizes are fixed by the demo Stage config; budget-driven difficulty is real-game work, configured per stage as a plain number.
- **Collision matrix (carried forward, unchanged).** Above a small speed threshold: Enemy Adventurers suffer Collision Damage from any impact — except impacts with a Knight, which protects its allies; only Knight impacts damage the Boss Monster, whoever initiated; Cushion impacts deal no damage. Two damage channels stay total and separate: Auto-Attack (scripted, Action Time) vs Collision Damage (physics, Puck-puck Time!) — ADR-0002.
- **At most one Settle Time per Turn.** Everything settle-worthy in a Turn settles together — a refinement of the timing-system spec's Settle rules.
- **Profile visualization state.** Each adventurer exposes the state the Unit Information Board renders: icon, HP, Class, team number/colour, per-action turns-remaining, defeated (grey + red cross, bars hidden), pocketed (grey + return countdown). The UI itself is a separate consumer.
- **Terminology.** The adventurer attack-preparation state is **Focusing** (the Mage's flavour: Chant) — never "charging", which belongs to Energy/Charging Time.

## Testing Decisions

- **One seam, confirmed with the developer: the headless battle harness.** Tests instantiate TimingManager + Time Board + the real adventurer roster with physics faked (except where Puck-puck Time! is explicitly under test), drive the timing inputs — charge a slot, enter Play Time, fire a synthetic collision, complete a Settle — and assert only externally observable state: Action Tags on the board, adventurer state (idle / Focusing / Recovering), staged vs applied HP, post-glide positions. Generation is exercised through the same harness's stage-setup entry.
- **A good test asserts external behaviour only** — decisions, tags, state, and damage visible at the seam — never node structure, timers, tween state, or private fields.
- **Modules tested:** the adventurer Brain (decision logic), the Adventurer Action Executor (via post-action state), and the Generation module (via produced rosters). The TimingManager itself is covered by its own spec's tests; here it is a collaborator.
- **Key cases:** same seed → identical composition, different seed → different; composition rules (4–10, cap 12, every Class present); demo fixed sizes honoured; condition met at Settle → Focusing + attack tag; tag fires → scripted damage staged, no force applied; Knight tag fires → Puck-puck Time!; target leaves range → soft interrupt at next Settle; hard interrupt per class (Warrior bonus damage staged; Ranger Recovery tag placed and recovery on its firing; Mage plain cancel; Knight cancel + collision punishment); glide destination rules (never rests on a Pocket Area, never overlaps, pass-through mid-glide allowed); defeat applied only at Settle (ghost HP until then); pocketed adventurer → return tag → re-entry on nearest free Tile; initial-tag stagger; one Settle per Turn cap.
- **Prior art:** none in-repo — the timing-system spec introduced the `res://tests/test_*.gd` convention and this suite follows it.

## Out of Scope

- Legendary Hero designs (tailor-made, rule-breaking; no spec yet) — the generation hook for placing them ships, their content does not.
- The combat-power budget formula, difficulty growth curve, LV formula, and all ratio→absolute mapping values — decided with the growth system / balancing.
- Skill pool contents (samples to be designed later); the equipment system (generation hook only).
- Target-selection refinement beyond nearest-puck.
- Unit Information Board rendering, lighting VFX, attack animations, damage numbers, and localization strings — visual/manual concerns.
- Minions (future system), card effect payloads (card-effects spec), the Codex scene, and the wave/stage flow itself (stage-wave-loop spec).
- The physics simulation; Pocket Area damage/return mechanics (cue-table spec).

## Further Notes

- This spec supersedes the previous enemy-adventurers spec (shared wander/chase/attack AI) — that premise died with ADR-0002; only its collision matrix survived, carried forward above.
- Two cross-spec touch-ups flagged and ruled by the developer: stage-wave-loop's "spawn along the four Cushions" is dead (spawn = any random free Tile), and its fixed wave sizes are demo-scope only (real game = budget-driven). Update that spec when it is next touched.
- Explicitly parked during grilling: buff/debuff tag priority (timing spec), additional Settle triggers, legendary spec, budget/growth formula, skill samples, equipment.
- ADR-0002 (hybrid movement) was written during the grilling session and is part of this spec's foundation; ADR-0001's steering consequence was amended accordingly.
