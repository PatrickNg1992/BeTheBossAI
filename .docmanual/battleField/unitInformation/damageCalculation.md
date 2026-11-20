# Damage Calculation

## Damage Stack

Damage Stack is the damage accumulated during a "Puck-puck time!" or Action Time that has not yet settled. It resolves during Settle Time. 

Typically, damage to a unit is dealt by collision, effects and projectiles. Each time a unit takes damage, the Damage Stack adds one Damage DO to record it. The Damage DO is stored in a List inside the Unit Information DO in time order. 

All units hold a Damage Stack, including Boss monsters, minions and adventurers.

### Damage DO (Data Object)

A Damage DO of a unit stores the source and value of damage taken. It also specifies other information, such as damage type.

When two pucks collide in `PuckVelocityManager`, after calculating the collision Impulse scalar `J`, `PuckVelocityManager` checks collision effects and pushes a `Damage DO` to the affected unit's Damage Stack in `UnitInformationManager` (following the collision matrix: Enemy Adventurers take collision damage from any impact except with an allied Knight; Boss Monsters only take collision damage from impacts with a Knight). For the demo formula (to be refined later), collision damage is linear with the collision Impulse `J`, landing in approximately the `50 ~ 200` range per collision depending on hitting velocity/impulse. 

## Frenzy Power

Frenzy Power is a bonus mechanism that allows players to multiply the damage with a good play. It is a percentage number (default `100%`) that multiplies the total damage right before the Damage Settlement. 

The number can be affected by collisions and effects. Typically, the power number increases whenever the Boss monster collides with an enemy adventurer puck (default `+10%`). However, if the puck is a knight class, the number will decrease (default `-20%`), with a minimum floor of `50%`. Sometimes the battlefields will spawn special blocks that allow the player to adjust the Frenzy Power.

Only boss monsters have Frenzy Power (each boss monster has its own Frenzy Power, displayed on the right side of its 2-cell Unit Display). After each Damage Settlement in Settle Time, the extra Frenzy Power above 100% is halved: `new_frenzy = (current_frenzy / 2) + 50%` (e.g. `200% -> 150%`, `100% -> 100%`).

## Hit Level

Hit Level adjusts damage based on special conditions. Every unit (Boss monsters, minions, and enemy adventurers) has its own hit level. Hit level is an integer that defaults to zero and can be increased or decreased by conditional effects. The final damage to a unit scales exponentially with its hit level (`1.1^(Hit Level)`). Hit Level resets to `0` after each Damage Settlement in Settle Time. Some standard effects are:

- The monster hits a unit puck that is charging an attack

- The pucks collide with special cushion blocks

- Type Effectiveness Effects

## Damage Settlement

In the Settle Phase, after all damage effects are completed, the game will settle the Damage Stack for all units on the board.  



Damage taken by Adventurer:

(Sum over Damage Stack of (Damage DO value x Source Boss Frenzy Power)) x 1.1^(Hit Level)

where Source Boss Frenzy Power refers to the Frenzy Power of the opponent's Boss Monster that dealt (or owns the source of) that Damage DO (defaults to 100% if no Boss Monster source applies).

Damage taken by Boss Monster and Minions:

(Sum of Damage Stack) x 1.1^(Hit Level)

For any Boss Monster, pending and settled damage in a single Settle Phase is capped at clearing at most 1 Health Bar (its Ghost HP bar trails down to 0 of the active Health Bar, and excess damage never spills over into the next Health Bar). This applies to every Boss Monster in every Settle Phase.

After Damage Settlement, the Damage stack translates to the actual Damage value dealt to units, Hit Level resets to 0 for all units, and each Boss Monster's Frenzy Power decays to `(current_frenzy / 2) + 50%`. Then the units check whether they are defeated.

## Visual Effect (Count and HP Trailing)

Whenever a unit takes damage, the Unit Display notify the player with visual effects. On the left of the HP bar, a small circle mark shows the Damage Stack count of the unit. It is invisible when the count is 0. The middle of the mark is a number that shows the count. The mark shakes briefly whenever the unit takes damage. A harder hit creates a larger shake.

The HP trailing does not consider the Frenzy Power and only considers the Damage Stack and Hit Level. A visual effect that spreads the Frenzy Power to the opponents' HP when the Damage Settlement starts.
