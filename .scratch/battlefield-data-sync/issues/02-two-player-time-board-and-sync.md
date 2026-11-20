# 02 — Two-Player Time Board Display & `sync_time_board` (UI-First Slice)

**What to build:** Add a 2-player display mode to the Time Board so that when both `Player A` and `Player B` seats are occupied, both players' Energy values are visible to all Peers (`Player A`, `Player B`, and `Spectator`s) alongside the shared Turn charge progress and Action Tags (while keeping the 1-player Time Board display when `Player B` is empty), and wire `sync_time_board()` from the Host to all Peers. Pause for human UI verification per `AGENTS.md`.

**Blocked by:** 01 — Transport Unreliable-Ordered Support, Single-Player Loopback & Battlefield Sync Scaffold

**Status:** ready-for-agent

- [x] When `Player B` is empty (such as in Single-Player), the Time Board renders in 1-player mode showing `Player A`'s Energy fill, fractional Turn charge progress, and Action Tags.
- [x] When both `Player A` and `Player B` are seated, the Time Board renders in 2-player mode so that both `Player A`'s Energy and `Player B`'s Energy are visible to both players and Spectators on the shared Time Board.
- [x] Any display labels added for the 2-player Time Board come from the multiLang localization holder.
- [x] Calling `sync_time_board()` on the Host broadcasts the Time Board state (`turn_progress`, `energy_a`, `energy_b`, `has_player_b`, `action_tags`, `unit_tag_turns`) to all Peers and updates the local Host display.
- [x] Continuous fractional Turn charge progress during `Charging Time` is sent via `sync_time_board()` using `UNRELIABLE_ORDERED`, whereas discrete changes (Turn slot completion, Energy spend/gain, Action Tag updates) are sent using `RELIABLE`.
- [x] When `sync_time_board()` lowers a player's Energy, each client automatically plays the Energy spend rewind animation locally from the state change.
- [ ] Pause and request human UI review once the 2-player Time Board visual layout is ready.
