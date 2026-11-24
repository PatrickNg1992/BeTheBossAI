# Common Skill Effects

## Skill Countdown

Some skills will not take effect every Action Time a unit participates. Skill Countdown is the minimum number of turns that must pass before the skill can activate again. The Skill Countdown of a skill start with the value, but not 0. The countdown resets only when the skill fulfilled its activation conditions and activated.

For example, if a Guard has a skill with Skill Countdown 9 while it has Action Countdown 4, it means the skill takes at least 3 Action Time to take effect again. 

## On the cue table

This condition means that 
- the unit is not defeated, and
- there is at least one puck of that unit on the table, not including fallen into the pocket area;
- If the unit is in conditions like invisible, it still counts.

## Pocket Area Damage +/-?%

When a unit falls into the Pocket Area, calculate all the passive effects to adjust the damage it should take. The default Pocket Area Damage value is 50% of the max HP for all units (only count 1 HP bar). The resulting value must be within 0 to 100%, and the resulting `Damage DO` is marked `is_fixed = true` (meaning it is not affected by `Hit Level` or `Frenzy Power` during Damage Settlement). 

For example, if two Scouts with skill apply -10% each to teammates and a Boss monster skill apply +15% to all enemies, a unit should take 45% damage when fallen into pocket.

## Statistic Buff/Debuff

Some effects increase/decrease a unit's statistics(max HP/POW/SPD). There are two types of such kind of effect: percentage or flat value. For percentage, it work on the base value, which means the unit's original statistics after considering the Unit Lv. For flat value, it add/minus the stated value directly. 

If there are more then 1 percentage effects acting on the same value, sum up the percentage. Flat value effects are calculated after percentage effects. Round the result to nearest integer. Whenever a Statistic Buff/Debuff effects activate or deactivate on a unit, recalculate the value.

When max HP is increase or decrease, no need to adjust HP. The only exception is that HP should never higher than max HP. Therefore, set HP = max HP if after a decrease in max HP, the HP is higher than it.

For example, a unit at Lv5 with 280 POW, with two +20% buff and one +100, the final value will be `280 * 140% + 100` = 492