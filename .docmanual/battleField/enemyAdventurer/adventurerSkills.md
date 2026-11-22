# Adventurer Skills

This document describes the Adventurer Skill system. It explains which skills an Adventurer should have and how they affect the game.

Read .docmanual/battleField/unitInformation/unitSkills.md to get the basic concept of Unit Skills that are allied to all Units.

## Skills Combination

For Adventurers, the Move Skills, Attack Skills and Active Skills are typically class-restricted. A unit of a certain class can only acquire these 3 types of skills of that class or the prerequisite classes.

Every Base Class has a fixed Move Skill and Attack Skill called Basic Skills, which are described below. Some classes also have some passive skills.

## Basic Skills

- Name: Block LV1
  
  - Type: Move Skill/Base Skill
  
  - For: Guard or Advanced Classes
  
  - Description: Move to protect the allies.
  
  - Effects: If there are friendly units with Scout or Acolyte, or their Advanced classes, calculate lines between the opponent's Boss Monster and them. Move towards a random position on the lines that are within a 180-degree angle from the boss monster (avoid moving past the boss) that is close to the Guard. If there are no such units, try to move around the boss within a distance of 1 to 3 randomly. Max distance to move is 1.5.

- Name: Lance Lv1
  
  - Type: Attack Skill/Base Skill
  - For: Guard or Advanced Classes
  - Description: Attack a random enemy nearby.
  - Effects: Skill Countdown: 9. Do a distance check against all opponent's pucks. If there are pucks with 3.5 distance (edge to edge), attack one random pucks of them and skip movement. Increase the target's Hit level by 2. Damage: 200.
  - Animation: A lance moves towards the target.

- Name: Protect Lv1
  
  - Type: Passive Skill/Base Skill
  - For: Guard or Advanced Classes
  - Description: Reduce damage from enemies for every non-guard unit in the team.
  - Effects: Count the number of non-guard or advanced-class units; call it X. When the opponent's Boss Monster git this puck, reduce its Frenzy power by X times 5.0% (need to count the normal +10.0%). When taking damage from the opponent team, reduce that damage value by X times 5% (does not apply to pocket area damage).

- Name: Approach LV1
  
  - Type: Move Skill/Base Skill
  
  - For: Brawler and Advanced Classes
  
  - Description: Move towards the nearest enemy.
  
  - Effects: Move towards the nearest opponent's unit at an angle within 90 degrees. Move a random distance of 0.8-1.2.

- Name: Melee LV1
  
  - Type: Attack Skill/Base Skill
  
  - For: Brawler and Advanced Classes
  
  - Description: Close melee attack to the nearest target.
  
  - Effects: Do a distance check to all opponent pucks. If the distance between the puck and the nearest opponent puck is within 1.5 (edge to edge), attack it and skip the Move Skills. Increase the Hit level of the target by 1. Damage: 200.
  
  - Animation: A sword swipe towards the attack target.

- Name: Patrol LV1
  
  - Type: Move Skill/Base Skill
  
  - For: Scout and Advanced Classes
  
  - Description: Keep a suitable distance from the target.
  
  - Effects: Do a distance check against the opponent's boss monster. If the distance is less than 4.5, move away. If the distance is more than 6, move closer. In these two cases, the moving direction should be within 60 degrees. Otherwise, move in a random direction. Move a random distance of 0.8-1.2.

- Name: Shoot LV1
  
  - Type: Attack Skill/Base Skill
  
  - For: Scout and Advanced Classes
  
  - Description: Do a Shoot attack while moving.
  
  - Effects: Do a distance check against all opponent pucks. Choose a random opponent's puck within 7.5 distance to attack (centre to centre). Increase the Hit level of the target by 1. Damage: 100.
  
  - Animation: An arrow shoots towards the attack target.

- Name: Safety Rope Lv1
  
  - Type: Passive Skill/Base Skill
  
  - For: Scout or Advanced Classes
  
  - Description: Pocket area damage -10% for teammates.
  
  - Effects: If this unit is on the cue table, apply Pocket Area damage -10% to all units in the same team. 

- Name: Move Away LV1
  
  - Type: Move Skill/Base Skill
  
  - For: Acolyte and Advanced Classes
  
  - Description: Keep far away from the Boss Monster.
  
  - Effects: Check whether the opponent's boss monster is on the left or right of the cue table. Then check whether this puck is in the farthest area on the other side, within a width of 2. If not, move towards that area in a direction within a 60-degree angle with a random distance of 1.8-2.2. If yes, stay still.

- Name: Spell Attack Lv1
  
  - Type: Attack Skill/Base Skill
  - For: Acolyte or Advanced Classes
  - Description: Use Spell to attack the boss monster.
  - Effects: Skill Countdown: 12. Attack the opponent's boss monster and skip movement. Increase the target's Hit level by 3. Damage: 500.
  - Animation: A magic attack shoots towards the target.
