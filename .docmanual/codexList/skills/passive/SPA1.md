# Passive Skill Level 1 Adventurer

## Name: Protect
- ID: 0001
- LV: 1-3
- Type: Base Skill
- For: Guard
- Description: Reduce *Frenzy Power* of opponent *Boss Monster* on hit by `?Y%` based on non-guard teammates (`?X`), doubled on first hit, and reduce *Collision Damage* by 50% on both pucks when colliding with same-team allies.
- Effects: When the opponent's *Boss Monster* hits this puck, reduce its *Frenzy Power* by `?Y%`. If this puck is the first puck the *Boss Monster* hit in a shot, multiply the reduce value by 2. (need to count the normal +10.0%). When this puck collides with an ally in the same team, reduce the *Collision Damage* taken on both pucks by 50% (fixed, not affected by skill Lv; this reduction only applies once per collision even if both colliding pucks have Protect).
- Var: 
  - ?X = the number of non-guard or advanced-class units
  - ?Y = `X * (4 + Lv * 1)`

## Name: Heavy Hit
- ID: 0002
- LV: 1-3
- Type: Base Skill
- For: Brawler
- Description: Increase the damage to *Boss Monster*'s balance value.
- Effects: (TBC)
- Var: 

## Name: Safety Rope
- ID: 0003
- LV: 1-3
- Type: Base Skill
- For: Scout
- Description: While *On the cue table*, apply *Pocket Area Damage* `-?X%` for teammates.
- Effects: If this unit is *On the cue table*, apply *Pocket Area Damage* `-?X%` to all units in the same team. 
- Var: ?X = `10 + Lv * 3`


## Name: Chanting
- ID: 0004
- LV: 1-3
- Type: Base Skill
- For: Acolyte
- Description: Increase POW by `?X%` in each *Action Time*. Reset when fallen into *Pocket Area*.
- Effects: At the start of each *Action Time* of this unit, increase the skill counter by 1. Increase the unit POW by `?X%`. The counter resets if the unit falls into a *Pocket Area*. Skip the counter increment if the unit returns from a *Pocket Area*.
- Var: 
  - ?N = the skill counter value
  - ?X = `N * (7.5 + Lv * 2.5)`