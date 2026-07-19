Project Name: Be The Boss

## Core Stack
* **Engine:** Godot 4.x (using GDScript)
* **Genre:** 3D [e.g., Action RPG, Strategy, Horror]
* **Target:** Mobile (Both android and IPhone)/ Steam


## Game Concept & Scope
Now we are prepaing the game demo only, which only work on one main game scene.

The game is a 3D game with a fixed camera having a medieval theme. The player controls a boss-level Monster to defeat the incoming hero teams. 


## Main Scene

The battles are carried out in a rectangular area. Enemy heroes will come from each side of the rectangle. Both the player’s monsters and the enemy heroes automatically fight each other, while players can issue simple instructions and play cards to change the game. 

The player needs to control the monster to defeat a few consequences hero teams to win a stage. Each hero team may consist of about 6 to 10 heroes, and it is called a wave. Between waves, there is a small checkpoint where the player can take a brief break and prepare.

The only basic instructions a player can issue are to choose target enemies. The monster would take the target enemy as the primary attack target. However, the monster's AI should be simple and predictable. 

A player can truly be a game-changer by playing cards from a deck. Some typical card effects include dealing a strong attack, moving monsters or heroes, summoning minions, or applying a buff or debuff.

The boss monster will have multiple health bars, just like other RPGs. Whenever a health bar was cleared, the monster became invincible for a few seconds.

The player needs to prepare a deck before a game. Before each wave (in the checkpoint), the player will gain a few hand cards from the deck. Also, the player can draw cards whenever he defeats a hero or gets a health bar cleared by the enemies.

Enemy Heroes stand like chess pieces and have different classes, as in other medieval games, with swords and magic. Typical class examples include warrior, knight, mage, and ranger. Each class will characterise the chess pieces. When a chess piece takes a strong hit, it will fly away and may collide with other objects on the battlefield, creating interesting interactions. The player can use this mechanism to deal great damage to the enemy teams. As expected, each chess piece should have its collider shape and cannot overlap with the others. To achieve this mechanism, the game requires a 3D collision engine.

As expected, the heroes will attack the monsters automatically. They will move around the battlefield according to their class-specific AI and attack within a suitable range.
