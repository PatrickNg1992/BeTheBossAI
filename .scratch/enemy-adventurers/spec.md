# Spec: Enemy Adventurers

Status: ready-for-agent

The Enemy Adventurer logic: stats model, the decide-at-Settle action loop, Focusing and Interrupts, scripted glide movement, and seeded generation. Vocabulary per `CONTEXT.md` and `.docs/contexts/battlefield.md`; movement and damage-channel rules per ADR-0001 and ADR-0002. Settled in the grilling session; raw sources `.docmanual/battleField/enemyAdventurer/`. Supersedes the previous version of this spec (shared wander/chase/attack AI), whose collision matrix is carried forward.

## Problem Statement

Enemy Adventurers are the player's only opposition, and today they are a throwaway prototype: a shared wander/chase/attack state machine with hard-coded stats, running continuously with no regard for the timing system — exactly the design ADR-0001 rejected. There is no connection to Action Tags, no visible warning before attacks, no interrupt counterplay, no level scaling, and no generation logic behind a Stage's Adventurer Teams. Without the real Adventurer logic, the battlefield has no readable threats and the "snooker with cards" fantasy has nothing to knock around.

## Solution

Every Enemy Adventurer lives on the Time Board under a **Fixed 12-Turn Action Cycle** (`.docmanual/battleField/enemyAdventurer/adventurerActions.md`). Each Adventurer has a single fixed **Action Countdown** that must be a factor of 12 (`3`, `4`, or `6` — typically `4` for Guard and Brawler trees, `3` for Scout tree, `6` for Acolyte tree, modifiable by passive skills to another fixed factor), so `Action Time` only occurs at turns `3, 4, 6, 8, 9, 12` of the 12-turn cycle (with 12-interval tags highlighted in a special colour). When `Action Time` triggers, the acting Adventurers execute in a deterministic order (buff/debuff first, then spawn order, cue-shot actions last) **without waiting for the previous unit's animation or movement to finish before starting the next unit's action**. Each acting Adventurer checks its skills in `Active Skill → Attack Skill → Move Skill` order (gated by each skill's internal `Skill Countdown`, `.docmanual/battleField/unitInformation/unitSkills.md`), and resets its Action Tag at the end of `Settle Time`. Existing base skills (`SMA10001..10004`, `SAA10001..10004`, `SPA10001..10002`) take effect immediately in `Action Time` and are non-interruptible (future interruptible skills that enter **Focusing** before firing will be designed later). Movement is a fast scripted glide (physics disabled, overlap resolved after stopping) per ADR-0002; attacks are scripted damage events per the Auto-Attack rule. Adventurer Teams are rolled when the Stage begins from a seed: same seed, same team; spawn positions (TBC) and card order stay fresh per attempt.

## User Stories

1. As a player, I want to see each Adventurer's icon, Class, HP bar, Reference Mark (`G, B, S, A, F, E` / `g, b, s, a, f, e`) and Class Tree colour in the Unit Information Board, so that I can read the enemy team at a glance.
2. As a player, I want each adventurer's box to show its Action Countdown turns until its next action, so that I know who acts soonest.
3. As a player, I want adventurers acting on the same turn to share one Action Tag with a count, so that the board stays readable with many adventurers.
4. As a player, I want a defeated adventurer's icon greyed with a red cross and its bars hidden, so that I instantly know it is out.
5. As a player, I want a pocketed adventurer greyed with a return countdown, so that I know when it comes back.
6. As a player, I want every Adventurer to have a fixed Action Countdown that is a factor of 12 (`3`, `4`, or `6`, with 12-interval tags highlighted), so that Action Time only happens at predictable intervals (`3, 4, 6, 8, 9, 12`) and I don't constantly wait for enemies to act.
7. As a player, I want acting adventurers in Action Time to trigger in deterministic order without waiting for the previous unit's animation or movement to finish, so that Action Time feels smooth and fast.
8. As a player, I want each acting adventurer to check `Active Skill → Attack Skill → Move Skill` in order (respecting any per-skill `Skill Countdown` and `Skip Movement` rules), so that unit behaviour is consistent and readable.
9. As a player, I want existing base skills (`SMA10001..10004`, `SAA10001..10004`) to take effect immediately and non-interruptibly in Action Time, while supporting future interruptible Focusing skills later.
10. As a player, I want Guard's base passive skill `Protect` (`SPA10001`) to reduce the opponent Boss Monster's Frenzy Power on hit based on surviving non-Guard-tree teammates (`X * (4% + Lv * 1%)`, offsetting the normal `+10%`), and Scout's base passive skill `Safety Rope` (`SPA10002`) to reduce teammates' Pocket Area damage (`-(10 + Lv * 3)%`), so that base classes have distinct passive team roles.
11. As a player, I want enemy attacks to deal damage without applying force (unless a specific future skill explicitly launches a self Cue-Shot), so that the board state stays predictable.
12. As a player, I want damage during Puck-puck Time! and Action Time shown as a ghost HP trail and applied only at Settle Time, so that chain collisions and actions play out completely.
13. As a player, I want adventurer moves to be fast glides that ignore puck collisions while moving and resolve any overlap after stopping, so that Action Time never drags or causes surprise physics.
14. As a player, I want adventurers to never end a move on a Pocket Area or overlapping another puck, so that the board stays fair and readable at rest.
15. As a player, I want Scout-tree adventurers (`Action Countdown = 3`) to act more often than Guard/Brawler-tree (`4`) and Acolyte-tree (`6`) adventurers on the Time Board, so that enemy speed is legible.
16. As a player, I want the Acolyte's `Spell Attack` (`SAA10004`, `Skill Countdown = 12`) to target the opponent Boss Monster from anywhere on the table while its `Move Away` (`SMA10004`) keeps it on the far side of the table, so that it must be prioritized.
17. As a player, I want the same seeded Stage to field the same adventurer compositions, so that I can learn and plan against a known team.
18. As a player, I want spawn positions (TBC) and card order to vary per attempt, so that the same team still plays differently.
19. As a player, I want Adventurer Waves/Teams to normally contain pucks from all four Class Trees (with missing class trees allowed as an uncommon case), so that waves demand varied tactics.
20. As a player, I want teams of 1-6 adventurers and at most 2 teams for a wave, so that the screen stays readable.
21. As a player, I want each Class to keep a distinct stat identity (ratios) and default puck mass/radius (defined in `.docmanual/codexList/classes/`), so that I can learn what a Brawler or an Acolyte means at a glance.
22. As a player, I want higher-LV adventurers and upgradable skills (`Lv`) to scale proportionally, so that enemy strength is readable.
23. As a player, I want adventurers to carry 1 Move Skill, 1 Attack Skill, at most 1 Active Skill, and multiple Passive Skills, all inspectable in the Unit Detail Display, so that same-class adventurers still differ without becoming unreadable.
24. As a player, I want Heroes (superior Adventurers with Exceptional Classes) to be tailor-made and free to break class rules, so that stages have memorable headline enemies.
25. As a player, I want at most one Settle Time per Turn, so that the pace never fragments.
26. As a developer, I want generation deterministic per seed, so that battles are reproducible and testable.
27. As a developer, I want the demo seed as a plain code variable, so that QA can pin compositions (daily seed is real-game work).
28. As a developer, I want fixed wave sizes in the demo Stage, so that tests have a stable fixture; budget-driven generation ships with the real game.
29. As a developer, I want a per-stage configurable wave budget hook, so that difficulty tuning is data, not code.
30. As a developer, I want the two puck movement modes (scripted glide / physics) cleanly separated, so that no state bleeds between them (ADR-0002).
31. As a designer, I want the class table to stay relative ratios with ratio→absolute mappings in one place, so that class identity and power level are tuned independently.
32. As a designer, I want LV scaling linear with the formula decided alongside the growth system, so that balancing has one obvious knob.

## Implementation Decisions

- **Rebuild, don't migrate.** The prototype enemy code (shared wander/chase/attack state machine, hard-coded stats, always-on movement) is discarded wholesale. No interface from it survives.
- **Unit Skill Hierarchy (`UnitSkill` → `MoveSkill`, `AttackSkill`, `ActiveSkill`, `PassiveSkill`).** Per `.docmanual/battleField/unitInformation/unitSkills.md` and `.docmanual/battleField/enemyAdventurer/adventurerSkills.md`, every Adventurer equips 1 Move Skill, 1 Attack Skill, 0–1 Active Skill, and 0..N Passive Skills. The 4 Base Classes default to:
  - **Guard (`ACG10001`)**: `SMA10001 Block`, `SAA10001 Lance` (`Skill Countdown: 9`, `Hit Level+2`, `Skip Movement`), `SPA10001 Protect`
  - **Brawler (`ACB10001`)**: `SMA10002 Approach`, `SAA10002 Melee` (`Hit Level+1`, `Skip Movement`)
  - **Scout (`ACS10001`)**: `SMA10003 Patrol`, `SAA10003 Shoot` (`Hit Level+1`, attacks while moving), `SPA10002 Safety Rope`
  - **Acolyte (`ACA10001`)**: `SMA10004 Move Away`, `SAA10004 Spell Attack` (`Skill Countdown: 12`, `Hit Level+3`, `Skip Movement`)
- **Fixed 12-Turn Action Cycle & Action Execution.** Each Adventurer has one fixed `Action Countdown` that is a factor of 12 (`3` for Scout tree, `4` for Guard and Brawler trees, `6` for Acolyte tree; modifiable by passive skills to another fixed factor). When a Turn reduces an Adventurer's Action Countdown to `0`, `Action Time` begins. All Adventurers at `0` trigger in deterministic order (buff/debuff first, then spawn order, cue-shot actions last) **without waiting for the previous unit's animation or movement to finish before starting the next unit's action**. Each acting unit evaluates `Active Skill → Attack Skill → Move Skill` in order (if an activated Attack/Active Skill has `Skip Movement`, the Move Skill is skipped). At the end of `Settle Time`, acted Adventurers reset their Action Tag to their fixed `Action Countdown`.
- **Immediate Base Skills vs. Future Interruptible / Focusing Skills.** All existing base skills (`SMA10001..10004`, `SAA10001..10004`) are non-interruptible and take effect immediately when their conditions and `Skill Countdown` are satisfied in `Action Time`. The `Focusing` state and collision `Interrupts` are reserved as hooks for future interruptible skills.
- **Stats & Puck Size Model.** Default puck `mass` and `radius` per class live in `.docmanual/codexList/classes/` (Guard: `mass 1.75, radius 0.65`; Brawler: `mass 1.5, radius 0.6`; Scout: `mass 1.35, radius 0.57`; Acolyte: `mass 1.25, radius 0.55`, inherited by advanced classes unless overridden). Class table = relative ratios (HP / Power / ATK FRQ / SPD / RNG).
- **Generation module.** `generate(seed, stage config) → the full Stage's Adventurer Teams`, rolled once when the Stage begins. Follows the documented step order: wave budget → Hero placement → per-wave counts → classes (waves/teams should contain pucks from all four Class Trees; missing class trees are uncommon; 4–12 common, hard cap 12) → skills → equipment (no-op hook) → LV tuned last to fit budget. The seed pins composition only — never spawn positions (spawn logic TBC) nor card order.
- **Collision matrix (carried forward, applied to Class Trees).** Above a small speed threshold: Enemy Adventurers suffer Collision Damage from any impact — except impacts with a same-team Guard (or its advanced classes), which protects its allies; only an opponent Guard (or its advanced classes) deals collision damage to a Boss Monster; Cushion impacts deal no damage (and grant `+1` Hit Level to an Enemy Adventurer hitting a Cushion in `Puck-puck Time!`). When a Boss Monster hits an opponent Adventurer, Boss Frenzy Power increases by `+10%`, and Guard's `SPA10001 Protect` passive skill reduces the Boss Monster's Frenzy Power by `X * (4% + Lv * 1%)` (where `X` is the number of non-Guard-tree teammates).
- **At most one Settle Time per Turn.** Everything settle-worthy in a Turn settles together.
- **Profile visualization state.** Each adventurer exposes the state the Unit Information Board renders: icon, HP, Class, Reference Mark (`G, B, S, A, F, E` / `g, b, s, a, f, e`), Class Tree colour, Action Countdown turns-remaining, defeated (grey + red cross, bars hidden), pocketed (grey + return countdown).

## Testing Decisions

- **One seam, confirmed with the developer: the headless battle harness.** Tests instantiate TimingManager + Time Board + the real adventurer roster with physics faked (except where Puck-puck Time! is explicitly under test), drive the timing inputs — charge a slot, enter Play Time, fire a synthetic collision, complete a Settle — and assert only externally observable state: Action Tags on the board, adventurer state (idle / Focusing / Recovering), staged vs applied HP, post-glide positions. Generation is exercised through the same harness's stage-setup entry.
- **A good test asserts external behaviour only** — decisions, tags, state, and damage visible at the seam — never node structure, timers, tween state, or private fields.
- **Modules tested:** the adventurer Brain (decision logic), the Adventurer Action Executor (via post-action state), and the Generation module (via produced rosters). The TimingManager itself is covered by its own spec's tests; here it is a collaborator.
- **Key cases:** same seed → identical composition, different seed → different; composition rules (4–12, cap 12, waves should contain pucks from all four Class Trees); demo fixed sizes honoured; Fixed 12-Turn Action Cycle (`3`, `4`, `6` Action Countdowns) firing `Action Time` at `3, 4, 6, 8, 9, 12` and resetting at the end of `Settle Time`; `Active Skill → Attack Skill → Move Skill` evaluation order with `Skill Countdown` and `Skip Movement`; base skills (`SMA10001..10004`, `SAA10001..10004`, `SPA10001..10002`) executing immediately and non-interruptibly; glide destination rules (never rests on a Pocket Area, resolves overlap after stopping, pass-through mid-glide allowed); defeat applied only at Settle (ghost HP until then); pocketed adventurer → return tag → re-entry on a random empty Tile inside the middle 80% of the Cue Table; one Settle per Turn cap.
- **Prior art:** none in-repo — the timing-system spec introduced the `res://tests/test_*.gd` convention and this suite follows it.

## Out of Scope

- Hero designs (tailor-made superior Adventurers with Exceptional Classes, rule-breaking; no spec yet) — the generation hook for placing them ships, their content does not.
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
