# Unit Information Board

Unit Information Board is a canvas board that shows unit information on the battlefield. 

## General

It appears on the left and right of the screen, corresponding to the two sides of the game. In different game modes, each side shows different units.

On each side, the board looks like a table with 2 columns and multiple rows. The cell is called a *Unit Display*. Each Unit Display holds a unit. 

For flexibility, the board has 8 rows and can display up to 16 Units on each side. For easy description, we number them as three letters: (L/R)(1-2)(1-8), which means {Left/right board}{Column Num}{Row Num}. The unit number ordering should follow L11, L12, L21, L22, L31, L32, L41, L42, L51, L52......Same for the right side

The unit information board works closely with the unit manager (see ./unitInformationManager.md) to show the unit information to the players. The board listens to events from the manager.

### Unit Display

Each cell shows the unit's image. Below the cell is the unit's HP bar. In the upper-left corner of the cell, a *Reference Mark* lets players match the unit and its corresponding pucks. 

The Unit Display for boss monsters spans 2 horizontal cells, which looks greater. For the player's boss monster, its Unit Display does not show the HP because that information appears in the upper-left corner of the screen. It only shows the current HP bar and remaining HP bar count of the opponent's boss monster.

If the unit is an enemy adventurer, a *Class Mark* appears in the upper-right corner to tell what class the unit is.

When a player hovers the mouse over a Unit Display, the corresponding puck on the table will be highlighted so they can spot the puck easily. When a player clicks on the Unit Display, a small pop-up window named *Unit Detail Display* will appear to the side.

Defeated units will have a grey Unit Display, and their HP bar will disappear. 

The Unit Display should show the Ghost HP bar according to the Damage Stack. (Check the Unit Information Manager document) The Damage Stack count (how many times damage has been taken) should be displayed to the right of the unit image. 

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

When the unit skills are triggered, the skill icon will pop up shortly.

## Single-player game

In a single-player PvE game, the left side shows the player's boss monster and the minions, while the right side shows the enemy adventurers. 

On the left side, Row L1 is a span cell that shows the Boss Monster. Rows L2-L4 hold up to 6 minions' information. L5-8 are left empty.

On the right side, up to 2 Adventurer Teams, and each team consists of at most 6 adventurers. Rows R1 and R5 are reserved for team information (a simple name). Rows R2 - R4 show the team members of team1 and rows R6-R8 show the team members of team2.

## 2-player vs game

Each side shows one player's boss monster and the minions. The left side shows player A and the right side shows player B.

Rows L1 and R1 hold each side's boss monster. 

Rows L5-8 and R5-8 are left empty. Rows L6-8 and R6-8 show the 6 *Target Pucks* to defeat (TBC). 

Rows L2-4 and R2-4 show up to 6 minions of each side.

## 2-player cooperative game

The right side is the same as a single-player game.

On the left side, L1-4 are the same as a single-player game that shows Player A's boss monster and minions. L5-8 show the same information for Player B.

### Reference Mark

Reference marks identify different pucks on the cue table. A reference mark marks the same symbol on the upper-left Unit Display and the middle of the puck of a unit. Each wave uses unique marks.

The members of the first Adventurer Team are marked as A1, A2, A3, A4, A5 and A6. Meanwhile, the members of the second Adventurer Team are marked as B1, B2, B3, B4, B5 and B6. For easy identification, in general the reference number will be arranged by unit classes that ?1 is guardian class, ?2 is warrior class, ?3 is ranger class, ?4 is magician class. ?5 and ?6 are free positions. Therefore, some numbers may be missing in the middle for some small teams.

Also, the puck colour shall be different for different classes, but it is specified in another document.

(This logic affects the enemy random algorithm)

On the player side, the boss monster of player A (or the player of a single-player game) is marked as Ω and the minions are marked as ωI, ω2, ω3...The boss monster of player B is marked as Ψ and the minions are marked as ψ1, ψ2, ψ3...
