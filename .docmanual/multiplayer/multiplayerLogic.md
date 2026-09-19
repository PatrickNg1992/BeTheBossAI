# Multiplayer Logic

The game allows single-player PvE or two-player PvP. Spectators are allowed in PvP games.

The following lists the logic of multiplayer scenes:

- From the menu, a player can choose to join a multiplayer game. Then he will enter the multiplayer scene. He will see the Role Selector scene.

- In the *Role Selector* scene, a player can select to (1) Host a game room, (2) Join a game, or (3) go back to the menu.

- If a player chooses to be the host (Host a game room), he will enter the Waiting Room. The host can select the game config. He can click the Confirm button to start waiting for the peers as a server. The screen shows any connected peers.

- If a host player clicks "Close room", the room is closed. Any connected peer is kicked. All of them return to the menu and get a message.

- The host can configure the room's player capacity. The minimum is 2, and the maximum is 6. 

- In the room, the players can choose their Role. Only 1 Player A and 1 Player B are allowed. 

- By default, the host joins as Player A and the first joiner becomes Player B. Afterwards, other players become spectators when join.

- If a player chooses to *Join a Game*, the game will show a menu that requires the player name, connection information and a join button. Then, the game tries to connect to the server he specified.

- In **Development mode**, use IP and port to connect in multiplayer games. The default port should be 8910. The host can edit the port number in the waiting room. Other peers can edit the port number before connecting.

- In **Production mode**, the connection should be made via Steam. TBC.

- If the server detects a connecting peer, it checks the peer's game version. If the version differs from its own, it rejects the peer, and both players see a reason message.

- If the server detects a peer connection, the waiting room shows the peer’s information on the host’s screen. The screen will sync to the peer. 

- The server player is responsible for managing the connection and information state of the peers.

- If an peers successfully connects to the host, he will sync the host’s waiting room information. However, he will see a “Leave” button instead of "Close Room".

- While in the waiting room, if a connected peer detects that the host is offline or disconnected, they return to the menu and receive a notification.

- While in the waiting room, if both Player A and Player B are present, the host's screen enables the “Start game” button. Otherwise, the button is disabled.

- In the waiting room, if the host clicks the “Start Game” button, all players enter the battlefield scene.

- While in the game, if the Player A or Player B is offline or disconnected, try to reconnect the game. The game freeze and enter grace period. It show a "Connecting..." message to all players in the room.

- While in the game, if a spectator is offline or disconnected, try to reconnect the game. The game will not freeze. It shows a "Connecting..." message only to the disconnected spectator.

- In the grace period, a players can click leave to end the reconnection attempt early.

- When players enter the battlefield scene, the game initialises and synchronises the data. (whether single-player or two-player game)

- During the game, the objects’ positions stay synchronised.

- During the game, the player's hands stay synchronised but are visible only to the owner (two lists). The data is managed by the host.

- During the game, all the player's actions stay synchronised using reliable mode.

- When the game ends, both players return to the waiting room.

## Single-player Game

For a single-player game, use another scene with OfflineMultiplayerPeer to load the Battlefield.

## Emoji System

The players can send emoji in the game. No text no voice.
