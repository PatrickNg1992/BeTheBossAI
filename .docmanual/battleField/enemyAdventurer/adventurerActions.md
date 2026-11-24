# Adventurer Actions

This document describes the Adventurer actions, including the turns, action tags, skills and action behaviours.

## When adventurers take Actions

Adventurers do count down in charging time. The countdown is called *Action Countdown*. The Action Countdown is stored and displayed as an *Action Tag* in the time board display and unit display. Whenever an energy slot is full, the Action Countdowns of all adventurers are reduced by 1. If any Action Countdown goes to Zero, the game enters Action Timing. The Adventurers whose Action Countdowns become 0 will act: they will move, attack or use skills. In Action Time, skills across all on-table acting units are evaluated by skill phase — **all Active Skills first, then all Attack Skills, then all Move Skills** — with units within each phase ordered by **`SPD` (speed)** descending (tie-broken by their order in the game). Move Skills execute unit by unit at constant speed and stop their glide immediately upon colliding with another puck or cushion. After all on-table acting units finish moving, any pocketed Adventurers whose Action Countdown reached 0 return to the table (ordered by `SPD` descending, consuming their action for that turn). After all acting units finish, the game enters Settle Time to settle. The action tags of those acted Adventurers will reset at the end of Settle Time. 

## Action Cycle

To make the Actions more comprehensive and smooth, every 12 turns (charging 12 energy slots) is an Action cycle. To be specific, all Adventurers have fixed Action Countdowns, and they must be factors of 12. This is a hard restriction that an Adventurer must have either 3,4 or 6 as its Action Countdown so that the Action Time will only happen at 3,4,6,8,9,12 of a 12 Action cycle to avoid adding too many Action Times in the game so the players don't always wait for the enemies to act. At the 12th time slot, almost all enemy Adventurers act together, which the player may consider to take defence actions. The Action tags at 12 intervals are highlighted in a special colour. 

Typically, Brawler and Guard classes and their advanced versions act at 4 intervals. Scouts act at 3 intervals, and Acolytes act at 6 intervals. Some of them can change their intervals with passive skills, but the interval is always a fixed value of a unit. 

## Class Actions

Every base class has a default action pattern, which can be changed by acquiring more skills in advanced classes. Read ./adventurerSkills.md for details

## Stun and Skip

Some player skills (TBC) can impose *Stun* on some Adventurers. Stun makes an Adventurer skip its original action in Action Time. 
