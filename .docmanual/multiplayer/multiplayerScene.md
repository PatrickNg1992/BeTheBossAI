# Multiplayer Scene

The Multiplayer scene controls the multiplayer game logic. A player can go to the scene from the main menu. 

It consists of 3 sub-scenes: 

- Role Selector: it allows players to choose whether they would like to be a host, peer, or spectator 
- Waiting Room: players wait for others in the waiting room. The host can select the game configuration and start the game here.
- Battlefield: When the game starts, the player will go to the battlefield.

The sub-scene will be held in a container, and it will synchronise.



In a 2-player PvP game, there are 2 teams. Each player controls 1 team to play. 



A multiplayer game shall run in Host-authoritative model.
