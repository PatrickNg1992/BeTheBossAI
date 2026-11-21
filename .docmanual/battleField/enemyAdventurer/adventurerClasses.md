# Adventurer Classes

To make the game more fun and fit the medieval style, we introduce a class system for Adventurers. Each adventurer is assigned a class to characterise them.

There are four basic classes: Warrior, Knight, Ranger, and Mage. More classes will be added in future designs.

The class determines an Adventurer's basic attacks and some passive effects. Each adventurer will be assigned passive skills and an active skill. The Adventurer generation logic shall be described in more detail in ./adventurerGeneration.md

The following will describe the fundamental characteristics of each basic class.

\*\* Here **player's buck** means the pucks of boss monster and minions  

## Warrior

Warrior is the class that deals high attack damage. It has high attack power and medium health. The attack frequency is normal.

Warriors move towards the player's pucks. After getting close, it attacks the target pucks after a short focusing time. Colliding with a focusing warrior puck stops it from charging and deals extra damage.  

Players should avoid being surrounded by multiple warriors or interrupt its attack on time.

## Mage

Mage is the class that deals long-range serious damage. They move to keep distance from the boss monster puck. They *Chant* to cast strong spells and hit from a distance.

Mages have low HP and a slow focusing time. Once they attack, they deal great damage. If a focusing mage is collided with, it will interrupt the chanting charge.

Players should defeat them asap or interrupt their chanting.

## Ranger

Ranger is the class that moves and attacks frequently. They have special skills to interfere with the battle. Examples are reducing or attracting monsters' attacks.

Colliding with a charging Ranger puck stops it from focusing and stuns it for a few turns.

Players should be aware of skill effects and respond accordingly.

## Knight

Knight is the class that is good at protecting allies and collision. Knight has high HP. However, it is bad at attack and moves slowly.

When a knight collides with its ally, it does not deal damage to them. 

When a knight puck is focusing and collides with the player's pucks, it deals damage to them and reduces the damage taken. 

When a puck collides with a knight puck, it loses force, so its speed decreases.

Players should be careful not to collide with a charging knight.

Relative strength like the following

| Class   | HP  | ATK | ATK FRQ | SPD | RNG |
| ------- | --- | --- | ------- | --- | --- |
| Warrior | 4   | 4   | 3       | 2   | 1   |
| Mage    | 1   | 5   | 1       | 3   | 5   |
| Ranger  | 3   | 2   | 5       | 5   | 3-4 |
| Knight  | 5   | 1   | 2       | 1   | 2   |

## Classes Advancement

- Guard: defence-based
  - Sentinel: defence-based
    - Bastion: tanky
    - Vanguard: taunt and block
  - Knight: effect-based
    - Paladin: support and heal effects
    - Banneret: aura-based
- Brawler: melee-based
  - Warrior: attack-based
    - Champion: balanced-attacker
    - Berserker: strong attack with negative effects
  - Duelist: effect-based
    - Virtuoso: effect-buffed attack
    - Spellblade: effect damage
- Scout: ranged-based
  - Shooter: attack-based
    - Marksman: long range focus
    - Barrager: heavy power focus
  - Ranger: effect-based
    - Trapper: hinder effects
    - Assassin: effect-buffed attack and damage prevention
- Acolyte: magic-based
  - Mage: damage-based
    - Sorcerer: attack-based
    - Warlock: effect damage-based
  - Priest: support-based
    - Bishop: healer
    - Enchanter: buffs
