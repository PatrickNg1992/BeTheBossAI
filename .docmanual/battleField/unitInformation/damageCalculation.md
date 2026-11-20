# Damage Calculation

## Damage Stack

Damage Stack is the damage accumulated during a "Puck-puck time!" or Action Time that has not yet settled. It resolves during Settle Time. 

Typically, damage to a unit is dealt by collision, effects and projectiles. Each time a unit takes damage, the Damage Stack adds one Damage DO to record it. The Damage DO is stored in a List inside the Unit Information DO in time order. 

All units hold a Damage Stack, including Boss monsters, minions and adventurers.

### Damage DO (Data Object)

A Damage DO of a unit stores the source and value of damage taken. It also specifies other information, such as damage type. 

## Frenzy Power

Frenzy Power is a bonus mechanism that allows players to multiply the damage with a good play. It is a percentage number that multiplies the total damage right before the Damage Settlement. 

The number can be affected by collisions and effects. Typically, the power number increases whenever the Boss monster collides with an enemy adventurer puck. However, if the puck is a knight class, the number will decrease. Sometimes the battlefields will spawn special blocks that allow the player to adjust the Frenzy Power.

Only boss monsters have Frenzy Power.

## Hit Level

Hit Level adjusts damage based on special conditions. Each enemy adventurer has its own hit level. Hit level is an integer that defaults to zero and can be increased or decreased by conditional effects. The final damage to a unit scales exponentially with its hit level. Some standard effects are:

- The monster hits a unit puck that is charging an attack

- The pucks collide with special cushion blocks

- Type Effectiveness Effects

## Damage Settlement

In the Settle Phase, after all damage effects are completed, the game will settle the Damage Stack for all units on the board.  



Damage taken by Adventurer:

(Sum of Damage Stack) x (Frenzy Power) x 1.1^(Hit Level)

where Frenzy Power refers to the opponent's Boss Monster



Damage taken by Boss Monster and Minions:

(Sum of Damage Stack) x 1.1^(Hit Level)



After Damage Settlement, the Damage stack translates to the actual Damage value dealt to units. Then the units check whether they are defeated.

## Visual Effect (Count and HP Trailing)

Whenever a unit takes damage, the Unit Display notify the player with visual effects. On the left of the HP bar, a small circle mark shows the Damage Stack count of the unit. It is invisible when the count is 0. The middle of the mark is a number that shows the count. The mark shakes briefly whenever the unit takes damage. A harder hit creates a larger shake.

The HP trailing does not consider the Frenzy Power and only considers the Damage Stack and Hit Level. A visual effect that spreads the Frenzy Power to the opponents' HP when the Damage Settlement starts.
