# 05 — Start Game and return to the Waiting Room

**What to build:** the Host clicking "Start Game" loads the Battlefield into the Multiplayer Scene's container for all Peers, so everyone enters the same battle together (Host authoritative per ADR-0003). When the game ends, the connection stays open and every Peer returns to the Waiting Room; the Host can start another game immediately, so rematches are frictionless.

**Blocked by:** 03 — Waiting Room: seats, Game Config, start gating, leave / close.

**Status:** ready-for-agent

- [ ] "Start Game" swaps the container from Waiting Room to the Battlefield on every Peer
- [ ] The same Battlefield scene is loaded on all Peers, with the Host's instance authoritative
- [ ] When the battle ends, every Peer returns to the Waiting Room without reconnecting
- [ ] After returning, the Host can start another game
