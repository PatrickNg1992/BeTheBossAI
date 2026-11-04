# Multiplayer game mechanism

The game supports a 2-player game. Players should connect peer-to-peer via the Godot interface. In a game, there are player A, player B and spectators. One of the players hosts the game room.

In a production game, the player should connect via Steam Multiplayer Peer. While in testing, the developer may use Godot's built-in IP connection.

## Basic design

- **Godot's High-Level Multiplayer:** Use Godot 4’s built-in nodes like `MultiplayerSpawner` and `MultiplayerSynchronizer` to sync player positions, game states, and RPCs (Remote Procedure Calls).

- **Steam Integration:** Use **GodotSteam** (a GDExtension plugin) to connect Godot with Steamworks APIs, enabling Steam friend invites, lobbies, and avatar fetching.

- **Steam Multiplayer Peer:** Swap Godot's default `ENetMultiplayerPeer` for **SteamMultiplayerPeer** (or `GodotSteamMultiplayerPeer`). This wraps Steam's P2P network layer so Godot's built-in multiplayer systems work seamlessly over Steam.

## Multiplayer logic

The host player select the stage and related setup before starting a room. After other players join the game, they enter the Battlefield scene.

When a multiplayer game is preparing to start, the game synchronises the monster, skills and deck, etc. 

Details check ./multiplayerLogin.md

### What to synchronise

Frequently sync (MultiplayerSynchronizer):

- Pucks positions

- Energy Charging

- Canvas visual effects

RPC:

- Timing Change (e.g. from Charging Timing to Action Timing)

- Player click the "Play" button: during Charging Time, players press the Play button to compete for the "playing right" — the first player whose press reaches the Host becomes the active player for that Play Time.

- Any Players' actions on cards

- Players make a cue-shot

- Unit creation or removal

- Pucks Collisions in "Puck-puck time!"

- Any Moving and attack in Action timing

- Any special effects
