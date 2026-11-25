# Battlefield Scene

The main scene of the game: one Stage battle, fought as "snooker with cards" — the Boss Monster and Enemy Adventurers are physics Pucks on a Cue Table, and the player also plays cards from their Deck. Stages are selected from the World Map scene. Game-wide terms (Boss Monster, Stage, Deck, Card Type) live in the root `CONTEXT.md`.

## Language

### The Game Loop

**Wave**:
One to Two Adventurer Team assault within a Stage. The player advances by defeating every Enemy Adventurer in the Wave.
_Avoid_: round

**Adventurer Team**:
The group of Enemy Adventurers fielded by one Wave. 1-6 Adventurers, and commonly consists of different Classes.
_Avoid_: mob, enemy wave

**Preparation Phase**:
The rest before each Wave. The coming Adventurer Team stands inert on the table, all cards return to the Deck, and the player draws a fresh hand of 5. No boss movement, no card play.
_Avoid_: checkpoint, break

**Start Wave**:
The player's only Preparation Phase action — ends the phase and activates the previewed Adventurer Team. In a 2-player game (when both Player A and Player B are seated), both players must complete their preparation and press Start Wave before the Wave begins.

### Units

**Enemy Adventurer**:
An enemy puck with a Class. Adventurer Skills are drawn from a shared pre-defined pool — 0–1 active plus any number of passives; equipment is a future concept. Its move action is a scripted constant-speed glide during the Move Skill phase of Action Time with its collider disabled during the movement — before gliding, it resolves a valid **Adjusted Target Position** (inside Cushions, not on a Pocket Area, and not overlapping other pucks, checking against the Adjusted Target Position rather than the original position for moving pucks, searching up to 3 concentric circles of 8 directions at `0.5` distance increments around the raw Target Position, or cancelling the move if none is valid) per ADR-0002.
_Avoid_: chess piece, mob

**Class**:
An Enemy Adventurer's occupation — defined in `.docmanual/codexList/classes/` across the four Rank 1–3 Class Trees (Guard, Brawler, Scout, Acolyte) plus Exceptional Classes for Heroes — fixing its default puck `mass`, `radius`, `Action Countdown` interval (`4` for Guard/Brawler trees, `3` for Scout tree, `6` for Acolyte tree), Base Skills, and linear stat growth formula `{base HP}/{base POW}/{base SPD} + {HP/lv}/{POW/Lv}/{SPD/Lv}` (`stat = base + Lv * per_lv`, inherited by advanced classes unless overridden). `SPD` determines the skill execution order among units acting in the same phase of `Action Time` (and feeds skill formulas) without changing constant glide movement speed.
_Avoid_: type, job

**Minion**:
A future player-side puck, summoned by cards or the Boss Monster. Takes collision damage from puck impacts and gains `+1` Hit Level when hitting a Cushion during `Puck-puck Time!` like any non-Boss puck.
_Avoid_: summon

**Health Bar**:
One segment of a unit's HP. The Boss Monster has several; losing one grants brief invincibility and a card draw. Every Boss Monster's damage taken in a single `Settle Time` is capped at clearing at most one Health Bar (its Ghost HP trail clamps at `0` of the current bar and excess damage never spills into the next bar). Enemy Adventurers have one Health Bar.

**Unit Information Board**:
The HUD board on the left and right edges of the battlefield canvas, arranged as two 2-column × 8-row grids (`{L|R}{Row 1..8}{Col 1..2}`) that display the status of all units in the battle. Replaces floating health bars on the 3D Cue Table.
_Avoid_: Adventurer Team Profile, Hero Team Profile, side panel

**Unit Display**:
One cell on the Unit Information Board (or a 2-column horizontal span for a Boss Monster) showing a single unit's portrait, Reference Mark, Class Mark (for Enemy Adventurers), HP bar with Ghost HP trail, Damage Stack count, and Action Tag turn countdowns. Fixed to the grid position matching the unit's Reference Mark index (unoccupied class slots remain empty rather than compacting).
_Avoid_: unit card, profile box

**Unit Detail Display**:
A popup window alongside the Unit Information Board that shows full stats, status effects, puck properties, and two rows of skill icons (Row 1: Move, Attack, and Active Skill slots, leaving an empty slot if no Active Skill is equipped; Row 2: Passive Skills) for an inspected unit.

**Skill Display**:
A hover tooltip window shown when hovering over a skill icon in the Unit Detail Display. Displays the skill's name, type, skill `Lv`, and `Description` injected with resolved variable values (highlighted in a value colour) and `*keyword*` terms (highlighted in a keyword colour), with the glossary meanings of those keywords listed at the bottom (never displaying raw internal `Effects` implementation text).

**Unit Skill Manager**:
The battle-scoped manager node that owns skill definitions and unit skill bindings, maintains a trigger-time-to-skills lookup map (so event sites dispatch only to skills registered for that trigger time without scanning all skills), evaluates cross-unit skill effects, and recalculates **Statistic Buff/Debuff** values (`round(base_stat_at_lv * (1 + sum_pct) + sum_flat)`).

**Auto Fight Manager**:
The battle-scoped manager node that controls the automated combat flow in `Action Time` (start-of-action passives, followed by `All Active Skills → All Attack Skills → All Move Skills → Pocketed Units Return`, each ordered by `SPD` descending) and `Settle Time` for all units on the battlefield.

**Presentation Manager**:
The battle-scoped manager node that controls visual and sound effects and animations (skill attack animations, constant-speed Move Skill glides, skill popups, Frenzy Power spread, settled damage popups) across `Action Time` and `Settle Time`.

**Reference Mark**:
The short identifier shown on both the upper-left corner of a unit's Unit Display and the center of its Puck(s) on the Cue Table so the player can match HUD cells to pucks. Player A's Boss Monster uses `Ω` and minions `ω1..ω6` (Gold Reference Mark colour); Player B's uses `Ψ` and minions `ψ1..ψ6` (Silver Reference Mark colour); Enemy Adventurer Team 1 uses capital letters `G, B, S, A, F, E` (Deep Grey Reference Mark colour) and Team 2 uses small letters `g, b, s, a, f, e` (Deep Brown Reference Mark colour), standing for **G**uard (`1`), **B**rawler (`2`), **S**cout (`3`), **A**colyte (`4`), **F**ree (`5`), and **E**xtra (`6`). In normal random Adventurer Team generation, slot `1` (`G`/`g`) = Guard tree, slot `2` (`B`/`b`) = Brawler tree, slot `3` (`S`/`s`) = Scout tree, slot `4` (`A`/`a`) = Acolyte tree, and slots `5..6` (`F`/`f`, `E`/`e`) are free positions for duplicate class trees (missing class trees leave their slots and grid cells unused); customized stage compositions may override this class-to-slot assignment. Both the puck colour and the Unit Display border colour follow the unit's **Class Tree** (Guard tree = Blue, Brawler tree = Red, Scout tree = Green, Acolyte tree = Purple; Minions use a deeper shade of `1..6` TBC; Boss Monster is Black). To distinguish pucks of the same Class across teams and free positions, Team 1 pucks carry a 4-sided White X stripe and Team 2 pucks carry a 4-sided Black X stripe, while free positions `5` (`F`/`f`) and `6` (`E`/`e`) display a white circle behind the Reference Mark letter (like an 8-ball).

**Unit Information Manager**:
The battle-scoped manager node inside the Battlefield Scene that owns the authoritative `Unit Information` data objects (stats, `current_hp`, `max_hp`, `bars_remaining`, `Damage Stack`, `Hit Level`, `Frenzy Power`, buffs/debuffs, and active Puck references) for every unit in the battle, whether alive or defeated, and drives the Unit Information Board via events. Puck scripts hold only physics state (radius, mass, rotation, position, velocity); combat stats and HP live in the Unit Information DO.

**Frenzy Power**:
A percentage damage multiplier (baseline `100%`, minimum floor `50%`) held by each Boss Monster and displayed on the right side of its 2-cell Unit Display. Increases when the Boss Monster collides with an opponent Enemy Adventurer puck (default `+10%`) and is dynamically reduced by passive skills such as Guard's `SPA10001 Protect` (`-Y% = -X * (4% + Lv * 1%)` where `X` is the number of non-defeated, non-Guard-tree teammates in the same Adventurer Team, including pocketed teammates, offsetting the normal `+10%`; if that Guard puck is the very first puck the Boss Monster hits in a shot, the reduction `Y%` is doubled to `-2 * Y%`). Multiplies scalable damage dealt to opposing Adventurers at `Settle Time` per `Damage DO`'s source Boss Monster: $\left(\sum_{i} \text{Damage}_i \times \text{Frenzy}(\text{Source}_i)\right) \times 1.1^{\text{Hit Level}}$ (excluded from the pre-settle Ghost HP trail, then visually spread to enemies when settlement begins). After each `Settle Time` settlement, decays via `new_frenzy = current_frenzy / 2 + 50%`.

### The Battlefield

**Cue Table**:
The rectangular arena, styled as a cue table: a flat floor (30×20 on the demo table) with Cushions on four sides and Pocket Areas at the corners. Also called the Battle Field.
_Avoid_: arena, board

**Tile**:
One of the 15×10 squares making up the floor. May carry special effects in the future.

**Cushion**:
The raised border on each side of the table. Impacts deal no damage; Special Cushions with triggered effects are future work.
_Avoid_: wall

**Pocket Area**:
A hollow 2×2 zone at a table corner. A puck that falls in takes Pocket Area damage: baseline `50%` of one Health Bar (Boss Monster) or `50%` of `max_hp` (others), modifiable by passive skills (`Pocket Area Damage +/-?%`, clamped to `0%..100%`, such as Scout's `SPA10003 Safety Rope` for teammates in the same Adventurer Team while that Scout is on the cue table — excluding the falling Scout itself), pushed as a fixed `Damage DO` (`is_fixed = true`, meaning it is not multiplied by `Hit Level` or `Frenzy Power` at `Settle Time`). Unless the damage kills it, a pocketed **Boss Monster** respawns at the end of that turn's `Settle Time` (so the game can continue), whereas a pocketed **Adventurer** (or Minion) stays off the table with its `Unit Display` greyed out while keeping its normal `Action Countdown` and Time Board `Action Tag` count unchanged, and returns to the table at its next `Action Time` (consuming its action for that turn, respawning after all on-table acting units finish moving in `SPD` descending order) at a random empty, non-pocket Tile inside the middle 80% of the Cue Table.
_Avoid_: hole

**Puck**:
Any unit on the table — Boss Monster, Enemy Adventurer or Minion — treated as a physics-driven cylinder. Position and collision, not animation, define combat.
_Avoid_: ball, token

### Timing

Battle time always falls into exactly one of six Timings — Prepare, Charging, Play, Action, Puck-puck Time! or Settle.

**Turn**:
One tick of the battle clock: the time to charge one Energy slot (configurable, default 1s). The minimum gap between two consecutive Action Times.
_Avoid_: tick, second

**Time Board**:
The HUD board at the top of the battlefield canvas that visualizes battle time. Its parts are the Energy Bar — the fill showing Energy owned and the charging progress — and the Action Tags riding the slots. Laid out as two bars of 10 slots — upper and lower; contents slide one slot per Turn along a serpentine path: left→right on the lower bar, wrapping from lower-right to upper-right, then right→left on the upper bar toward the goal at the upper-left slot. Frozen except during Charging Time, unless an effect moves it (e.g. gaining or spending Energy — the fill rewinds with a quick animation). Contents glide smoothly; a slot completing means a new Energy is ready or an Action Tag has arrived. At full Energy the fill stops but Turns keep ticking and tags keep moving. In a 2-player battle, both players share one Time Board (a 2-player variant of the board) that shows both Player A's and Player B's Energy to all Peers.
_Avoid_: energy bar (that's only the fill, not the whole board), timer

**Prepare Time**:
The Timing of the Preparation Phase: the timing state machine does not run, no unit acts and Energy does not regenerate. On entering, the Time Board animates to the coming Wave's opening state — Energy set to exactly 10, old Action Tags removed, the new Adventurer Team's initial tags placed — then freezes, so the player can read the board and plan before pressing Start Wave.

**Charging Time**:
The fundamental timing: Energy charges one slot per Turn and nothing else acts — the player's thinking time. Entering Play Time is allowed at most once per slot charged. A Turn that lands one or more Action Tags on the goal slot triggers Action Time.

**Play Time**:
Everything waits for the player. In a 2-player game, players press the Play button during Charging Time to compete for the **Playing Right** — the first player whose press reaches the Host becomes the active player for that Play Time, while the other player and Spectators watch. Exactly one action is allowed: one Cue-Shot, one card, or cancel back to Charging Time. A Cue-Shot leads to Puck-puck Time!; a card leads wherever its effect directs.

**Action Time**:
The units whose Action Countdown reached `0` act across three sequential skill phases — **all Active Skills first, then all Attack Skills, then all Move Skills** (rather than all skills of one unit before the next). Within each phase, on-table acting units are ordered by their **`SPD` (speed)** from highest to lowest, tie-broken by their order in the game (spawn / registration order). Move Skills resolve their Adjusted Target Position in `SPD` descending order (using the Adjusted Target Position for moving pucks) and glide at constant speed with colliders disabled during the movement. After all on-table acting units finish moving, any pocketed units whose Action Countdown reached `0` respawn on the table in `SPD` descending order (consuming their action for that turn). All other units and the player only spectate.

**Puck-puck Time!**:
The window from a Cue-Shot until all pucks stop moving. Every Auto-Attack and AI behaviour freezes; only physics runs. Damage is staged, not applied, until Settle Time.

**Settle Time**:
A short timing after another timing, applying staged damage and displaying events (puck defeated, pocketed, Health Bar cleared). Skipped entirely when nothing settle-worthy happened, and occurs at most once per Turn — everything settle-worthy in a Turn settles together. Action Tag membership changes and resets are applied here: defeated units are removed from future cycle tag counts, and units that acted in `Action Time` reset their `Action Countdown` to their fixed interval.

**Action Tag**:
A marker on the Time Board marking the turns of each 12-Turn **Action Cycle** where Enemy Adventurers potentially act (`3, 4, 6, 8, 9, 12`, with 12-interval tags highlighted in a special colour). Tags are independent of Energy — they only share the board. Each Adventurer has a single fixed **Action Countdown** that must be a factor of 12 (`3`, `4`, or `6` — typically `4` for Guard and Brawler trees, `3` for Scout tree, `6` for Acolyte tree, modifiable by passive skills to another fixed factor), and every non-defeated Adventurer contributes `+1` to all multiples of its interval (`3, 4, 6, 8, 9, 12`) regardless of team or whether it is currently pocketed. Cycle tags exist at `3, 4, 6, 8, 9, 12` even when `0` units act on that turn. On the Time Board, a tag is an arrow with a circle on top showing the acting unit count for tags within 10 Turns (the upper bar); if a tag has `0` count (or is on the lower bar), the circle and number disappear. Each unit's own `Action Countdown` turns-to-next-action integer is shown on its `Unit Display`. Tags glide smoothly toward the goal, one slot per Turn; when a tag with count `> 0` reaches the goal, `Action Time` fires (a `0`-count tag clears at the goal without firing `Action Time`).

### Cards in Battle

**Hand**:
The cards currently playable, up to 10. A draw attempted at 10 is skipped (with a notification animation).

**Casting Area**:
Holds the single card in play until its effect resolves (its cooldown ends), when it moves to the Discard Pile. While occupied, no card can be played.
_Avoid_: play area

**Discard Pile**:
Spent cards, ordered and inspectable by the player.
_Avoid_: graveyard

### Combat & the Cue-Shot

**Focusing**:
An optional attack-preparation state for future interruptible skills (existing base skills `SMA10001..10004` and `SAA10001..10004` take effect immediately in Action Time and are non-interruptible). When a unit uses an interruptible skill that enters Focusing, it shows lighting VFX and stands stationary until the attack fires or an Interrupt cancels it. Not to be confused with energy charging in Charging Time.

**Auto-Attack / Attack Skill**:
Every unit's built-in Attack Skill against enemies in range, gated by the unit's Action Countdown and any per-skill `Skill Countdown`. A scripted damage event with a simple animation in Action Time — deals damage only, never applies Impulse or Force (unless a specific future skill explicitly launches a physical self Cue-Shot in Puck-puck Time, per ADR-0002).

**Cue-Shot**:
The player's basic action: drag to aim, release to launch the Boss Monster with an Impulse proportional to the Energy spent ($J \propto E$, so initial speed $v_0 = J / m$ — heavier Boss Monsters launch slower). Allowed only when every puck on the table is at rest.
_Avoid_: dash, basic attack

**Impulse**:
A one-off momentum change applied to a puck ($\Delta \vec{v} = \vec{J} / m$). Collisions (puck–puck and puck–cushion), Cue-Shots, and instantaneous card/unit knockbacks apply Impulse.
_Avoid_: impact

**Force**:
A continuous rate of momentum change over time applied to a puck ($\Delta \vec{v} = (\vec{F} / m) \cdot \Delta t$). Ground Friction on Tiles and continuous card/unit effects apply Force during each 20 Hz velocity update.

**Energy**:
The resource spent on Cue-Shots, shown as the energy fill on the Time Board. Capacity 20 — at full, further charging is discarded but Turns keep ticking; a shot costs 1–9 slots in 0.5-slot increments (1.0, 1.5, …, 9.0; demo tuning value, may be simplified later); it regenerates one slot per Turn during Charging Time — the player's thinking time. The per-slot charge time is configurable (default 1s). Spending Energy rewinds the fill backward along the board with a quick animation.

**Collision Damage**:
Damage dealt by puck impacts above a small speed threshold during `Puck-puck Time!`, calculated from the collision Impulse scalar $J$ applied to the victim puck and the hitting unit's `POW` via `(J / 40) * hitter.POW` (divisor in `PhysicsConstant.COLLISION_DAMAGE_IMPULSE_DIVISOR`). All class-specific collision modifiers (ally collision damage reduction, dealing collision damage to a Boss Monster, collision force reduction) are defined by Unit Skills rather than hardcoded class rules: by default, Boss Monsters take `0` collision damage from puck impacts, while all non-Boss pucks (Enemy Adventurers, Minions, Target Pucks) suffer normal collision damage (modifiable by equipped skills such as Guard's `SPA10001 Protect`, which reduces collision damage by `50%` on both pucks when colliding with a same-team ally, applied at most once per collision). Each puck records an ordered collision history of pucks and cushions collided during the turn, cleared at the end of `Settle Time`. In 2-player PvP mode, a Boss Monster hitting its own friendly Adventurer deals `1/4` (`0.25x`) damage, skips Frenzy Power changes, and settles at `100%` Frenzy Power; two Boss Monsters colliding deal `0` damage, reduce both Boss pucks' post-collision velocities to `20%`, and grant `+3` Energy to the non-active opponent at most once per `Puck-puck Time!`.

**Damage Stack**:
The time-ordered list of pending damage records (`Damage DO`: source, owner Boss Monster, decimal value, damage type, `is_fixed` flag — where `is_fixed = true` means the entry is not multiplied by `Hit Level` or `Frenzy Power`) accumulated on a unit during `Puck-puck Time!` or `Action Time` before resolving in `Settle Time` (where damage rounds to the nearest integer and displays as a large negative HP change number such as `-567`). Displayed on the Unit Display as a hit-count badge on the left of the portrait (invisible at 0, shaking on impact) and a blood-red Ghost HP trail on the green-to-greenish-yellow HP bar. Cleared after Damage Settlement in `Settle Time`.

**Hit Level**:
A per-unit integer (default `0`, held by all units: Boss Monsters, Minions, and Enemy Adventurers) adjusted by conditional effects (such as `+1` whenever any non-Boss unit puck hits a Cushion in `Puck-puck Time!`, attack skill effects like `Hit Level+?`, hitting a Focusing puck, special cushions, or type effectiveness) that scales final scalable damage exponentially by $1.1^{\text{Hit Level}}$. Included in the Ghost HP trail, persists across turns within a 12-turn Action Cycle, and resets to `0` only after the `Settle Time` of the last turn (Turn 12) of each 12-turn cycle.

**Interrupt**:
Cancelling or revising an adventurer's pending interruptible skill (applicable to future interruptible skills; existing base skills take effect immediately and are non-interruptible). Hard interrupts (a collision with a Focusing puck) force a cancel with class-tree consequences: a Brawler-tree unit takes bonus collision damage; a Scout-tree unit places a Recovery action tag / stun; an Acolyte-tree unit suffers a plain cancel; a Guard-tree unit still deals damage and takes reduced damage on collision, but its Focusing is cancelled like any other.
