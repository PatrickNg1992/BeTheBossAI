# 04 — Action Tag Turn Countdowns, Defeated & Pocketed Unit Display States, and Skill Popups

**What to build:** Live status synchronization on each **Unit Display** for upcoming **Action Tag** turn countdowns, **Pocketed** (temporarily removed) unit state with return turn countdown, **Defeated** unit state (applied at `Settle Time`), and brief skill icon popups when unit skills trigger.

**Blocked by:** 01 — Unit Information Board 2×8 Grid, Reference Marks & Colour Coding, 03 — Migrate Unit HP/Stats to Unit Information, Scale Adventurer HP & Wire Linear Impulse Collision Damage

**Status:** completed

- [x] Each active unit's **Unit Display** shows the Turns-to-goal integer(s) for its upcoming **Action Tag**(s) (basic action and optional active skill) on the right/lower-right of the unit portrait, kept in sync with the Time Board.
- [x] When a unit is temporarily taken out of the table (such as falling into a **Pocket Area**), its **Unit Display** turns grey, keeps its HP bar visible, and displays its pocket return turn countdown (`5..1`) in place of its normal Action Tag turn numbers until it returns to the Cue Table.
- [x] When a unit is defeated at `Settle Time`, its **Unit Display** turns grey, displays a **red cross mark** over the unit portrait, and hides its HP bar, **Damage Stack** count badge, and all Action Tag turn numbers while remaining in its grid cell until the Wave ends.
- [x] When a unit's skill triggers, the skill icon pops up briefly on its **Unit Display**, and during `Settle Time` damage/defeat animations play on affected **Unit Displays**.
- [x] Automated tests verify Action Tag turn integer display updates, the Pocketed visual state (grey + visible HP bar + return countdown), the Defeated visual state (grey + red cross + hidden HP bar, Damage Stack badge, and turn numbers), and skill trigger popups.
