# Unit Information Board

Unit Information Board is a canvas board that shows unit information on the battlefield. 

## General

It appears on the left and right of the screen, corresponding to the two sides of the game. In different game modes, each side shows different units.

On each side, the board looks like a table with 2 columns and multiple rows. The cell is called a *Unit Display*. Each Unit Display holds a unit. 

For flexibility, the board has 8 rows and can display up to 16 Units on each side. For easy description, we number them as three letters: (L/R)(1-8)(1-2), which means {Left/right board}{Row Num}{Column Num}. The unit number ordering should follow L11, L12, L21, L22, L31, L32, L41, L42, L51, L52......Same for the right side

The unit information board works closely with the unit manager (see ./unitInformationManager.md) to show the unit information to the players. The board listens to events from the manager.

### Unit Display

Each cell shows the unit's image. Below the cell is the unit's HP bar. In the upper-left corner of the cell, a *Reference Mark* lets players match the unit and its corresponding pucks. 

The Unit Display for boss monsters spans 2 horizontal cells, which looks greater. On the right side of a boss monster's 2-cell Unit Display, its current *Frenzy Power* is displayed (each boss monster has its own Frenzy Power, supporting 2-player modes). For the local seated player's own boss monster (Player A's boss monster for Player A and Spectators; Player B's boss monster for Player B), its Unit Display omits the HP bar because that information appears in the upper-left corner of the screen. All other boss monsters on the board (the co-op partner's boss monster or the opponent's boss monster) show their current HP bar and remaining HP bar count (`x N`) inside their 2-cell Unit Display.

If the unit is an enemy adventurer, a *Class Mark* icon appears directly in the upper-right corner (without a background square) to tell what class the unit is. In the upper-left corner, the *Reference Mark* sits inside a compact square just slightly larger than the letter.

When a player hovers the mouse over a Unit Display, the corresponding puck on the table will be highlighted so they can spot the puck easily. When a player clicks on the Unit Display, a small pop-up window named *Unit Detail Display* will appear to the side.

Defeated units will have a grey Unit Display with a red cross mark over the unit portrait, and their HP bar, Damage Stack count mark, and Action Tag turn numbers will disappear. Temporarily removed units (such as pocketed units) will have a grey Unit Display, keep their HP bar visible, and show the pocket return turn countdown in place of normal Action Tag turn numbers. 

The Unit Display should show the Ghost HP bar according to the Damage Stack and Hit Level. (Check the Unit Information Manager and Damage Calculation documents) On the left of the HP bar, a small circle mark displays the Damage Stack count (how many times damage has been taken, invisible when 0). On the right/lower-right of the unit image, the Action Tag turn countdown integer(s) (or pocket return countdown) are displayed.

### Unit Detail Display

The Unit Detail Display shows more detail about a unit. It appears when the player clicks on the Unit Display. The Unit Detail Display closes when the player clicks elsewhere (or clicks the same Unit Display again).

(TBC) Information to be shown:

- Unit name

- Detail class name and the Class mark icon of the unit, if it is an adventurer

- HP bar with numeric HP / Max HP value (plus remaining health bar count if Boss Monster)

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

Each side shows one player's boss monster, minions, and 6 adventurers (target pucks to defeat). The left side shows Player A and the right side shows Player B.

Rows L1 and R1 hold each side's boss monster (`Ω` Fire Dragon for Player A; `Ψ` Skeleton for Player B).

Rows L2-4 and R2-4 show up to 6 minions of each side.

Row L5 and R5 hold each side's Adventurer Team header (or are left empty). Rows L6-8 (`L61..L82`) show Player A's 6 Adventurers (`V, B, R, S, F, E`), and Rows R6-8 (`R61..R82`) show Player B's 6 Adventurers (`v, b, r, s, f, e`).

## 2-player cooperative game

The right side is the same as a single-player game.

On the left side, L1-4 are the same as a single-player game that shows Player A's boss monster and minions. L5-8 show the same information for Player B.

### Reference Mark

Reference marks identify different pucks on the cue table. A reference mark marks the same symbol on the upper-left Unit Display and the middle of the puck of a unit. Each wave uses unique marks.

The members of the first Adventurer Team are marked with **capital letters** (`V, B, R, S, F, E`), while the members of the second Adventurer Team are marked with **small letters** (`v, b, r, s, f, e`), corresponding to positions `1` through `6` (**V**anguard, **B**rawler, **R**anger, **S**pell, **F**ree, and **E**xtra). For easy identification, in general for normal random Adventurer Team generation, the reference position will be arranged by unit classes so that position `1` (`V`/`v`) is Knight (guardian) class, position `2` (`B`/`b`) is Warrior class, position `3` (`R`/`r`) is Ranger class, and position `4` (`S`/`s`) is Mage (magician) class. Positions `5` (`F`/`f`) and `6` (`E`/`e`) are free positions for duplicate classes. Therefore, some positions may be missing in the middle for some small teams, and their corresponding Unit Display cells are left empty rather than compacted. Note: this class-to-position rule applies to normal random Adventurer Team generation; customized team compositions in specific stages are free to override it.

For intuitive class recognition on the Cue Table, both the **puck** and the **Unit Display grid border** are coloured according to the unit's **Class** (even when placed in free positions `F`/`f` or `E`/`e`):
- **Knight**: **Blue**
- **Warrior**: **Red**
- **Ranger**: **Green**
- **Mage**: **Purple**
- **Boss Monster**: **Black**

To distinguish between multiple pucks of the same Class across teams and free positions (`5` and `6`), thin **stripes** are added on the pucks:
1. **Team Stripe** (to separate Adventurer Team 1 and Adventurer Team 2):
   - **Adventurer Team 1 (`V, B, R, S, F, E`)**: No team stripe
   - **Adventurer Team 2 (`v, b, r, s, f, e`)**: Thin **Black** line stripe on **2 opposite sides** of the puck
2. **Free-Position Stripe** (to identify free positions `5` and `6`):
   - **Positions `1..4` (`V/v, B/b, R/r, S/s`)**: No free-position stripe
   - **Position `5` (`F`/`f`)**: Thin **White** 4-sided stripe like an **X**
   - **Position `6` (`E`/`e`)**: Thin **Black** 4-sided stripe like an **X**

In addition, the **Reference Mark colour** itself differs by team:
- **Adventurer Team 1 (`V, B, R, S, F, E`)**: **Deep Grey** Reference Mark colour
- **Adventurer Team 2 (`v, b, r, s, f, e`)**: **Deep Brown** Reference Mark colour

(This logic affects the enemy random algorithm)

On the player side, the boss monster of player A (or the player of a single-player game) is marked as Ω and the minions are marked as ω1, ω2, ω3... (using **Gold** for the Ω / ω Reference Mark colour). The boss monster of player B is marked as Ψ and the minions are marked as ψ1, ψ2, ψ3... (using **Silver** for the Ψ / ψ Reference Mark colour). For minion puck and grid border colours (`1..6`), use a deeper shade of the corresponding `1..6` position colours (Blue, Red, Yellow, Purple, Green, Orange; exact shades TBC).
