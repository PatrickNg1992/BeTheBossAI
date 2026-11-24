# Adventurer Classes

To make the game more fun and fit the medieval style, we introduce a class system for Adventurers. Each adventurer is assigned a class to characterise them.

There are four basic classes: Brawler, Guard, Scout, and Acolyte. More classes will be added in future designs.

The class determines an Adventurer's basic attacks and some passive effects. Each adventurer will be assigned passive skills and an active skill. The Adventurer generation logic shall be described in more detail in ./adventurerGeneration.md

The following will describe the fundamental characteristics of each basic class (these characteristics and class rules also apply to their advanced classes in the same Class Tree). Note that existing base skills take effect immediately in Action Time and are non-interruptible; the Focusing/chanting and collision-interrupt behaviours below apply to future interruptible skills designed for each Class Tree.

\*\* Here **player's buck** means the pucks of boss monster and minions  

## Brawler

Brawler is the class that deals high attack damage. It has high attack power and medium health. The attack frequency is normal.

Brawlers move towards the player's pucks. After getting close, it attacks the target pucks after a short focusing time. Colliding with a focusing brawler puck stops it from charging and deals extra damage.  

Players should avoid being surrounded by multiple brawlers or interrupt its attack on time.

## Acolyte

Acolyte is the class that deals long-range serious damage. They move to keep distance from the boss monster puck. They *Chant* to cast strong spells and hit from a distance.

Acolytes have low HP and a slow focusing time. Once they attack, they deal great damage. If a focusing acolyte is collided with, it will interrupt the chanting charge.

Players should defeat them asap or interrupt their chanting.

## Scout

Scout is the class that moves and attacks frequently. They have special skills to interfere with the battle. Examples are reducing or attracting monsters' attacks.

Colliding with a charging Scout puck stops it from focusing and stuns it for a few turns.

Players should be aware of skill effects and respond accordingly.

## Guard

Guard is the class that is good at protecting allies and collision. Guard has high HP. However, it is bad at attack and moves slowly.

When guard pucks focus on collides effects. Some skill effects may deals damage to opponents when collision, reduce collision force and reduces the damage taken. 

Players should be careful not to collide with a guard pucks.

Relative strength like the following

| Class   | HP  | ATK | ATK FRQ | SPD | RNG |
| ------- | --- | --- | ------- | --- | --- |
| Brawler | 4   | 4   | 3       | 2   | 1   |
| Acolyte | 1   | 5   | 1       | 3   | 5   |
| Scout   | 3   | 2   | 5       | 5   | 3-4 |
| Guard   | 5   | 1   | 2       | 1   | 2   |

## Classes Advancement

There is an Adventurer class hierarchy, like other games in the Sword and Magic world. There are four main *Class Trees* corresponding to defence, melee, ranged and magic. Their base class are *Guard*, *Brawler*, *Scout*, *Acolyte*. There are 3 ranks of common Classes. (There are exceptional unique upper classes for Heroes) Each class at ranks 1 and 2 has two advancement options. Therefore, there are 4/8/16 common classes for Rank 1/2/3. 

The following are the 4 Class Trees for Ranks 1, 2 and 3. If you really need to know the class details, read ./.docmanual/codexList/index.md and the ./.docmanual/codexList/classes folder. Avoid it if possible, since the codex could be large. Common classes are listed here

- Guard: defence-based
  - Sentinel: self-focused
    - Bastion: tanky
    - Vanguard: taunt and block
  - Knight: protection-focused
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
    - Marksman: single-target focused
    - Barrager: heavy-power focused
  - Ranger: effect-based
    - Trapper: hinder effects
    - Assassin: effect damage and damage prevention
- Acolyte: magic-based
  - Mage: damage-based
    - Sorcerer: attack focused
    - Warlock: effect-damage focused
  - Priest: support-based
    - Bishop: healing and protection
    - Enchanter: buffs

The following are some terms to describe the relation between classes:

*Class Rank*: a number that describes the advancement level and relative strength of a class. Base classes have Rank 1. Every advancement increases the Rank, but not necessarily by 1.

*Base Class*: Classes of Rank 1: Guard, Brawler, Scout, or Acolyte.

*Advanced Class*: Classes that a class can evolve into. (ie. Knight and Bastion are Advanced Classes of Guard) 

*Prerequisite Class*:  All Classes that a class evolved from (Guard and Knight are Prerequisite classes of Paladin)

*Parallel Class*: Classes of the same Rank (Knight is a parallel class of Mage; Trapper is a parallel class of Assassin)

*Exceptional Class*: Class that is not in the four hierarchy Rank 1/2/3. These classes are uniquely designed for special Heroes. Some Exceptional Classes may have a class from the four hierarchies as a base class.  They are normally at Rank 3, 4, or 5. (A Pope may be developed from a Bishop. A Dragon Slayer is from Champion. A Dark Knight is from Knight) However, some Exceptional Classes simply do not have any Prerequisite Classes.

*Direct* Advanced/Prerequisite Class: the Class that a class directly advanced to/evolved from (Knight is a direct prerequisite class of Paladin, but Guard is not). Note that a direct Prerequisite Class of an Exceptional Class sometimes can be more than 1 rank lower. (A Dragon Knight evolved from Knight, but it is Rank 4)
