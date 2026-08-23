# Player Stats

Player Stats are shown on the canvas, including the following:

## HP bars

The Boss monster, like many other games, has multiple health bars. An x N indicator appears to the right of the health bar. 

The health bar is green when filled and black in the background. When HP is reduced in Action time or "Puck-puck time!", a Ghost bar (HP trailing) should appear. The Ghost bar should remain until Settle Time and fade out with animation. The Boss monster will lock the HP when the current health bar is cleared and will not take damage more than that in a single Action time or "Puck-puck time!". (Damage limited to at most 1 health bar per turn)

When an attack damage makes the current health bar less than or equal to 0, the health bar will be cleared. As a consequence, 

If N is 0, then the Boss monster will be defeated. 

If N is larger than 0, it will be minus by 1 and start with the next health bar from 100% (excess damage during the previous health bar will not count). Then the player will draw 1 card.

Also, "breaking" visual effects appear on the health bar when a health bar is cleared.

In the Test scene, start the monster with 15 health bars.
