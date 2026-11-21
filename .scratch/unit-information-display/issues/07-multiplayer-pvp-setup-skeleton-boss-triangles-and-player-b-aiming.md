# 07 — Multiplayer 2-Player Versus Setup: Skeleton Boss, Snooker Triangles & Player B Drag-and-Aim

**What to build:** When a Multiplayer game starts (when `Player B` is seated), replace the single-player demo enemy adventurers with the symmetric **2-Player Versus** battlefield and **Unit Information Board** setup: move Player A's Fire Dragon Boss Monster (`Ω`) to original `Enemy2` `(-6, 3)` (`L1`), spawn Player B's **Skeleton** Boss Monster (`Ψ`, with a cartoon Skeleton Boss portrait) at original `Enemy3` `(6, -3)` (`R1`), spawn a 6-Adventurer snooker triangle for Player A around original `Enemy4` `(-6, -3)` (`L6–L8`, `V, B, R, S, F, E`) and for Player B around original `Enemy1` `(6, 3)` (`R6–R8`, `v, b, r, s, f, e` with Black 2-sided team stripes, where `F`/`f` = Warrior and `E`/`e` = Ranger), and update `CueShotManager` so Player B drags and aims from **Player B's Boss Monster puck** during Player B's `Play Time`.

**Blocked by:** 05 — Hover Puck Highlighting & Click-to-Inspect Unit Detail Display Popup

**Status:** completed

- [x] A cartoon **Skeleton Boss Monster** avatar (`avatar_boss_skeleton.png`) is generated and used for Player B's Boss Monster (`Ψ`) on the **Unit Information Board** (`R1`).
- [x] Team 2 (`v, b, r, s, f, e`) pucks use a **Black** 2-sided line stripe (in both single-player and multiplayer) instead of White.
- [x] In Multiplayer mode (`has_player_b() == true`), the single-player demo adventurers are removed; Player A's Boss Monster (`Ω`) is placed at original `Enemy2` `(-6, 1.8, 3)` (registered in `L1`), and Player B's Boss Monster (`Ψ`) is spawned at original `Enemy3` `(6, 1.8, -3)` (registered in `R1`).
- [x] In Multiplayer mode, each player has a team of 6 Adventurers (Player A in `L6–L8` with `V, B, R, S, F, E`; Player B in `R6–R8` with `v, b, r, s, f, e`, with `F`/`f` = Warrior and `E`/`e` = Ranger), arranged in a 3-row snooker triangle facing horizontally toward `X = 0` at `(-6, -3)` for Player A and `(6, 3)` for Player B:
  - Front line (apex, 1 puck): Vanguard (`V`/`v`, Knight)
  - Second line (2 pucks): Brawler (`B`/`b`, Warrior) and Ranger (`R`/`r`, Ranger on the side nearer its own Boss Monster)
  - Third line (3 pucks): Free (`F`/`f`, Warrior on outer side), Spell (`S`/`s`, Mage in middle), and Extra (`E`/`e`, Ranger on the side nearer its own Boss Monster).
- [x] During `Play Time`, `CueShotManager` binds its active Boss Monster puck to the `active_player` holding the **Playing Right** (`Player` for Player A; `PlayerB` for Player B), so Player B drags, aims, and launches Player B's Boss Monster puck (`Ψ`) rather than Player A's.
- [x] Automated tests verify the Multiplayer 2-Player Versus board layout (`L1`, `R1`, `L6–L8`, `R6–R8`), Skeleton Boss avatar, Black Team 2 stripes, 6-puck snooker triangle positions/orientation for both players, and Player B drag-and-aim control of `PlayerB`.
