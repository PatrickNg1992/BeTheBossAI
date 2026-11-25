# Enemy Adventurer

While controlling the boss monster, the player faces incoming adventurers as enemies.

Adventurers come in groups in each wave, called Adventurer teams. The player must defeat all the adventurers in a wave to complete it. Each team consists of at most 6 adventurers. 1 or 2 teams are allowed in a single wave. (4 - 12 adventurers in common)

There is a random adventurer generation logic to be specified in ./adventurerGeneration.md

## Adventurer Basic

Each adventurer owns the following basic properties: 

- Class, which affects the activities and skills,

- LV, which indicates the strength,

- Max HP, which affects survivability, 

- Power, which affects attack damage

Then, based on the basic properties, an adventurer will have:

- Current HP

- A basic attack  (determined by the class),

- An active skill (Optional),

- Passive Skills (Optional),

- Upcoming Actions

Typically, the player defeats an adventurer by reducing their HP to 0.

The class system is desbribed in ./adventurerClasses.md

## Visualization

On the right side of the canvas in the battlefield scene, an area shows the basic information of the members of the adventurer team, called the *Unit Information Board*.

The Profile shows a box for each adventurer in that wave. It displays the following info:

- Icon,

- HP bar,

- Class,

- A number and unique colour in the team,
- How many turns left for the next action (Action Countdown)



If an adventurer is defeated, the icon turns grey, and a red cross mark appears on it. Hide the HP bar and all turn information.

If an adventurer is temporarily taken out of the game (like pocketed), the icon turns grey. If not defeated, it comes back at its next Action Time (its Action Countdown continues as normal and the Time Board Action Tag counts remain unchanged; returning consumes its action for that turn, and it respawns after all on-table acting units finish moving, ordered by `SPD` descending).

Each adventurer is represented by a puck on the table. The pucks are distinguished by the colour and number of the adventurer.

In Action timing, or "Puck-puck Time!", when the adventurers take damage, the damage will display and accumulate under the profile. A Ghost Health bar (trail HP) will be displayed and kept until the settle time and fade out with animation. The defeat calculation will only take effect at the settle time but not at other times. The puck of a defeated adventurer will be removed.

## Action Tags

Action Tags marks the turns that adventurers potentially take actions. Therefore, the 3,4,6,8,9,12 turns of each 12-turn cycle have Action Tags. For each Action Tags with in 10 turns(the upper Timeboard bar), there is a number indicating the number of advanturers who will act. Action Tag exist even if a turn has no adventurer to move. The Action tags count all advanturers no matter their teams. (If a guard move in 4-turn interval, the Action Tags at 4,8,12 should all `+1`) Action tags at 12 are sightly larger and in different color.

The tags appeared as a arrow with a circle on top. Inside the circle indicate the number. If a tag has 0 count, the circle and the number disappear.

Adventurers mark the turns left for their next action (*Action Countdown*) on the right on the Unit Display. See `./adventurerActions.md` for the full 12-turn Action Cycle design. When a unit is defeated, update the Action tags and unit display.

Each adventurer has a fixed Action Countdown that is a factor of 12 (`3`, `4`, or `6`). Remove an action tag when its countdown reaches `0`. Individual Attack and Active Skills have their own `Skill Countdown` checked when the unit acts in Action Time (see `./adventurerSkills.md` and `../unitInformation/unitSkills.md`).

## Focusing State and Attack

Existing base skills take effect immediately in Action Time and are non-interruptible.

For specific future/advanced interruptible skills, a unit (puck) can change to a **Focusing** state before its attack lands, giving the player time to take appropriate counter-actions. When a puck is focusing, it has lighting visual effects, and players are often recommended to hit focusing pucks in "Puck-puck time!" (except classes in the Guard tree).
## Adventurer move

Most adventurers move at constant speed without a physical impulse engine in Action timing. Move Skills resolve an *Adjusted Target Position* via the Move Glide Logic (`.docmanual/battleField/unitInformation/unitSkills.md`) in `SPD` descending order and glide to it with their collider disabled during the movement. 

## Number size

The max and attack damage are expected to be at about hundreds or thousands level.
