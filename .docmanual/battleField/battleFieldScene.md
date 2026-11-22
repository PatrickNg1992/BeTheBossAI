# Battle Field Scene

The main game scene is the battlefield.

## Gameplay

Battles take place in a rectangular area (Cue Table). Enemy Adventurers will spawn on the table (exact spawn logic TBC). Game time is divided into Timings (see `./timingSystem` folder): during `Play Time`, the player can drag to aim and launch the Boss Monster puck as a Cue-Shot (to collide with enemies in `Puck-puck Time!`) or play cards from their hand to change the game, while Enemy Adventurers act automatically during `Action Time`.

The player needs to control the monster to defeat a few consecutive adventurer teams to win a stage. Each Adventurer team may consist of at maximum 6 adventurers, and 1 to 2 teams form a wave. Between waves, there is a Preparation Phase where the player can take a brief break and prepare.

A player can also be a game-changer by playing cards from a deck. Some typical card effects include dealing a strong attack, moving monsters or adventurers, summoning minions, or applying a buff or debuff.

The boss monster will have multiple health bars, just like other RPGs. Whenever a health bar is cleared, excess damage in that Settle Time does not spill over into the next health bar, and the player draws a card.

The player needs to prepare a deck before a game. Before each wave (in the Preparation Phase), all cards are shuffled back into the deck and the player draws 5 hand cards. Also, the player can draw cards whenever they defeat an adventurer or get a health bar cleared by the enemies.

Enemy Adventurers stand like pucks on the Cue Table and have different classes, as in other medieval games, with swords and magic. Base class examples include brawler, guard, acolyte, and scout (and their advanced classes). Each class characterises the pucks. When a puck takes a strong hit in `Puck-puck Time!`, it slides across the table and collides with other pucks, cushions, or corner Pocket Areas, creating chain-collision interactions. The player uses this mechanism to deal great damage to the enemy teams.

During `Action Time`, the adventurers move and attack the monsters automatically according to their equipped Move, Attack, Active, and Passive Skills.
