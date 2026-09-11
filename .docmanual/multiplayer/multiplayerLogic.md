# Multiplayer Logic

The game allows single-player PvE or two-player PvP. Spectators are allowed in PvP games.

The following lists the logic of multiplayer scenes:

- From the menu, a player can choose to join a multiplayer game. Then he will enter the multiplayer scene. He will see the Role Selector.

- In the *Role Selector* scene, a player can select to (1) host a game as a server, (2) join as the opponent, or (3) join as a spectator. He can choose to go back to the menu.

-  If a player chooses to be the host, he will enter the Waiting Room. The host can select the game config. He can click the Confirm button to start waiting for the peers as a server. The screen shows any connected peers.

- If a host player click "Close room", the room is closed. Any connected peer is kicked. All of them return to the menu and get a messages.

- The host can configure the room to accept or reject spectators.

- If a player chooses to connect to a host as an opponent or a spectator, the game tries to connect to the server he specified.

- In **Development mode**, use IP and port to connect in multiplayer games. The default port should be 8910. The host can edit the port number in the waiting room. Other peers can edit the port number before connecting.

- In **Production mode**, the connection should be made via Steam.

- If the server detects a connecting peer, it checks the peer's game version. If the version differs from its own, it rejects the peer, and both players see a reason message.

- If the server detects a connected opponent, the waiting room shows the peer’s information on the host’s screen. The screen will sync to the peer. The “Start game” button is enabled.

- If an opponent successfully connects to the host, he will sync the host’s waiting room information. However, he will see a “Leave” button instead of “Start game”.

- If a spectator successfully connects to the host, he will always sync the host's screen (excluding some sensitive information TBD). Additionally, he will see a leave button.

- While in the waiting room, if the connected peer is disconnected. The host’s screen detects it and disables the “Start game” button.

- While in the waiting room, if a connected peer detects that the host is offline or disconnected, they return to the menu and receive a notification.

- In the waiting room, given both players are present, when the host clicks the “Start Game” button, the players and spectators enter the battlefield scene.

- While in the game, if the connected players detect that the host or the opponent is offline or disconnected, try to reconnect the game. The game freeze and enter grace period. It show a "Connecting..." message 

- In the grace period, a players can click leave to end the reconnection attempt early.

- When players enter the battlefield scene, the game initialises and synchronises the data. (whether single-player or two-player game)

- During the game, the objects’ positions stay synchronised.

- During the game, the player's hands stay synchronised but are visible only to the owner (two lists).

- During the game, all the player's actions stay synchronised using reliable mode.

- When the game ends, both players return to the waiting room.



## Single-player Game

For a single-player game, use another scene with OfflineMultiplayerPeer to load the Battlefield.



## Emoji System

The players can send emoji in the game. No text no voice.


