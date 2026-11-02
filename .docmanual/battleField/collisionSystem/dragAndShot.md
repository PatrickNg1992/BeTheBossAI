# Drag and Shot

The player can shoot the monster puck by dragging.

## Drag and Aim

A player can click on the monster puck and drag to make a shot.

- This action only works in “Play time”, when the timing freezes all pucks.
- The shooting direction is opposite to the drag direction.
- When the player holds the click and drags, an aiming line will be shown.
- The player can control how many energy slots to consume by controlling the drag distance. When the player holds the click and drags, the time board will show a different colour on the energy slots required. If the energy required exceeds what the player owns, display it in red.
- The unit of energy consumption of a shot is half of a slot. Typically, a minimum of 1 slot and a maximum of 10 slots are available for a single shot.
- When the player releases the drag, the puck is shooted out. However, if the drag is released at very close to the puck or the player does not have enough energy, the shot will be cancelled. When the shot is cancelled, play a sound of cancellation.
- A force is applied to the puck when shoot. The force is proportional to the energy consumption.
- After a shot is made, the game enters “Puck-puck time!”.

## Aiming line

Details TBC; need to combine with the collision system.

Now show an arrowed line indicating the direction the pucks will shoot. The length is proportional to the force to be applied.
