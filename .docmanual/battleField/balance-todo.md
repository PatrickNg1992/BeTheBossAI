# Battlefield Balance & Future Design TODOs

Items observed during playtesting to evaluate and tune in later balance / design passes:

## 1. Multiplayer PvP Initial Puck & Triangle Positions (First-Strike Pocket Advantage)

- **Observation**: In the current 2-player PvP demo layout (with Boss Monsters at `(-6, 3)` / `(6, -3)` and 6-Adventurer snooker triangles at `(-6, -3)` / `(6, 3)`), the player who takes the first strike has too easy an angle to knock pucks directly into a corner Pocket Area on the opening shot.
- **Todo**: Adjust the opening Boss Monster and Adventurer triangle coordinates (or table/pocket geometry) in a later balancing pass so the opening break shot is fair and does not give an overwhelming first-strike pocket advantage.

## 2. Candidate Extra Timing: "Setup Time" (Manual Placement of Pocketed Pucks)

- **Observation**: Currently, when a puck falls into a Pocket Area and survives, the system respawns it at a random empty Tile inside the middle 80% of the Cue Table.
- **Idea to Decide Later**: Introduce an extra Timing — **Setup Time** — that allows the owning player to manually choose where to place their puck(s) returning from a Pocket Area (within valid placement rules) instead of random system placement. Evaluate whether this improves tactical depth without slowing down the match pace.
