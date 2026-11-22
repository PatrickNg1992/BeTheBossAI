# Passive Skill Level 1 Adventurer

## Name: Protect

- ID: 0001
- LV: 1-3

- Type: Base Skill
- For: Guard
- Description: Reduce Frenzy Power of opponent Boss Monster on hit based on non-guard teammates number.
- Effects: When the opponent's Boss Monster hits this puck, reduce its Frenzy power by `?Y` (need to count the normal +10.0%). 
- Var: 
  - ?X = the number of non-guard or advanced-class units
  - ?Y = `X * (4% + Lv * 1%)`

## Name: Safety Rope

- ID: 0002

- LV: 1-3

- Type: Base Skill

- For: Scout

- Description: Pocket area damage `-?X%` for teammates.

- Effects: If this unit is on the cue table, apply Pocket Area damage `-?X%` to all units in the same team. 

- Var: ?X = `10 + Lv * 3`
