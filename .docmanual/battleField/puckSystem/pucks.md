# Pucks

In "Puck-puck Time!", the game should let the pucks collide freely using classic physics. To make it work, each puck needs an internal state stored in a script. To be specific, a puck should have radius, mass and velocity. The physics calculation should be done by a tailor-made calculation, as specified in other Markdown files in this folder. This design allows flexibility to introduce more game mechanisms in the future. The original

## Motion change

The velocities of the pucks are affected by *Impulse* or *Force*. Impulse are one-off velocity changes. Collision and cue shots apply Impulse to pucks. Forces are continuous velocity changes over time. Friction applies Force to pucks. Meanwhile, cards and units effects may apply impulse or force.

## Calculation

The position change due to velocity should be calculated in each update on the host and synced to all players with MultiplayerSynchronizer. 

The velocity changes are calculated in each physics update, which should be less frequent. Calculate it about 20 times per second.

May create a puck velocity manager in the battlefield to calculate the velocity change of all pucks.






