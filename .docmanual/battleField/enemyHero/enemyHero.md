# Enemy Hero

While controlling the boss monster, the player faces incoming heroes as enemies.

Heroes come in groups in each wave, called Hero teams. The player must defeat all the heroes in a wave to complete it. At most **12 heroes** are allowed in a single wave. (4 - 10 in common)

There is a random hero generation logic to be specified in ./heroGeneration.md

## Hero Basic

Each hero owns the following basic properties: 

- Class, which affects the activities and skills,

- LV, which indicates the strength,

- Max HP, which affects survivability, 

- Power, which affects the attack damage

Then, based on the basic properties, a hero will have:

- Current HP

- A basic attack  (determined by the class),

- An active skill (Optional),

- Passive Skills (Optional),

- Upcoming Actions

Typically, the player can defeat a hero by bringing his HP to 0.

The class system is desbribed in ./heroClasses.md

## Visualization

On the right side of the canvas in the battlefield scene, an area shows the basic information of the members of the hero team, called the *Hero Team Profile*.

The Profile shows a box for each hero in that wave. It displays the following info:

- Icon,

- HP bar,

- Class,

- A number and unique colour in the team,

- How many turns left for the next basic attack and active skills



If a hero is defeated, the icon turns grey, and a red cross mark appears on it. Hide the HP bar and all turn information.

If a hero is temporarily taken out of the game (like pocketed), the icon turns grey. Shows the turn number needed for it to come back instead. 

Each hero is represented by a puck on the table. The pucks are distinguished by the colour and number of the hero.

In Action timing, or "Puck-puck Time!", when the heroes take damage, the damage will display and accumulate under the profile. A Ghost Health bar (trail HP) will be displayed and kept until the settle time and fade out with animation. The defeat calculation will only take effect at the settle time but not at other times. The puck of a defeated hero will be removed.

## Action Tags

Heroes not only mark the turns left for their next basic attacks and active skills, but the information will also be displayed on the *Time Board Display*. 

Heroes with the same turns left for the upcoming action will share the same tag. An action tag will mark 2 numbers: the count of heroes using this tag and the turns remaining. 

Once a hero decides when the next actions will be (either entering the game, completing an action, or being taken out of the table, etc), it will show the action tag. If a tag for that turn is already there, just change the count of heroes. Otherwise, create a tag with count = 1.

Remove an action tag with a count of 0.

Typically, a hero has 1 to 2 action tags. One active skill can coexist with a basic move.

A hero may change its targeted next action in settle timing, after some moves in action timing or "Puck-ppuck timing!".

## Focusing State and Attack

A unit (puck) can change to focusing state before attack. This gives the player time to take appropriate actions. 

A unit enters focusing state under specific conditions based on its class. In most cases, it depends on the distance between it and other pucks. If a puck is focusing, it has lighting visual effects. Player are often recommended to hit a focusing pucks in "Puck-puck time!". (Except classes like Knight)

## Hero move

Most heroes move at constant speed without a physical engine in Action timing. No collision detection is needed. 

## Number size

The max and attack damage are expected to be at about hundreds or thousands level.
