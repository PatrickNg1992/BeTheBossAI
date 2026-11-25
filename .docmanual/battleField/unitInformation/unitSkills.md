# Unit Skills

This document describes the Skill system. It explains skill types and their general effects. It applies to all units, including Boss Monsters, Adventurers and Minions.

There are mainly 4 types of skills. For simplicity, an Adventurer unit has one *Move Skill*, one *Attack Skill*, at most one *Active Skill* and multiple *Passive Skills* (TBC). This design avoids players wasting too much time learning different Adventurer actions at every stage. All Adventurer behaviours are presented as skills, and the number is limited. All skills should be checkable in the Unit Display Detail window. 

In Action Time, skills across all acting units are checked by skill category in three sequential phases: **all Active Skills first, then all Attack Skills, then all Move Skills** (rather than running all skills of one unit before the next unit). Within each phase, acting units are ordered by their **`SPD` (speed)** from highest to lowest; units with the same `SPD` are checked according to their order in the game (spawn / registration order).

Each skill has a name, icon, type and description. Attack Skills should have an attack power. Some Attack and Active Skills have Skill Countdowns. All this information should be displayed when the player checks the Unit Information Display system.

Each Skill has a unique name. Notice that skills with LV? at the end are Upgradable Skills. When generating Adventurers, it can increase to LV to adjust the strength of a unit.

Whenever a unit uses its Attack Skills or Active Skills, an animation should be played. The effects should display at almost the end of the animation.

Read ./.docmanual/codexList/skills/index.md to find the skills document.
Read ./commonSkillEffects.md if you need to know skill effects in more detail. Avoid doing it if your task is not related. 

## Move Skill

It defines how a Unit moves. Every unit, except a Boss Monster, has exactly one. It defines the distance, directions, and other conditions or effects. By default, all distance checks in Move Skills are measured **centre-to-centre**. Sometimes a unit that attacked or used an active skill with `Skip Movement` will skip its Move Skill. 

In the Move Skill phase of Action Time, moving units evaluate their Move Skill in `SPD` descending order (tie-broken by game order) using the **Move Glide Logic** below. 

### Move Glide Logic

Most of the Move Skills use *Glide* to move target position. (Except some advanced Skills like Teleport)

If a Skill effect shall glide, determine the *Target Position* of the skill first. Then resolve a *Adjusted Target Position* by the following logic:
- check whether the Target Position is a *Valid Position*. If yes use it.
- Otherwise check the surrounding position by 
    - Select a random direction on the table plane, call it *Angle*, and set *Distance* = 0.5 
    - Check the position that at *Angle* and *Distance* from the Target Position, if it is *Valid Position*, use it
    - Adjust *Angle* by 45 degree clockwise. If it is a multiple of 8 times(1 circle), increase *Distance* by 0.5
    - If already completed 3 circles and still cannot find a Valid Point, break the loop and cancel the move. 
    - Repeat the checking if not break
Then move the pucks towards the *Adjusted Target Position* with constant speed. During the movement, disable the puck's collider. 

*Valid position* of a puck means a position that if the puck move to there:
- Not on pocket area
- Not overlap with another pucks and obstacles (for any puck that shall move in the current Move Skill phase and has already resolved its *Adjusted Target Position*, check overlap against its *Adjusted Target Position* instead of its original position)
- Inside the table and does not overlap with the cushions



## Attack Skill

It defines how a Unit attacks. Every unit, except a Boss Monster, has exactly one. It defines the attack method, ratio, and conditions of basic attacks. Typically, a unit needs suitable range and charge time to attack. Some attacks allow movement at the same time, but some do not.

The damage value dealt by an attack skill = `unit's POW * skill ratio`

## Active Skill

It defines how a Unit acts beyond moving and basic attacks. Every unit has zero or one Active Skill. It defines the conditions and effects of the additional action. 

## Passive Skill

It defines some extra effects of a unit. Every unit can have multiple Passive Skills. The effects are varied. 

Passive Skills are extra traits of a unit beyond its defined behaviour. Adding random Passive Skills is a way to adjust the unit and team strength in unit random generation logic. Some passive skills are restricted to some specific kinds of units.

Passive skills can be triggered whenever the condition is met, not necessarily at the Unit's Action Time.

## Implementation

Create a abstract Unit Skill Class. It should include name, icon path, type, target classes, level etc. 

Then create 4 abstract subclasses: Move Skill, Attack Skill, Active Skill and Passive Skill. Create Skill Classes and set them into the Unit Information Object. The User Display Detail should show them. Create classes for actual implementations for each skill. Create helpers for common effects.

In the unit's Action Times, check Active Skill, Attack Skill, and Move Skill, and make the pucks act accordingly.

For Passive Skills, create multiple checking functions and run the checks for different types of effects. Checking times are: 
- When created,
- Collision with pucks or the cushion,
- Pucks are falling into the pocket area,
- Pucks are put back on the cue table, 
- Making or receiving Damage DO,
- Units are defeated,
- Before or after movement or attack,
- When a player plays a card,
- When a player makes a cue shot,
- When a card is completed and goes to the discard pile,
- When a player draws a card

This list should be managed. Add comments to the Skill Classes for that. Can use event listener pattern if it is better, but need to consider the return value.

## How to display Unit Skills

In the Unit Detail Display, the bottom part shows all skills of that unit. 

Skills are displayed as Icons. The first row, with proper spacing, shows the three Move, Attack, and Active Skill icon slots (leaving an empty slot frame if the unit has no Active Skill). Below it shows all Passive Skill icons. Skills with a *Skill Countdown* or counter also display a live badge on the icon.

When the player hovers the mouse on a skill icon, a *Skill Display* window appears, showing the name, type, skill Lv, and `Description` of the skill (do not display the raw `Effects` implementation text). The `Description` is injected with resolved variable values (e.g. `?X`, `?Y` evaluated at the skill's current `Lv` and counter) and allows styling: keywords (marked as `*keyword*` in the skill codex) and resolved variable values are highlighted in different colours. At the bottom of the *Skill Display*, show the meaning of the highlighted keywords that appear in that skill. 


## Game managers

Create a Unit Skill Manager to handle:
- Common Skills effects
- Handle skill effects that across more than one units
- Handle a map to skills at different triggering times so that other logic no need to loop all the skills to check 
- Manage the Skills type and belongs