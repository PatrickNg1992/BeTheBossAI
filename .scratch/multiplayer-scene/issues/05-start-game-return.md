# 05 — Start Game and return to the Waiting Room

**What to build:** the Host clicking "Start Game" loads the Battlefield into the Multiplayer Scene's container for all Peers, so everyone enters the same battle together (Host authoritative per ADR-0003). When the game ends, the connection stays open and every Peer returns to the Waiting Room; the Host can start another game immediately, so rematches are frictionless.

**Blocked by:** 03 — Waiting Room: seats, Game Config, start gating, leave / close.

**Status:** implemented (46/46 tests green)

**Progress notes:**
- Host `request_start_game()` (guarded: both seats + not already in battle) broadcasts `{"type":"game_start"}` → every side lazily `load()`s `res://src/demo_bettlefield.tscn` into the container and swaps to it. Peers handle `game_start`/`game_end` messages.
- Battle-end seam: new `src/battlefield/demo_battlefield.gd` on the demo battlefield root — `signal battle_finished`, emitted when the boss puck's `died` fires (the demo's only end condition; real PvP end rules come later). Manager ignores it on non-Host sides (Host-authoritative end, ADR-0003).
- `_on_battle_finished` → broadcast `game_end` → `_end_battle()`: frees the battlefield, back to Waiting Room, seats preserved, Start re-enabled → rematch works (covered by test).
- "Host's instance authoritative" note: in-field object sync remains ADR-0003/out of scope; DevTransport is raw ENetConnection and deliberately not wired into the tree's MultiplayerAPI, so `multiplayer.is_server()` is not the authority signal — the manager's `is_host` is.

- [x] "Start Game" swaps the container from Waiting Room to the Battlefield on every Peer
- [x] The same Battlefield scene is loaded on all Peers, with the Host's instance authoritative
- [x] When the battle ends, every Peer returns to the Waiting Room without reconnecting
- [x] After returning, the Host can start another game
