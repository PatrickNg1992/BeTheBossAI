# Time Board Display

The time board is a board at the top of the battlefield scene canvas. It shows a few important pieces of information:

- The charging progress of energy,

- How much energy the player owns,

- Action tags that indicate when the units on board act

The board visualize the time information.

## Time board

The time board is displayed as two bars, upper or lower. Each bar consists of 10 slots. 

Typically, the board only move during *Charging time*, unless it is affected by some effects. (It stays over time and is only affected by other effects)

Both Action tags and energy move at the same constant speed. The charging time of 1 slot is like **1 turn** of the game. (The charge time is configurable, which is the thinking time of the player)



## Turn

A turn means the configurable time that

- charge a energy slot

- minimum time interval between two action time

- allow player to think and click the play button



## Action Tags

Action tags are indicators that show wheThe tag shows an integer indicating how many turns it will take may share the same tag, the unit's tag number is also displayed in its icon on the canvas for clarityn the units will act. Units tag their action time on the time board so the player knows when they will act.

Action tags stand on top of the upper bar and move from right to left over time, and stand below the lower bar and move from left to right. 

For Action tags, the upper bar is the primary. Once an action tag reaches the upper-left slot, an *Action time* will start to play the actions of the corresponding units. Meanwhile, when an action tag reaches the lower-right slot, it goes to the upper-right slot.

An integer number is shown in the tag showing how many turns it will take for the tag to reach the goal. Since there may be many units on the battlefield and more than one unit shares the same tag, for clarity, the integer of the tag of the unit is also displayed in its icon in the canvas.

## Energy

An energy bar indicator on the bars moves in the same direction as the action tags. However, it accumulates over time rather than moving towards a goal. 

Therefore, the primary bar of energy is the lower bar. 

When player energy is consumed, the energy indicator will go backwards.




