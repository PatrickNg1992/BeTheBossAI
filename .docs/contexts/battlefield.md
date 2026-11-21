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
An enemy puck with a Class. Adventurer Skills are drawn from a shared pre-defined pool — 0–1 active plus any number of passives; equipment is a future concept. Its move action is a scripted constant-speed glide with physics disabled — it may pass through other pucks and Pocket Areas mid-glide, but never comes to rest on a pocket or overlapping another puck (ADR-0002).
_Avoid_: chess piece, mob

**Class**:
An Enemy Adventurer's occupation — Warrior, Knight, Mage or Ranger — fixing its Auto-Attack range/cooldown profile and stats. The per-class stat table (HP / Power / ATK FRQ / SPD / RNG) encodes *relative strength ratios* between classes, not absolute values; absolute stats run into the thousands, with LV scaling them linearly on top of the ratios (exact formula TBD). RNG is likewise relative — a Mage reaches nearly the whole table.
_Avoid_: type, job

**Minion**:
A future player-side puck, summoned by cards or the Boss Monster. Follows Enemy Adventurer collision rules, except that a Knight's protection does not extend to it.
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
A popup window alongside the Unit Information Board that shows full stats, skills, status effects, and puck properties for an inspected unit.

**Reference Mark**:
The short identifier shown on both the upper-left corner of a unit's Unit Display and the center of its Puck(s) on the Cue Table so the player can match HUD cells to pucks. Player A's Boss Monster uses `Ω` and minions `ω1..ω6` (Gold Reference Mark colour); Player B's uses `Ψ` and minions `ψ1..ψ6` (Silver Reference Mark colour); Enemy Adventurer Team 1 uses capital letters `V, B, R, S, F, E` (Deep Grey Reference Mark colour) and Team 2 uses small letters `v, b, r, s, f, e` (Deep Brown Reference Mark colour), standing for **V**anguard (`1`), **B**rawler (`2`), **R**anger (`3`), **S**pell (`4`), **F**ree (`5`), and **E**xtra (`6`). In normal random Adventurer Team generation, slot `1` (`V`/`v`) = Knight, slot `2` (`B`/`b`) = Warrior, slot `3` (`R`/`r`) = Ranger, slot `4` (`S`/`s`) = Mage, and slots `5..6` (`F`/`f`, `E`/`e`) are free positions for duplicate classes (missing classes leave their slots and grid cells unused); customized stage compositions may override this class-to-slot assignment. Both the puck colour and the Unit Display border colour follow the unit's **Class** (Knight = Blue, Warrior = Red, Ranger = Green, Mage = Purple; Minions use a deeper shade of `1..6` TBC; Boss Monster is Black). To distinguish pucks of the same Class across teams and free positions, Team 2 pucks carry a 2-sided White line stripe (Team 1 has no team stripe), while free position `5` (`F`/`f`) carries a 4-sided White X stripe and position `6` (`E`/`e`) carries a 4-sided Black X stripe.

**Unit Information Manager**:
The battle-scoped manager node inside the Battlefield Scene that owns the authoritative `Unit Information` data objects (stats, `current_hp`, `max_hp`, `bars_remaining`, `Damage Stack`, `Hit Level`, `Frenzy Power`, buffs/debuffs, and active Puck references) for every unit in the battle, whether alive or defeated, and drives the Unit Information Board via events. Puck scripts hold only physics state (radius, mass, rotation, position, velocity); combat stats and HP live in the Unit Information DO.

**Frenzy Power**:
A percentage damage multiplier (baseline `100%`, minimum floor `50%`) held by each Boss Monster and displayed on the right side of its 2-cell Unit Display. Increases when the Boss Monster collides with a non-Knight Enemy Adventurer puck (default `+10%`) and decreases when colliding with a Knight puck (default `-20%`, or via special blocks/effects). Multiplies damage dealt to opposing Adventurers at `Settle Time` per `Damage DO`'s source Boss Monster: $\left(\sum_{i} \text{Damage}_i \times \text{Frenzy}(\text{Source}_i)\right) \times 1.1^{\text{Hit Level}}$ (excluded from the pre-settle Ghost HP trail, then visually spread to enemies when settlement begins). After each `Settle Time` settlement, decays via `new_frenzy = current_frenzy / 2 + 50%`.

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
A hollow 2×2 zone at a table corner. A puck that falls in takes damage equal to half a Health Bar (Boss Monster) or half its max HP (others). Unless the damage kills it, it leaves the field for 5 Turns: its planned Action Tag is cancelled, a "return" tag is placed 5 slots ahead of the goal, and when that tag fires the puck returns at the nearest free Tile and places its next Action Tag as usual.
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
The units whose Action Tags reached the goal act — one action each, in spawn order; buff/debuff actions first (priority TBC), cue-shot actions (e.g. the Knight's) last. All other units and the player only spectate.

**Puck-puck Time!**:
The window from a Cue-Shot until all pucks stop moving. Every Auto-Attack and AI behaviour freezes; only physics runs. Damage is staged, not applied, until Settle Time.

**Settle Time**:
A short timing after another timing, applying staged damage and displaying events (puck defeated, pocketed, Health Bar cleared). Skipped entirely when nothing settle-worthy happened, and occurs at most once per Turn — everything settle-worthy in a Turn settles together. Action Tag membership changes are also applied here: a tag whose unit count reaches zero is removed, and a unit entering the table joins an existing tag for the slot it will act on — or places a new tag there. Adventurers make their next-action decisions here: after any table change, a adventurer may decide to attack — placing a full-countdown attack tag — or revise its pending tag based on the new situation.

**Action Tag**:
A marker an Enemy Adventurer or Minion places on a slot of the Time Board, meaning "this unit acts when the tag reaches the goal." Tags are independent of Energy — they only share the board. On the board a tag is a simple arrow pointing into the bar, standing above the upper bar or below the lower bar, showing two integers: how many units share it, and the Turns until it reaches the goal; it does not identify the units (too many) — instead the same Turns integer is shown on each unit's icon on the canvas. Tags glide smoothly toward the goal, one slot per Turn, firing Action Time on arrival; crossing from the lower bar to the upper bar teleports with a fade-out/fade-in. During Action Time a firing tag stays pinned at the goal and its unit count decreases as each of its units acts; each unit's replacement tag fades in as its action completes, and the firing tag vanishes when Action Time ends. After acting, the unit places its next tag a unit-specific number of slots ahead of the goal — faster units use smaller offsets, so they act more often. A adventurer commonly owns 1–2 tags at once: one for its base action (move or attack) and one per active skill; passives never place tags.

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
A adventurer's attack-preparation state, entered at Settle Time when its class condition (usually range) holds: it places a full-countdown attack tag, shows lighting VFX, and stands stationary until the tag fires or an Interrupt cancels it. Not to be confused with energy charging in Charging Time.

**Auto-Attack**:
Every puck's built-in attack against enemies in range, on its own cooldown. A scripted damage event with a simple animation in Action Time — deals damage only, never applies Impulse or Force. The Knight's attack is the exception: a self Cue-Shot resolved physically in Puck-puck Time (ADR-0002).

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
Damage dealt by puck impacts above a small speed threshold. Enemy Adventurers suffer it from any impact — except impacts with a Knight, which protects its allies. Only a Knight's impacts damage the Boss Monster, whoever initiated the collision.

**Damage Stack**:
The time-ordered list of pending damage records (`Damage DO`: source, value, damage type) accumulated on a unit during `Puck-puck Time!` or `Action Time` before resolving in `Settle Time`. Displayed on the Unit Display as a hit-count badge on the left of the HP bar (invisible at 0, shaking on impact) and a Ghost HP trail on the HP bar. Cleared after Damage Settlement in `Settle Time`.

**Hit Level**:
A per-unit integer (default `0`, held by all units: Boss Monsters, Minions, and Enemy Adventurers) adjusted by conditional effects (such as hitting a Focusing puck, special cushions, or type effectiveness) that scales final damage exponentially by $1.1^{\text{Hit Level}}$. Included in the Ghost HP trail and resets to `0` after `Settle Time` settlement.

**Interrupt**:
Cancelling or revising a adventurer's pending attack. Hard interrupts (a collision with the Focusing puck) force a cancel; soft interrupts (the target moving out of range, card effects) let the adventurer re-decide at the next Settle Time. Class texture: a Warrior takes bonus collision damage; a Ranger places a Recovery action tag — an action whose firing ends the stun; a Mage suffers a plain cancel; a Knight still deals damage and takes reduced damage on collision, but its Focusing is cancelled like any other.
