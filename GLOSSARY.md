# Glossary

# Stage and Battlefield

## Boss Monster

The main character the player controls. If defeated, the game is over. There is a boss pucks on the battlefield.

## Stage

Simply a game stage that the player can choose to play.

## Wave

A game stage consists of multiple waves. Each wave will generate a Hero Team. The player needs to defeat the team to pass the wave. A hero team typically consists of 4 - 10 Enemy Heroes, with a hard cap of 12 per wave.

## Preparation Phase (Prep Phase)

Before each wave, there is a short rest for the player to do some preparation, including shuffling the deck and redrawing cards.

## Hero Team

A group of *Enemy Heroes* that come to challenge the player in each wave. A hero team typically consists of 6 - 10 Enemy Heroes.

## Enemy Hero

An enemy unit of the player. Each may have a *Class*, some *Equipment* and some *Hero Skills*.

## Class

The type (occupation) of an Enemy Hero. Examples are Warrior, Mage, Ranger, Knight, etc.

## Battlefield

The field where the battle takes place. Including the Snooker table and pucks.

## Snooker Table (Table)

The table in the battlefield where pucks are placed. 

## Pucks

A short cylinder-shaped object on the *Table* that represents different units. 

## Pocket Area

A hole in the table that a puck may fall into. 

## Cushion

4 sides of the table. 

# Cue and Collision System

## Cue-shot

The player makes a fast move with the Boss Pucks. The pucks hit the opponents to deal damage.

It can be made by either

- use the basic drag and release by mouse

- play a card effect

## Force

Similar to classical physics, a force is applied to a puck to make it move when playing a cue shot.

## Friction

Similar to classical physics, when a puck is moving, friction gradually slows it until it stops. The friction should be constant so that the puck's travel distance should be ∝ force².

## Energy

Energy is the resource for the player to make a shot to make a cue-shot. Energy is regenerated over time.

## Energy Bar

The energy fill on the *Time Board*, showing how much energy the player owns. It has 20 slots laid out as two 10-slot bars (upper and lower).

One slot is charged per *Turn* during *Charging Time* (default 1s per slot, configurable). Slots can carry *Action Tags*.

## Time Board

The board at the top of the battlefield scene canvas that visualizes battle time: the *Energy Bar*, the charging progress, and the *Action Tags*. Contents glide smoothly one slot per *Turn* — left to right on the lower bar, then (teleporting with a fade) from the lower-right to the upper-right, then right to left toward the goal at the upper-left slot. Frozen outside *Charging Time* unless an effect moves it (e.g. gaining or spending energy). At full energy the fill stops but tags keep moving.

## Turn

One tick of the battle clock — the time to charge 1 energy slot (default 1s, configurable). The minimum gap between two consecutive *Action Times*.

# Timing system

The main game time always falls into one of the six timings below; only one type of thing happens at a time. Mechanics and transitions are specified in `.docmanual/battleField/timingSystem/`; canonical terms in `CONTEXT.md`.

## Prepare Time

The timing of the *Preparation Phase*. The timing state machine does not run, no unit acts and energy does not regenerate. On entering, the *Time Board* animates to the coming wave's opening state (energy set to exactly 10, old *Action Tags* removed, the new team's initial tags placed), then freezes so the player can read it and plan.

## Charging Time

Energy charges one slot per *Turn*; nothing else moves or acts. The player's thinking time. Ends when the player enters Play Time (at most once per slot) or a *Turn* lands an *Action Tag* on the goal slot.

## Play Time

Everything waits for exactly one player action: one cue-shot, one card, or cancel back to Charging Time.

## Action Time

The units whose Action Tags reached the goal act, one action each, in spawn order (buff/debuff first — TBC; cue-shot actions like the Knight's last). Everyone else spectates.

## Action Tag

A marker a Hero or Minion places on a slot of the *Time Board*, meaning "this unit acts when the tag reaches the goal (upper-left slot)." Tags are independent of energy. After acting, the unit places its next tag some slots ahead of the goal; faster units use smaller offsets and act more often.

Displayed as a simple arrow pointing into the bar, with two integers — how many units share the tag, and how many *Turns* until the goal. The Turns integer is also shown on each unit's icon in the canvas. During *Action Time* the firing tag stays at the goal, its unit count decreasing as each unit acts; replacement tags fade in one-by-one as each action completes, and the firing tag vanishes when Action Time ends.

## Puck-puck Time!

Pucks move with force and collide until all stop. Damage is calculated but only staged; it is applied in Settle Time.

## Settle Time

A short timing that applies staged damage and displays events (puck defeated, puck pocketed, a health bar cleared). Skipped entirely when nothing settle-worthy happened. *Action Tag* membership changes are also applied here — a tag whose unit count reaches zero is removed; a unit entering the table joins an existing tag for its acting slot or places a new one.

# Card system

## Card

The player can play effects with cards. The player can hold a maximum of 10 cards in their hand. 

## Deck

The player makes a 52-card deck before the game. Then the player draws cards from it.

## Casting Area

Holds the last card played to prevent the player from playing cards too frequently. The card held here will move to the discard pile after the CD is done.

## Discard Pile

The place where a used card is finally placed.

# Action system

# TBC

## Equipment

An Enemy Hero may randomly equip some equipment. Equipment provides stats, and some may provide extra effects. This system adds randomness to differentiate heroes.

(TBC)

## Hero Skill

An Enemy Hero may randomly equip some Hero Skills that have special effects. At least one basic attack skill is equipped according to the Hero Class.

(TBC)

## Minion

A smaller monster that is summoned by the player side, either by cards or the Boss Monster’s effect.

(TBC)
