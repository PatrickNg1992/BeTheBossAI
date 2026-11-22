# Unit Skills

This document describes the Skill system. It explains skill types and their general effects. It applies to all units, including Boss Monsters, Adventurers and Minions.

There are mainly 4 types of skills. For simplicity, an Adventurer unit has one *Move Skill*, one *Attack Skill*, at most one *Active Skill* and multiple *Passive Skills* (TBC). This design avoids players wasting too much time learning different Adventurer actions at every stage. All Adventurer behaviours are presented as skills, and the number is limited. All skills should be checkable in the Unit Display Detail window. 

In Action Time, always check the skills in this order: Active Skill, Attack Skill, Move Skill.

Each skill has name, type and description. Attack Skills should has a attack power. Some Attack and Active Skills have Skill Countdowns. All these information should displayed when player check in the Unit Information Display system.

Each Skill has a unique name. Notice that some skills with LV? at the end but they are counted different skills that can coexist. Treat it just a part of the skill name, even though they usually have similar effects. 

Whenever a units use their Attack Skills and Active Skills, an animation should be played. And the effects should display at the almost the end of the animation.

## Move Skill

It defines how a Unit moves. Every unit, except a Boss Monster, has exactly one. It defines the distance, directions, and other conditions or effects. Typically, if a unit does not Basic Attack and uses its Active Skill, it moves.

## Attack Skill

It defines how a Unit attacks. Every unit, except a Boss Monster, has exactly one. It defines the attack method, power, and conditions of basic attacks. Typically, a unit needs suitable range and charge time to attack. Some attacks allow movement at the same time, but some do not.

## Active Skill

It defines how a Unit acts beyond moving and basic attacks. Every unit has zero or one Active Skill. It defines the conditions and effects of the additional action. 

## Passive Skill

It defines some extra effects of a unit. Every unit can have multiple Passive Skills. The effects are various. 

Passive Skills are extra traits of a unit beyond its defined behaviour. Adding random Passive Skills is a way to adjust the unit and team strength in unit random generation logic. Some passive skills are restricted to some specific kinds of units.

Passive skills can be triggered whenever the condition is met, not necessarily at the Unit's Action Time.



## Common Skill Effects

### Skill Countdown

Some skills will not take effect every Action Time a unit participates. Skill Countdown is the minimum number of turns that must pass before the skill can activate again. The Skill Countdown of a skill start with the value, but not 0. The countdown resets only when the skill fulfilled its activation conditions and activated.

For example, if a Knight has a skill with Skill Countdown 9 while it has Action Countdown 4, it means the skill takes at least 3 Action Time to take effect again. 

### On the cue table

This condition means that 

- the unit is not defeated, and

- there is at least one puck of that unit on the table, not including fallen into the pocket area;

- If the unit is in conditions like invisible, it still counts.

### Pocket Area Damage +/-?%

When a unit falls into the Pocket Area, calculate all the passive effects to adjust the damage it should take. The default Pocket Area Damage value is 50% of the max HP for all units (only count 1 HP bar). The resulting value must be within 0 to 100%. 

For example, if two Scouts with skill apply -10% each to teammates and a Boss monsters skill apply +15% to all enemies, a unit should take 45% damage when fallen into pocket.
