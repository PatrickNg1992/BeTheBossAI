# 10 — Full Snapshot (`sync_all`) on Battle Start & Mid-Battle Rejoin Grace Period (`ADR-0004`)

**What to build:** Wire `sync_all()` (`RELIABLE`) to invoke all 7 state sync functions (`sync_timing`, `sync_time_board`, `sync_boss_stats`, `sync_units`, `sync_puck_positions`, `sync_cards`, `sync_aiming`) on battle initialization and whenever a dropped `Player A` or `Player B` rejoins during the 30-second Rejoin Grace Period (`ADR-0004`), restoring the full live battle state on the rejoining Peer's freshly mounted Battlefield before unfreezing the battle.

**Blocked by:** 05 — Authoritative Card Sync & Role-Based Hand Visibility (`sync_cards` & `action_play_card`), 08 — Host Physics Authority & Puck Positions Sync (`sync_puck_positions`), 09 — One-Shot Visual Effect Start Triggers (`sync_effect_trigger`)

**Status:** ready-for-agent

- [ ] Calling `sync_all()` on the Host invokes `sync_timing()`, `sync_time_board()`, `sync_boss_stats()`, `sync_units()`, `sync_puck_positions()` (`RELIABLE`), `sync_cards()`, and `sync_aiming()` (`RELIABLE`).
- [ ] When a battle starts (in both Single-Player and Multiplayer), the Host automatically runs `sync_all()` so every Peer's Battlefield initializes with identical Stage/Wave, Timing, Time Board, Boss Monsters, Enemy Heroes, puck positions, and role-filtered Hands.
- [ ] When `Player A` or `Player B` disconnects mid-battle (triggering the 30-second Rejoin Grace Period per ADR-0004) and rejoins via the Role Selector before the grace period expires, the Host runs `sync_all()` to restore the complete live battle state onto the rejoining Peer's newly instantiated Battlefield before unfreezing the battle on all Peers.
- [ ] After rejoining and unfreezing, the rejoined player's Battlefield reflects the exact mid-battle Timing, Time Board Energy/Action Tags, Boss Monster HP/Health Bars, Enemy Hero stats/positions, and their own face-up Hand cards, and the player can continue submitting actions normally.
