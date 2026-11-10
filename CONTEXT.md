# Be The Boss

A 3D medieval strategy game where the player is a Boss Monster fighting off the incoming adventurer teams. Battles combine RPG, snooker and card-game elements; side functions include the world map, codex, deck composition and training.

## Scenes

The game has many scenes — see `.docmanual/gameScenes.md` for the full list. Scene-specific vocabulary lives in per-scene context files:

- **Menu** — the game's first page on launch (main scene); vocabulary in `GLOSSARY.md` (# Scenes)
- **Battlefield Scene** — the main scene, where Stage battles happen: [`.docs/contexts/battlefield.md`](.docs/contexts/battlefield.md)
- **Multiplayer Scene** — connection logic; roles (Host / Player A / Player B / Spectator / Peer) live in `GLOSSARY.md` (# Multiplayer)
- **World Map, Codex, Deck-editing, Training** — no context docs yet; create one under `.docs/contexts/` when its terms get resolved.

## Language

Game-wide terms that span several scenes. Battle-only vocabulary (Puck, Cue-Shot, the six Timings, …) lives in the Battlefield Scene context.

**Boss Monster**:
The monster the player controls. In battle it is a puck on the Cue Table; if it is defeated, the game is over.
_Avoid_: player, character

**Stage**:
A single battle, made of an ordered sequence of Waves. All Adventurer Team compositions for the whole Stage are rolled when the Stage begins. Selected on the World Map scene.
_Avoid_: level, round

**Deck**:
The player's 52 cards — 13 of each Card Type. Its order is hidden. Composed on the Deck-editing scene.
_Avoid_: pile

**Card Type**:
One of Environment, Monster Skill, Summoner or Minion — the four card families.

**Legendary Hero**:
A fixed, pre-designed Enemy Adventurer that appears in specific Stages — tailor-made and free to break Class rules. Stronger than random adventurers; defeated Legendary Heroes are recorded in the Codex.
_Avoid_: named adventurer, boss (that's the player's own monster)
