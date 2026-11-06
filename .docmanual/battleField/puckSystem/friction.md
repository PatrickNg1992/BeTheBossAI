# Ground effect (Friction)

Moving pucks experience friction, so they gradually slow down. The friction deceleration depends on the table ground type and effects.

## Friction calculation

For each physics update moment, each puck detects the ground block it is standing on. Then compute the force applied to the puck.

Many block types have different force effects on the pucks. Typically, a friction force acts opposite the puck's motion. The friction should be proportional to the mass of the pucks. For the standard block, it should apply -1unit/sec^2 to a puck. (ie. If a puck travel in 5unit/sec, it should slow to 4unit/sec after a second) Add a small threshold so the puck stops instead of moving in the opposite direction due to deceleration.

Create an extendable script for floor blocks. The script has a function to calculate the force to apply, which takes the pucks' information as input parameters. 


