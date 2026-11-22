# Battlefield Design

## Cue Table

The game battlefield is similar to a cue game. The main field is like a cue table, which has a flat floor and cushions on four sides. The inner area of the table should be 30 × 20. (with 3 as height)

The table is split into 15 × 10 square tiles, each 2 × 2 in size. For the test scene, please use alternative green and light green for the tiles. Some tiles may generate special effects in the future.

The cue table has collision body preventing the pucks fall, except the pocket area.

### Cushion

The cushion width should be 2, and the height above the table should also be 2. As the table is 30 × 20 in size, the sides of the cushion are 34 and 24.

On the cushions, similar to the table, every 2 lengths are split. In the test scene, use brown and light brown to distinguish. Some split lengths may have special effects; these areas are called *Special Cushions*. When *pucks* hit the Special Cushion, the effects will be triggered.

The corner squares at the upper left and lower right are the same colour, and the remaining two are another colour.

The cue table has collision body preventing the pucks fall outside.

### Pockets Area

In some of the tiles at the 4 corners on the cue table, there are special areas called Pocket Areas (which are like the pockets in a snooker game). The pocket areas are hollow.

When a puck falls into a Pocket Area, it will take damage and be removed from the battlefield first. If the unit's health is too low, it will be killed. Otherwise, it will come back to the field a few *Turns* later.

Each Pocket Area is 2 × 2 in size.

A Pocket Area is a special kind of table floor block. Instead of a hole, make it look like a black swirl or a black hole. When a puck gets close to the centre of the pocket area (i.e. the puck's centre reaches the 3/4 rectangle length), its horizontal velocity decelerates dramatically, and it starts to fall vertically. When start to fall, make the puck collider no longer valid so that it will pass through the floor. Also, the puck will rotate vertically first, so the side near the centre falls.

## Syle

The table should be medieval style, like:

- wooden style cushion
- grass-style cushion
- flags on corners, etc

### Changible blocks

The table squares and the side segments of the cushions are configurable. They may change into blocks with special effects and style. Each block should be assigned with a number so the code and control them later.

### Obstacle or Other things

TBA

### Camera

The camera position can be changed to view from another rail side. There are two buttons, left and right, on the screen, so move the camera to another side. It takes about 1 second after clicking the buttons to move to another side.

While it is already moving after clicking the button

## Pucks

Meanwhile, the units, including Boss Monster, Enemy Adventurers and minions, stand like pucks instead of cue balls. The size of the pucks differs based on what they represent. Typically, a large monster will have a large puck, and a small acolyte enemy will have a small puck.

For the test scene (default puck radius and mass for Adventurer classes are defined in `./.docmanual/codexList/classes/`):

Make the puck with (radius, height, mass):

- Boss Monster: radius `0.8`, height `0.6` (`0.5 * 1.2`), mass `3.2` (`1.5 * (0.8 / 0.6)^2 * 1.2`)
- Guard: radius `0.65`, height `0.4`, mass `1.75`
- Brawler: radius `0.6`, height `0.35`, mass `1.5` (reference mass)
- Scout: radius `0.57`, height `0.35`, mass `1.35`
- Acolyte: radius `0.55`, height `0.35`, mass `1.25`

## Timing

To let the player enjoy both the snooker and auto-fighting, game time should be separated into different sections. Read files ./timingSystem folder

## Pucks Moving
