# Unit Information Board

Unit Information Board is a canvas board that shows unit information on the battlefield. 

## General

It appears on the left and right of the screen, corresponding to the two sides of the game. In different game modes, each side shows different units.

On each side, the board looks like a table with 2 columns and multiple rows. The cell is called a *Unit Display*. Each Unit Display holds a unit. 

For flexibility, the board has 8 rows and can display up to 16 Units on each side.

The unit information board work closely with the unit manager (see ./unitInformationManager.md) to show the unit information to the players.

### Unit Display

Each cell shows the unit's image. Below the cell is the unit's HP bar. In the upper-left corner of the cell, a *Reference Mark* lets players match the unit and its corresponding pucks. 

The Unit Display for boss monsters spans 2 horizontal cells, which looks great. For the player's boss monster, its Unit Display does not show the HP because that information appears in the upper-left corner of the screen. It only shows the current HP bar and remaining HP bar count of the opponent's boss monster.

If the unit is an enemy adventurer, a *Class Mark* appears in the upper-right corner to tell what class the unit is.

When a player hovers the mouse over a Unit Display, the corresponding puck on the table will be highlighted so they can spot the puck easily. When a player clicks on the Unit Display, a small pop-up window named *Unit Detail Display* will appear to the side.

Defeated units will have a grey Unit Display, and their HP bar will disappear. 

The Unit Display should show the Ghost HP bar according to the Damage Stack. (Check the Unit Information Manager document) The Damage Stack count (how many time of damage taken) should be displayed on the right of the unit image. 

### Unit Detail Display

The Unit Detail Display shows more detail about a unit. It appears when the player hovers over the Unit Display. The Unit Detail Display closes when the player clicks elsewhere.

(TBC) Information to be shown:

- Unit name

- Detail class name and the Class mark icon of the unit, if it is an adventurer

- HP and Max HP value

- Skills of the unit

- Special Condition of a unit

- Attack power of the unit

- Mass and radius of the puck

- Unit's status: buff, debuff, conditional status

### Skill and Damage effects

The unit displays show visual effects to improve the game's look. 

In "Puck-puck time!", when the unit puck collides with other pucks on the table, the unit display should shake to a degree corresponding to the Impulse received. 

In Settle timing, when a unit has taken damage or is defeated, animations will play on the unit display.

When the skills of a unit are triggered, the skill icon will pop up shortly.

## Single-player game

In a single-player PvE game, the left side shows the player's boss monster and the minions, while the right side shows the enemy adventurers. 

On the right side, since two adventure teams are available and each team may consist of up to 6 members, the unit display only needs 12 cells. The first and the eighth rows are reversed to show the team name.

## 2-player vs game

Each side shows one player's boss monster and the minions.

### Reference Mark

Reference marks identify different pucks on the cue table. A reference mark marks the same symbol on the upper-left Unit Display and the middle of the puck of a unit. Each wave uses unique marks.

The members of the first Adventurer Team are marked as A1, A2, A3, A4, A5 and A6. Meanwhile, the members of the second Adventurer Team are marked as B1, B2, B3, B4, B5 and B6. For easy identification, in general the reference number will be arranged by unit classes that ?1 is guardian class, ?2 is warrior class, ?3 is ranger class, ?4 is magician class. ?5 and ?6 are free positions. Therefore, some numbers may be missing in the middle for some small teams.

Also, the puck colour shall be different for different classes, but to be specified in other document.

(This logic affects the enemy random algorithm)

On the player side, the boss monster of player A (or the player of a single-player game) is marked as Ω and the minions are marked as ωI, ω2, ω3...The boss monster of player B is marked as Ψ and the minions are marked as ψ1, ψ2, ψ3...
