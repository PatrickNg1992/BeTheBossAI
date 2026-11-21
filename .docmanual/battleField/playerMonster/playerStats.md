# Player Stats

Player Stats are shown on the canvas, including the following:

## HP bars

The Boss monster, like many other games, has multiple health bars. An x N indicator appears to the right of the health bar. 

The health bar is green when full, gradually shifting toward greenish-yellow as HP gets lower, with a black background and a blood-red Ghost bar (HP trailing) when damage is taken in Action Time or "Puck-puck time!". Alongside the Boss monster's HP bar (both in the upper-left HUD for the local seated player's Boss Monster and on any other Boss Monster's 2-cell Unit Display), the Boss monster's **Damage Stack** hit-count circle mark (on the left of the HP bar, invisible at 0, shaking on hit) and settled negative HP change number (e.g. `-567` at Settle Time) are displayed in the same way as for Minions and Enemy Adventurers. The Ghost bar should remain until Settle Time and fade out with an animation in Settle Time. The Boss monster will lock the HP when the current health bar is cleared and will not take more damage than that in a single Action Time or "Puck-puck time!". (Damage limited to at most 1 health bar per turn)

When an attack damage makes the current health bar less than or equal to 0, the health bar will be cleared. As a consequence, 

If N is 0, the Boss monster is defeated. 

If N is greater than 0, it will be reduced by 1 and start with the next health bar from 100% (excess damage during the previous health bar will not count). Then the player will draw 1 card.

Also, "breaking" visual effects appear on the health bar when it is cleared.

In the Test scene, start the monster with 15 health bars.
