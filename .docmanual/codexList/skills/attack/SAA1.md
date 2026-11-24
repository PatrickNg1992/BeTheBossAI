# Attack Skill Level 1 Adventurer

## Name: Lance
- ID: 0001
- Lv: 1-11
- Type: Attack Skill/Base Skill
- For: Guard
- Description: *Skill Countdown*: 9. Attack a random enemy nearby for `?X%` POW and apply *Hit Level*+2. *Skip Movement*.
- Effects: *Skill Countdown*: 9. Do a distance check against all opponent's pucks. If there are pucks within 3.5 distance (edge to edge), attack one random puck. *Skip Movement*. *Hit Level*+2.
- Animation: A lance moves towards the target.
- Ratio: `?X%`
- Var: ?X = `90 + Lv * 10`



## Name: Melee
- ID: 0002
- Lv: 1-11
- Type: Attack Skill/Base Skill
- For: Brawler and Advanced Classes
- Description: Close melee attack to the nearest target for `?X%` POW and apply *Hit Level*+1. *Skip Movement*.
- Effects: Do a distance check to all opponent pucks. If the distance between the puck and the nearest opponent puck is within 1.5 (edge to edge), attack it. *Skip Movement*. *Hit Level*+1.
- Animation: A sword swipe towards the attack target.
- Ratio: `?X%`
- Var: ?X = `90 + Lv * 10`



## Name: Shoot
- ID: 0003
- Lv: 1-11
- Type: Attack Skill/Base Skill
- For: Scout and Advanced Classes
- Description: Do a Shoot attack while moving for `?X%` POW and apply *Hit Level*+1.
- Effects: Do a distance check against all opponent pucks. Choose a random opponent's puck within 7.5 distance to attack (centre to centre). *Hit Level*+1.
- Animation: An arrow shoots towards the attack target.
- Ratio: `?X%`
- Var: ?X = `45 + Lv * 5`



## Name: Spell Attack
- ID: 0004
- Lv: 1-11
- Type: Attack Skill/Base Skill
- For: Acolyte or Advanced Classes
- Description: *Skill Countdown*: 12. Use Spell to attack the *Boss Monster* for `?X%` POW and apply *Hit Level*+3. *Skip Movement*.
- Effects: *Skill Countdown*: 12. Attack the opponent's *Boss Monster*. *Skip Movement*. *Hit Level*+3.
- Animation: A magic attack shoots towards the target.
- Ratio: `?X%`
- Var: ?X = `225 + Lv * 25`


