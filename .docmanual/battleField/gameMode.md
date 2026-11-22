# Game Mode

(TBC) The game may have different game modes. 

## Player vs AI

The game mode for single-player games. 

The player chooses boss monsters to fight against enemy adventurers. In each stage, there are a few waves of enemy teams. The player proceeds to the next wave by defeating all enemies in a wave. 

## Player vs Player

2 Players fight against each other (Multiplayer Versus mode).

Each player controls a Boss monster (Player A: Fire Dragon `Ω` at original `Enemy2` position `(-6, 3)`; Player B: Skeleton `Ψ` at original `Enemy3` position `(6, -3)`) and a team of 6 Adventurers (`G, B, S, A, F, E` for Player A in `L6–L8`; `g, b, s, a, f, e` for Player B in `R6–R8`, with `F`/`f` = Brawler and `E`/`e` = Scout for fairness). Each player's 6 Adventurers are arranged in a 3-row snooker triangle facing horizontally toward the center (`X = 0`), placed around original `Enemy4` `(-6, -3)` for Player A and original `Enemy1` `(6, 3)` for Player B:
- **Row 1 (Front apex, 1 puck)**: Guard (`G`/`g`, Guard)
- **Row 2 (Middle line, 2 pucks)**: Brawler (`B`/`b`, Brawler) and Scout (`S`/`s`, Scout on the side nearer its own Boss Monster)
- **Row 3 (Back line, 3 pucks)**: Free (`F`/`f`, Brawler on outer side), Acolyte (`A`/`a`, Acolyte in middle), and Extra (`E`/`e`, Scout on the side nearer its own Boss Monster)

The target of the game is to defeat all 6 of the opponent's Adventurers. This mode does not have waves. Victory is checked right after `Settle Time` damage settlement: any unit whose settled HP reaches `0` (whether from collision damage or Pocket Area 50% max-HP damage) is defeated and removed (never respawning from a pocket if lethal). Once all 6 Adventurers of a player are defeated (`is_dead == true`), the other player wins (if both teams' last Adventurers are defeated in the exact same `Settle Time`, the player who took the shot wins): the game displays `"Player A win"` / `"Player B win"` for 5 seconds and then returns all Peers to the Waiting Room.

Each player has their own energy bar, hand, and deck. The energy bar is visible to both, while the hands are hidden from the opponent. Each player drags and aims from their own Boss Monster puck during their `Play Time`.

Collision rules in Player vs Player mode:
- **Boss Monster hits Friendly Adventurer**: deals `1/4` (`0.25x`) collision damage, does not change Frenzy Power, and settles with `100%` baseline Frenzy Power (friendly source never applies Frenzy bonus).
- **Boss Monster hits Opponent Adventurer**: deals full (`1.0x`) collision damage (even if the `Puck-puck Time!` was triggered by the other player!), adjusts the hitting Boss Monster's Frenzy Power (`+10%` baseline on hit, modified by passive skills such as Guard's `SPA10001 Protect` which reduces Frenzy Power by `X * (4% + Lv * 1%)` based on non-Guard-tree teammates), and an opponent Guard (or its advanced classes) deals collision damage back to the Boss Monster.
- **Boss Monster hits Opponent Boss Monster**: deals `0` damage to both Boss Monsters, immediately reduces both Boss pucks' post-collision velocities to `20%` (`velocity * 0.2`), and grants `+3` Energy to the non-active opponent (at most once per `Puck-puck Time!` to prevent multiple triggers in chaos).
- **Adventurer hits Adventurer**: Guard (and its advanced classes) collision protection (`0` damage) applies only between Adventurers on the same team. 

## 2 Player vs AI

2 Players on the same side fight for 2 Adventurer Teams.

The game will count how much damage is dealt by each player. 

Very similar to a single-player game.
