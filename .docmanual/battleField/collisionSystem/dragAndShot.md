# Drag and Shot

The player can shoot the monster puck by dragging.

## Drag and Aim

A player can click on the monster puck and drag to make a shot.

- This action only works in “Play time”, when the timing freezes all pucks.
- The shooting direction is opposite to the drag direction.
- When the player holds the click and drags, an aiming line will be shown. The aiming line should show the monster puck's first rebound. Also, the first hit is another puck; show another line to show the direction that pucks will go.
- The player can control how many energy slots to consume by controlling the drag distance. When the player holds the click and drags, the time board will show a different colour on the energy slots required, starting from the bottom-left (slot 0, the start point of the first energy). If the energy required exceeds what the player owns, the red part continues past the filled energy slots.
- The unit of energy consumption of a shot is half of a slot (0.5). For the demo, a minimum of 1 slot and a maximum of 9 slots (1.0, 1.5, ..., 9.0) are available for a single shot (undecided final values; testing the half-slot case first, may simplify later).
- When the player releases the drag, the puck is shot out. However, if the drag is released very close to the puck or the player does not have enough energy (over-dragged), the shot will be cancelled (staying in "Play time"). When the shot is cancelled, play a sound of cancellation.
- An **Impulse** is applied to the puck when shot. The impulse is proportional to the energy consumption ($J \propto E$), and initial velocity is $v_0 = J / m$, so a heavier Boss Monster starts with a slower speed.
- After a shot is made, the game enters “Puck-puck time!”.

## Aiming line

- A 3D arrowed line at `Y = 1.55` indicating the direction the Boss Monster puck will shoot, swept using the Boss Monster's radius.
- The reach of the aiming line is proportional to the Impulse to be applied. If no obstacle is within that reach, the arrow ends there.
- If a cushion or another puck is hit within that reach, a ghost contact ring is shown at the impact point along with the Boss Monster's first rebound arrow ($\vec{v}_{1f}$).
- When the first hit is another puck, a contrasting arrow is also drawn from the hit puck's center showing its outgoing direction ($\vec{v}_{2f}$). Both post-hit arrow lengths are proportional to their post-impact speeds ($\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$) from `collisionSystem.md`. All aiming visuals turn red when over-dragged.
