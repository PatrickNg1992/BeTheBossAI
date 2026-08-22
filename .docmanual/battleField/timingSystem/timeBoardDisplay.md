# Time Board Display

The time board is a board at the top of the battlefield scene canvas. It shows a few important pieces of information:

- The charging progress of energy,

- How much energy the player owns,

- Action tags that indicate when the units on board act

## Time board

The time board is display as two bar, upper or lower. Each bar contains of 10 slot. 

Typically, the board only move during *Charging time*, unless it is affected by some effects. 

Both Action tags and energy move in same constant speed. The charging time of 1 slot is like **1 turn** of the game. (The charge time is configurable that is the thinking time of player)

## Action Tags

Action tags are indicator that show when will the units act. Units tag their action time on the time board so the player knows when will they act.

Action tags stands on top of the upper bar and move from right to left over time, and stands below the lower bar and move from left to right. 

For Action tags, the upper bar is the primary. Once an action tag reach the most upper left slot, a *Action time* will start to play the actions of the corresponding units. Meanwhile when an action tag reach the most lower right slow, it go the upper right slot.

A integer number is shown in the tag showing how many turns will the tag reach the goal. Since there may be many units in the battlefield and more than one units share a same tag, for clearance, the integer of the tag of the unit are also displayed in their icon in the canvas.

## Energy

A energy bar indicator on the bars move in the same direction as the action tags. However, its accumulate over time rather than moving towards a goal. 

Therefore the primary bar of energy is the lower bar. 

When player energy is consumed, the energy indicator will go backward.




