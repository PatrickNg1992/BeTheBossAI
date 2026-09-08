# Common Design

No official servers shall be hosted.

## Progress save

As the game will target the Steam platform, the player's progress will be saved to Steam Cloud and the player's local machine.

## Multiplayer

The game shall support a two-player game.

Both players must purchase the game. One of them selects to host a server, and the other one selects to connect to the host.

The connection shall be made via Steam.

## Testing Mode

During local development and testing, disable Steam Cloud storage and rely only on the local machine.

The Steam connection should be swapped to use the default Godot multiplayer socket as well.



A GlobalNetworkManager.md shall be created and "Autoload" in the game scenes. It is configurable to use the default Godot connection or the Steam connection.


