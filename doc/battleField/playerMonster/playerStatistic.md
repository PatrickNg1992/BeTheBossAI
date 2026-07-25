# Player Stats

Player Stats are shown on the canvas, including the following:

## HP bars

The Boss monster, like many other games, has multiple health bars. There is an x N indicator on the right of the health bar. 

The health bar is green when filled and black in the background. When the HP is reduced, a temporary red colour behind the green bar will be shown shortly to indicate the original position. 

When an attack damage makes the current health bar less than or equal to 0, the health bar will be cleared. As a consequence, 

If N is 0, then the Boss monster will be defeated. 

If N is larger than 0, it will be minus by 1 and start with the next health bar from 100% (excess damage during the previous health bar will not count). Then the player will draw 1 card, and the Boss monster will get 2 second invincible state.

Also a "breaking" visual effects on the health bar like are presented when a health bar is cleared.



In the Test scene, start the monster with 15 health bars.




