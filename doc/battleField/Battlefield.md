# Battlefield

## ## Cue Table

The game battlefield is similar to a cue game. The main field is like a cue table, which has a flat floor and cushions on four sides. The inner area of the table should be 20 × 20. (with 3 as height)

The table is split into 10 × 10 square tiles, each 2 × 2 in size. For the test scene, please use alternative green and light green for the tiles. Some tiles may generate special effects in the future.

### Cushion

The cushion width should be 2, and the height above the table should also be 2. As the table is 20 × 20 in size, the longest side of the cushion is 24.

On the cushions, similar to the table, every 2 lengths are split. In the test scene, please use brown and light brown to distinguish. Some split lengths may have special effects; these areas are called *Special Cushions*. When *pucks* hit the Special Cushion, the effects will be triggered.

The corner squares at upper left and lower right are the same colour, and the remaining two are another color.

### Pockets Area

In some of the tiles at the 4 corners on the cue table, there are special areas called Pocket Areas (which are like the pockets in a snooker game). The pocket areas are hollow.

When a puck falls into a Pocket Area, it will take damage and be removed from the battlefield first. If the unit's health is too low, it will be killed. Otherwise, it will come back to the field a few seconds later.

Each Pocket Area is 2 × 2 in size.

### Obstacle or Other things

TBA

### Camera

The camera position can be changed to view from another rail side. There are two buttons, left and right, on the screen, so move the camera to another side. It takes about 1 second after clicking the buttons to move to another side.

While it is already moving after clicking the button

## Pucks

Meanwhile, the units, including Boss Monster, Enemy Heroes and minions, stand like pucks instead of cue balls. The size of the pucks differs based on what they represent. Typically, a large monster will have a large puck, and a small mage enemy will have a small puck.

For the test scene:

Make the puck with (radius, height):

- Boss Monster: 1.5, 1
- Knight: 1.2, 0.8
- Warrior: 1.1, 0.7
- Ranger: 1.0, 0.7
- Mage: 0.9, 0.7

## Pucks Moving
