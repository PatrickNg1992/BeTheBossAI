# Move Skill Level 1 Adventurer

## Name: Block
- ID: 0001
- Lv: 1-3
- Type: Base Skill
- For: Guard
- Description: Move to protect allies from the opponent's *Boss Monster*.
- Effects: If there are friendly units with Scout or Acolyte, or their Advanced classes, calculate lines between the opponent's *Boss Monster* and them. Move towards a random position on the lines that are within a 180-degree angle from the boss monster (avoid moving past the boss) that is close to the Guard. If there are no such units, try to move around the boss within a distance of 1 to 3 randomly. 
- Dist: `0.0-1.3 + Lv * (0.0-0.2)`

## Name: Approach
- ID: 0002
- Lv: 1-3
- Type: Base Skill
- For: Brawler
- Description: Move towards the nearest enemy.
- Effects: Move towards the nearest opponent's unit at an angle within 90 degrees. 
- Dist: `0.8-1.0 + Lv * (0.0-0.2)`

## Name: Patrol
- ID: 0003
- Lv: 1-3
- Type: Base Skill
- For: Scout
- Description: Keep a suitable distance from the opponent's *Boss Monster*.
- Effects: Do a distance check against the opponent's *Boss Monster*. If the distance is less than 4.5, move away. If the distance is more than 6, move closer. In these two cases, the moving direction should be within 60 degrees. Otherwise, move in a random direction. 
- Dist: `0.8-1.0 + Lv * (0.0-0.2)`

## Name: Move Away
- ID: 0004
- Lv: 1-3
- Type: Base Skill
- For: Acolyte
- Description: Keep far away from the opponent's *Boss Monster*.
- Effects: Check whether the opponent's *Boss Monster* is on the left or right of the *Cue Table*. Then check whether this puck is in the farthest area on the other side, within a width of 2. If not, move towards that area in a direction within a 60-degree angle, at a random distance. If yes, stay still.
- Dist: `1.5-2.0 + Lv * (0.0-0.2)`
