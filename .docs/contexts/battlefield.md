# Battlefield Scene

The main scene of the game: one Stage battle, fought as "snooker with cards" — the Boss Monster and Enemy Heroes are physics Pucks on a Cue Table, and the player also plays cards from their Deck. Stages are selected from the World Map scene. Game-wide terms (Boss Monster, Stage, Deck, Card Type) live in the root `CONTEXT.md`.

## Language

### The Game Loop

**Wave**:
One Hero Team assault within a Stage. The player advances by defeating every Enemy Hero in the Wave.
_Avoid_: round

**Hero Team**:
The group of Enemy Heroes fielded by one Wave.
_Avoid_: mob, enemy wave

**Preparation Phase**:
The rest before each Wave. The coming Hero Team stands inert on the table, all cards return to the Deck, and the player draws a fresh hand of 5. No boss movement, no card play.
_Avoid_: checkpoint, break

**Start Wave**:
The player's only Preparation Phase action — ends the phase and activates the previewed Hero Team.

### Units

**Enemy Hero**:
An enemy puck with a Class. (Equipment and Hero Skills are future concepts, not yet specified.)
_Avoid_: chess piece, mob

**Class**:
An Enemy Hero's occupation — Warrior, Knight, Mage or Ranger — fixing its Auto-Attack range/cooldown profile and stats.
_Avoid_: type, job

**Minion**:
A future player-side puck, summoned by cards or the Boss Monster. Follows Enemy Hero collision rules, except that a Knight's protection does not extend to it.
_Avoid_: summon

**Health Bar**:
One segment of a unit's HP. The Boss Monster has several; losing one grants brief invincibility and a card draw. Enemy Heroes have one.

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
A hollow 2×2 zone at a table corner. A puck that falls in takes damage equal to half a Health Bar (Boss Monster) or half its max HP (others), leaves the field, and returns 5 seconds later at the nearest free Tile — unless the damage kills it.
_Avoid_: hole

**Puck**:
Any unit on the table — Boss Monster, Enemy Hero or Minion — treated as a physics-driven cylinder. Position and collision, not animation, define combat.
_Avoid_: ball, token

### Timing

Battle time always falls into exactly one of six Timings — Prepare, Charging, Play, Action, Puck-puck Time! or Settle.

**Prepare Time**:
The Timing of the Preparation Phase: the timing state machine does not run, no unit acts and Energy does not regenerate. When it ends, the player's Energy is set to exactly 10 and units place their initial Action Tags.

**Charging Time**:
The fundamental timing: Energy charges one slot at a time (configurable, default 1s per slot) and nothing else acts — the player's thinking time. Entering Play Time is allowed at most once per slot charged. Charging into a slot carrying an Action Tag triggers Action Time.

**Play Time**:
Everything waits for the player. Exactly one action is allowed: one Cue-Shot, one card, or cancel back to Charging Time. A Cue-Shot leads to Puck-puck Time!; a card leads wherever its effect directs.

**Action Time**:
The units whose Action Tags were charged past act — one action each, in spawn order; buff/debuff actions first (priority TBC), cue-shot actions (e.g. the Knight's) last. All other units and the player only spectate.

**Puck-puck Time!**:
The window from a Cue-Shot until all pucks stop moving. Every Auto-Attack and AI behaviour freezes; only physics runs. Damage is staged, not applied, until Settle Time.

**Settle Time**:
A short timing after another timing, applying staged damage and displaying events (puck defeated, pocketed, Health Bar cleared). Skipped entirely when nothing settle-worthy happened.

**Action Tag**:
A marker an Enemy Hero or Minion places on an Energy slot, meaning "this unit acts when that slot finishes charging." After acting, the unit places its next tag a unit-specific number of slots ahead — faster units use smaller offsets, so they act more often.

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

**Auto-Attack**:
Every puck's built-in attack against enemies in range, on its own cooldown. Deals damage only — it never applies force.

**Cue-Shot**:
The player's basic action: drag to aim, release to launch the Boss Monster, spending Energy. Allowed only when every puck on the table is at rest.
_Avoid_: dash, basic attack

**Energy**:
The resource spent on Cue-Shots, shown as a bar at the top of the screen. Capacity 20; a shot costs 1-7; it regenerates one slot at a time during Charging Time — the player's thinking time. The per-slot charge time is configurable (default 1s).

**Collision Damage**:
Damage dealt by puck impacts above a small speed threshold. Enemy Heroes suffer it from any impact — except impacts with a Knight, which protects its allies. Only a Knight's impacts damage the Boss Monster, whoever initiated the collision.
