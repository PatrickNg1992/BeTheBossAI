# Spec: Battlefield Data Sync

Status: ready-for-agent

Vocabulary per `CONTEXT.md`, `.docs/contexts/battlefield.md`, and `GLOSSARY.md` (Host, Player A / Player B, Spectator, Peer, Single-Player Scene, Multiplayer Scene, Boss Monster, Enemy Adventurer, Minion, Puck, Cue-Shot, Energy, Time Board, Turn, Action Tag, Prepare Time, Charging Time, Play Time, Playing Right, Action Time, Puck-puck Time!, Settle Time, Deck, Hand, Casting Area, Discard Pile, Rejoin Grace Period). Governing decisions: ADR-0003 (Host-authoritative sync; deck secrecy is visibility-only) and ADR-0004 (grace-period rejoin for mid-battle disconnects). Source manuals: `.docmanual/battleField/battleFieldDataSync.md`, `.docmanual/multiplayer/multiplayerGame.md`, `.docmanual/multiplayer/multiplayerLogic.md`, and `.docmanual/battleField/timingSystem/timeBoardDisplay.md` (do not edit).

## Problem Statement

Today, the Battlefield Scene runs purely as a standalone local sandbox: player inputs directly mutate the Boss Monster, cards, and UI locally; there is no distinction between authoritative state and client display; and there is no support for a second Boss Monster seat (`Player B`) or for Spectators watching a live match. When the Multiplayer Scene loads the Battlefield on Start Game, each Peer runs an isolated local copy that immediately diverges. Furthermore, Single-Player and Multiplayer currently have different initialization paths, making it easy to introduce bugs that work in single-player but break in multiplayer. Finally, when a seated player disconnects mid-battle and rejoins during the Rejoin Grace Period (ADR-0004), there is no modular sync mechanism to restore the live battle state to the rejoining Peer.

## Solution

A unified, **Host-authoritative Battlefield Data Sync** architecture used identically across Multiplayer (with `Player A`, `Player B`, and `Spectator` Peers) and Single-Player (where the local player is both the **Host** and **Player A**, and the **Player B** seat is empty):

1. **Host as Single Source of Truth**: Only the Host manages authoritative battle state (physics, timing, energy, unit stats, cards, and action resolution), regardless of whether the Host is sitting in the `Player A` seat, the `Player B` seat, or watching as a `Spectator`.
2. **Command → Host Authority → State Sync → Display Loop**: Even on the Host's own machine and in Single-Player, player inputs never mutate battlefield state directly. Completed player actions and `Play Time` aiming updates are sent to the Host; the Host validates and updates authoritative state, then syncs the updated state back to all Peers (including the Host's own display) to render.
3. **Explicit Sync Category & Delivery Mode per Data Type**: Every piece of battlefield data is mapped to one of 8 modular sync functions (`sync_timing`, `sync_time_board`, `sync_boss_stats`, `sync_units`, `sync_puck_positions`, `sync_cards`, `sync_aiming`, `sync_effect_trigger`) plus `sync_all()` for battle initialization and mid-battle rejoin, with an explicit delivery category (**Continuous / `MultiplayerSynchronizer`-style state stream** vs. **Discrete / `RPC` call**) and transfer flag (**`RELIABLE`** vs. **`UNRELIABLE_ORDERED`**).
4. **Two-Seat Support & Role-Based Display**: The Battlefield supports `Player A` and an optional `Player B` (empty in Single-Player). When both seats are occupied, a 2-player Time Board displays both players' Energy to everyone, players compete for the **Playing Right** by pressing the Play button during `Charging Time`, both players must press **Start Wave** in `Prepare Time`, and face-up Hand cards are rendered only for their owner (`Player A` or `Player B`), while Spectators see neither face-up hand.
5. **One-Shot Effect Triggers & Self-Owned Local Data**: Frame-by-frame animation details are never synced; discrete impacts and unit actions send a lightweight one-shot start trigger (`sync_effect_trigger`), while UI/status animations trigger automatically from state changes. Camera settings, local inspection windows, and uncompleted local UI hovers remain strictly local self-owned data.

## User Stories

**Host Authority & Single-Player / Multiplayer Standardisation**

1. As a Host, I want to be the single source of truth for all battlefield data whether I am sitting as Player A, Player B, or a Spectator, so that every Peer always sees the exact same battle outcome.
2. As a Single-Player user, I want my game to run through the exact same Host-authoritative command-and-sync pipeline with myself as Host and Player A and the Player B seat empty, so that single-player and multiplayer share one standardized battle architecture.
3. As a seated player (Player A or Player B), I want my local inputs to send action notifications to the Host rather than mutating my local battlefield directly, so that my screen never desyncs from the authoritative state.
4. As a developer, I want battlefield synchronization split into modular functions by data category (`sync_timing`, `sync_time_board`, `sync_boss_stats`, `sync_units`, `sync_puck_positions`, `sync_cards`, `sync_aiming`, `sync_effect_trigger`) plus a `sync_all()` composite function, so that the Host can sync individual parts when only one category changes or sync everything on battle start and mid-battle rejoin.

**Two-Player Seats, Shared Time Board & Playing Right**

5. As a player in a 2-player game, I want the Battlefield to support a second Boss Monster, Energy pool, and Deck/Hand/Casting Area/Discard Pile for Player B, so that both Player A and Player B can play on the table.
6. As a player in a 1-player game (or when the Player B seat is empty), I want the Battlefield to leave Player B's Boss Monster and card zones empty without errors, so that single-player works seamlessly with the same data model.
7. As a Peer in a 2-player game, I want a shared 2-player Time Board that displays both Player A's Energy and Player B's Energy alongside the shared Turn progress and Action Tags, so that both players and Spectators can read both players' Energy at a glance.
8. As a seated player in `Prepare Time`, I want the Wave to start only after all seated players (Player A in single-player; both Player A and Player B in a 2-player game) have pressed **Start Wave**, so that neither player is forced into combat before finishing preparation.
9. As a seated player during `Charging Time`, I want pressing the Play button to send a request for the **Playing Right** to the Host, so that the first player whose press reaches the Host becomes the `active_player` for `Play Time`.
10. As the non-active player or a Spectator during `Play Time`, I want my Play/aim/card actions rejected by the Host while the `active_player` holds the Playing Right, so that only one player acts at a time in `Play Time`.
11. As the `active_player` in `Play Time`, I want to be able to cancel `Play Time` and return the game to `Charging Time`, so that I can reconsider without spending Energy or playing a card.

**Live Aiming Preview in `Play Time`**

12. As a non-active player or Spectator during `Play Time`, I want to see the `active_player`'s live 3D drag aiming line and Time Board Energy cost preview synced as they drag, so that I can watch what they are aiming at instead of waiting blindly.
13. As the `active_player` in `Play Time`, I want releasing my drag inside the cancel deadzone or while over-dragged to clear the synced aiming line on all Peers and remain in `Play Time`, so that everyone sees the cancelled aim cleanly.

**Physics, Pucks & One-Shot Visual Effect Triggers**

14. As a Peer during `Puck-puck Time!` and `Action Time`, I want the Host to calculate all puck physics, rebounds, and scripted glides and sync puck positions to my screen, so that pucks always land in identical positions on every machine.
15. As a Peer during `Puck-puck Time!`, I want to receive a one-shot effect start trigger whenever a collision occurs (carrying impact position, involved pucks, and staged damage numbers), so that my client plays collision sparks and running staged-damage popups without syncing particle frames.
16. As a Peer during `Action Time`, I want to receive a one-shot effect start trigger when an Enemy Adventurer or Minion begins its action (move glide, auto-attack, skill, or Guard cue-shot), so that my client starts the unit's action animation in sync.
17. As a Peer, I want UI and status animations (the "Puck-puck Time!" banner flash, Energy spend rewind, Boss Monster Health Bar break flash/shake, and Adventurer Focusing lighting VFX) to trigger automatically on my client when the corresponding synced state changes, so that network traffic stays minimal.

**Cards & Role-Based Hand Visibility**

18. As a Peer, I want the Host to sync the authoritative card zones (Deck order/count, Hand, Casting Area + cooldown, Discard Pile) for Player A (and Player B if seated), so that card state is consistent and mid-battle rejoin restores exact card state.
19. As Player A, I want to see only Player A's Hand cards face-up at the bottom of my screen, so that my hand is playable while Player B's hand stays private.
20. As Player B, I want to see only Player B's Hand cards face-up at the bottom of my screen, so that my hand is playable while Player A's hand stays private.
21. As a Spectator, I want neither Player A's nor Player B's Hand cards shown face-up on my screen, so that hand secrecy is preserved (ADR-0003).
22. As any Peer (Player A, Player B, or Spectator), I want hand counts, the active Casting Area card and its cooldown, and the Discard Pile to be visible to everyone, so that public card information is readable by all participants.

**Player Self-Owned Data & System Actions**

23. As a Peer, I want my camera rail position/angle, open deck/discard inspection windows, and local card hover states outside `Play Time` to stay strictly local on my machine, so that moving my camera or inspecting the Discard Pile never disturbs other Peers' screens.
24. As any Peer (Player A, Player B, or Spectator), I want to be able to trigger the **Leave** system action during a battle, and as the Host I want to be able to trigger **Close Room**, so that session lifecycle actions remain available in accordance with the Multiplayer Scene rules.

**Battle Initialization & Rejoin Grace Period Restoration (ADR-0004)**

25. As a Peer entering the Battlefield on Start Game, I want the Host to run `sync_all()` on initialization, so that my screen starts with the exact initial Stage/Wave, Time Board, Boss Monsters, Enemy Adventurers, Puck positions, and hands.
26. As a dropped Player A or Player B rejoining during the 30-second Rejoin Grace Period (ADR-0004), I want the Host to send `sync_all()` upon my rejoin before unfreezing the battle, so that my newly instantiated Battlefield is restored to the exact live state of the match.

## Implementation Decisions

### 1. Unified Architecture & Transport Seam (`MpTransport`)

- **One code path for Single-Player and Multiplayer**:
  - The Battlefield communicates through the `MpTransport` seam (extended with unreliable-ordered support for high-frequency state streams where appropriate, while remaining 100% compatible with `FakeTransport` in tests).
  - In the **Single-Player Scene**, `OfflineMultiplayerPeer` is replaced by a local loopback `MpTransport` where `is_host = true`, the local peer ID is `1` (`HOST_ID`), `Player A` is assigned to peer `1`, and the `Player B` seat is empty.
  - In the **Multiplayer Scene**, the manager passes its active `MpTransport`, local peer ID, `is_host` flag, and the room's seat assignments (`Player A` peer ID, `Player B` peer ID or empty, and `Spectator` peer IDs) to the Battlefield instance when starting or rejoining a battle.
- **Host Authority Independent of Seat**:
  - The Host (`HOST_ID = 1`) always runs the authoritative battle simulation (Timing state machine, physics in `Puck-puck Time!`, AI decisions in `Settle Time` / `Action Time`, damage staging and settlement, and card state transitions), regardless of whether the Host is seated as `Player A`, `Player B`, or `Spectator`.
  - Non-Host Peers disable autonomous physics, AI, and clock ticking; their Battlefield nodes act as views driven by the Host's sync messages and send player action requests to the Host.
  - Even when the Host is playing as `Player A` or `Player B` (including in Single-Player), local player inputs submit action messages to the Host handler, which mutates authoritative state and invokes the modular sync functions to update the local display.

### 2.Sync Category, Mechanism (`MultiplayerSynchronizer` vs. `RPC`), and Transfer Flags

Every synced data type and player/system message is assigned a specific sync mechanism and transfer flag (`RELIABLE` vs. `UNRELIABLE_ORDERED`, corresponding to `ENetPacketPeer.FLAG_RELIABLE` vs. `ENetPacketPeer.FLAG_UNSEQUENCED` / unreliable-ordered channel in ENet and `MultiplayerSynchronizer` continuous replication vs. `@rpc` discrete calls in Godot's multiplayer vocabulary):

| Function / Message | Direction | Category / Mechanism | Transfer Flag | Payload & Trigger Rules |
|---|---|---|---|---|
| `sync_puck_positions()` | Host → All Peers | **Continuous State Sync (`MultiplayerSynchronizer`-style)** | **`UNRELIABLE_ORDERED`** during continuous motion (`Puck-puck Time!` physics & `Action Time` glides); **`RELIABLE`** on snap/rest (`Settle Time`, `Prepare Time`, `sync_all()`) | Dictionary/array of `{ puck_id, position: Vector3, velocity: Vector3 }` for all pucks on the Cue Table. |
| `sync_time_board()` | Host → All Peers | **Continuous + Event Sync (`MultiplayerSynchronizer` for Turn charge progress; `RPC` on discrete changes)** | **`UNRELIABLE_ORDERED`** for smooth fractional Turn charge progress in `Charging Time`; **`RELIABLE`** on Turn completion, Energy spend/gain, Action Tag changes, and `sync_all()` | `{ turn_progress: float, energy_a: float, energy_b: float, has_player_b: bool, action_tags: Array, unit_tag_turns: Dictionary }`. |
| `sync_aiming()` | Host → All Peers | **Continuous State Sync in `Play Time` (`MultiplayerSynchronizer`-style)** | **`UNRELIABLE_ORDERED`** while dragging; **`RELIABLE`** when cleared/cancelled or on `sync_all()` | `{ active: bool, player_seat: "a" \| "b", aim_origin: Vector3, aim_direction: Vector3, energy_cost: float, over_dragged: bool }` (card selection preview in hand is parked as TBC). |
| `sync_timing()` | Host → All Peers | **Discrete State Sync (`RPC`)** | **`RELIABLE`** (`call_local`) | `{ timing: int/String, active_player: "" \| "a" \| "b", stage_index: int, wave_index: int, ready_players: Array }`. Fired on every Timing transition, Wave change, or `Prepare Time` ready-state update. |
| `sync_boss_stats()` | Host → All Peers | **Discrete State Sync (`RPC`)** | **`RELIABLE`** (`call_local`) | Per-seat Boss Monster state for `Player A` and (if seated) `Player B`: `{ seat, puck_id, current_hp, bar_max_hp, bars_remaining, max_bars, is_invincible, is_dead }`. Fired on damage applied in `Settle Time`, heal card effects, bar break, or `sync_all()`. |
| `sync_units()` | Host → All Peers | **Discrete State Sync (`RPC`)** | **`RELIABLE`** (`call_local`) | Full list or delta of Enemy Adventurers and Minions: `{ puck_id, unit_kind: "enemy_adventurer" \| "minion", owner_seat, adventurer_class, current_hp, max_hp, is_focusing, is_pocketed, pocket_return_turns, is_dead, position }`. Fired on Wave spawn, summon, defeat, pocket fall/return, Focusing change, or `sync_all()`. |
| `sync_cards()` | Host → All Peers | **Discrete State Sync (`RPC`)** | **`RELIABLE`** (`call_local`) | Authoritative card state for `Player A` and (if seated) `Player B`: `{ deck_card_ids: Array, hand_card_ids: Array, casting_card_id: Variant, casting_cd_remaining: float, discard_card_ids: Array }`. Synced to all Peers per ADR-0003; UI filters visibility by local role. |
| `sync_effect_trigger()` | Host → All Peers | **Discrete One-Shot Event (`RPC`)** | **`RELIABLE`** (`call_local`) | One-shot start triggers only: (1) **Collision hit** in `Puck-puck Time!`: `{ kind: "collision", impact_pos: Vector3, puck_ids: Array, impulse: float, staged_damage_by_puck: Dictionary }`; (2) **Unit action start** in `Action Time`: `{ kind: "unit_action", actor_puck_id: int, action_type: "move" \| "attack" \| "skill" \| "cue_shot", target_pos: Vector3, target_puck_id: int }`. |
| `sync_all()` | Host → All Peers (or single rejoining Peer) | **Composite Full Snapshot (`RPC`)** | **`RELIABLE`** (`call_local`) | Invokes `sync_timing()`, `sync_time_board()`, `sync_boss_stats()`, `sync_units()`, `sync_puck_positions()` (reliable), `sync_cards()`, and `sync_aiming()` (reliable). Used when the battle starts and when a dropped player rejoins during the Rejoin Grace Period (ADR-0004). |

### 3. Peer → Host Action & System Messages (`RPC`, Always `RELIABLE` except live aim drag)

All player actions flow from the acting Peer to the Host:

| Action Message | Sender Allowed | Valid Timing | Transfer Flag | Host Validation & Effect |
|---|---|---|---|---|
| `action_start_wave` | `Player A` or `Player B` | `Prepare Time` | **`RELIABLE`** | Marks the sender's seat as ready for the coming Wave. When all occupied seats (`Player A` in 1P; both `Player A` and `Player B` in 2P) have sent `action_start_wave`, the Host transitions from `Prepare Time` to `Charging Time` and calls `sync_timing()` + `sync_time_board()`. |
| `action_request_play` | `Player A` or `Player B` | `Charging Time` | **`RELIABLE`** | Competes for the **Playing Right**. If the game is still in `Charging Time`, the sender has not already used their once-per-slot Play entry on the current Turn, and all pucks are at rest, the Host transitions to `Play Time` with `active_player = sender_seat` and calls `sync_timing()` + `sync_time_board()`. |
| `action_aim_update` | Current `active_player` only | `Play Time` | **`UNRELIABLE_ORDERED`** while dragging; **`RELIABLE`** when drag cancels/clears | Updates the Host's live aiming state (`aim_direction`, `energy_cost`, `over_dragged`, or `active = false` on cancel) and triggers `sync_aiming()` so other Peers see the live 3D aiming line and Energy preview. |
| `action_cue_shot` | Current `active_player` only | `Play Time` | **`RELIABLE`** | Validates that `energy_cost` is in `[1.0, 9.0]` (in `0.5` steps) and `<= owned_energy` for `active_player`. Deducts Energy, clears aiming (`sync_aiming()`), applies Impulse to `active_player`'s Boss Monster, transitions to `Puck-puck Time!` (`sync_timing()`, `sync_time_board()`), and begins physics simulation + `sync_puck_positions()`. |
| `action_play_card` | Current `active_player` only | `Play Time` | **`RELIABLE`** | Validates `hand_index`, ensures `active_player`'s Casting Area is empty, moves the card from Hand to Casting Area, applies the card effect, calls `sync_cards()`, and transitions Timing per the card's effect (`sync_timing()`). |
| `action_cancel_play` | Current `active_player` only | `Play Time` | **`RELIABLE`** | Clears any active aiming preview (`sync_aiming()`) and transitions from `Play Time` back to `Charging Time` (`sync_timing()`, `sync_time_board()`) preserving the fractional Turn progress. |
| **System: Leave / Close Room** | `Leave`: Any Peer (`Player A`, `Player B`, `Spectator`); `Close Room`: `Host` only | Any | **`RELIABLE`** | Handled via the Multiplayer Scene manager's existing transport messages (`leave()`, `end_battle_request`, `grace_leave`, `close_room()`). Spectators can leave the room back to the Menu at any time without freezing the battle; Host closing the room kicks all Peers to the Menu with a Notification. |

### 4. Client Display & Visibility Rules

- **Time Board Display**:
  - In a 1-player battle (`Player B` seat empty), the standard Time Board is shown with `Player A`'s Energy fill and drag preview.
  - In a 2-player battle (both `Player A` and `Player B` seated), the 2-player Time Board mode is active on all Peers, displaying both `Player A`'s Energy and `Player B`'s Energy alongside the shared Turn progress and Action Tags.
- **Hands & Card Zones (`ADR-0003`)**:
  - If the local Peer's role is `Player A`, the card HUD displays `Player A`'s Hand face-up.
  - If the local Peer's role is `Player B`, the card HUD displays `Player B`'s Hand face-up.
  - If the local Peer's role is `Spectator`, no face-up Hand cards are rendered.
  - Hand card counts, the Casting Area card + cooldown, and the Discard Pile remain visible to all Peers.
- **State-Driven Local Animations vs. One-Shot Triggers**:
  - Clients do **not** receive frame-by-frame animation packets.
  - When `sync_effect_trigger()` arrives with `kind == "collision"`, the client spawns the collision visual effect at `impact_pos` and updates the running staged-damage popup on the affected pucks.
  - When `sync_effect_trigger()` arrives with `kind == "unit_action"`, the client starts the unit's attack/move/skill animation.
  - When `sync_timing()`, `sync_time_board()`, `sync_boss_stats()`, or `sync_units()` arrives, the client compares previous vs. new state and plays the corresponding UI/status transitions locally (e.g. "Puck-puck Time!" banner on entering `Puck-puck Time!`, Energy bar rewind tween on Energy decrease, Boss Monster Health Bar break flash/shake on bar count decrease, Adventurer Focusing glow when `is_focusing` becomes true).
- **Strictly Local Self-Owned Data (Never Synced)**:
  - Camera rail side/angle selection (left/right camera rotation buttons).
  - Local UI inspection popups (opening/closing the Discard Pile or debug Deck window) and hovering cards in hand outside `Play Time`.
  - Local client game config (language selection `EN`/`ZH`, audio preferences; the dedicated in-game config menu is deferred).

### 5. Mid-Battle Rejoin Restoration (`ADR-0004` Integration)

- When a dropped `Player A` or `Player B` rejoins during the 30-second Rejoin Grace Period, the Multiplayer Scene manager instantiates their Battlefield in the frozen state and notifies the Host's Battlefield sync controller to send `sync_all()` to the rejoining Peer (or broadcast `sync_all()`) before `_unfreeze_battle()` resumes processing on all Peers.

## Testing Decisions

- **What makes a good test**: Drive only the public seams (player action methods, modular `sync_*` methods, and `FakeTransport` lifecycle events) and assert observable state and UI outputs on each Peer's Battlefield instance — never internal private variables, tween node internals, or socket bytes.
- **Two seams (reusing existing project seams)**:
  1. **The `MpTransport` Seam**: Inject `FakeTransport` for multi-peer tests (Host, `Player A`, `Player B`, `Spectator` — including the case where the Host is a `Spectator` and two non-Host Peers are `Player A` and `Player B`) and the local loopback `MpTransport` for Single-Player tests.
  2. **The Battlefield Public Sync & Action Boundary**:
     - Drive the 6 gameplay actions (`action_start_wave`, `action_request_play`, `action_aim_update`, `action_cue_shot`, `action_play_card`, `action_cancel_play`) and the modular sync functions (`sync_timing`, `sync_time_board`, `sync_boss_stats`, `sync_units`, `sync_puck_positions`, `sync_cards`, `sync_aiming`, `sync_effect_trigger`, `sync_all`).
- **Modules and scenarios to test**:
  - **Single-Player standardisation**: Local player acts as Host + `Player A` with `Player B` empty; actions go through the command → Host → sync → display loop.
  - **Host as Spectator**: Host is a `Spectator` while Peer 2 is `Player A` and Peer 3 is `Player B`; Host still runs authoritative state and syncs to all Peers.
  - **`Prepare Time` readiness**: In 1-player mode, `Player A` pressing Start Wave starts `Charging Time` immediately; in 2-player mode, both `Player A` and `Player B` must send `action_start_wave` before `Charging Time` starts, and Spectators cannot send it.
  - **Competing for the Playing Right**: In `Charging Time`, when both `Player A` and `Player B` send `action_request_play`, the first to reach the Host enters `Play Time` as `active_player`, and the second request is ignored; non-active players and Spectators cannot send `Play Time` actions (`action_aim_update`, `action_cue_shot`, `action_play_card`, `action_cancel_play`).
  - **Live Aiming Sync**: `active_player` sending `action_aim_update` updates the aiming line and Energy preview on the opponent's and Spectators' screens via `sync_aiming()`.
  - **Modular Category Syncs**: Each of the 8 `sync_*` functions independently updates only its corresponding domain state and display on Peers, and `sync_effect_trigger()` fires discrete collision/action visual triggers on Peers.
  - **Role-Based Hand Visibility (`ADR-0003`)**: `sync_cards()` replicates both players' card zones to all Peers, while the UI displays face-up Hand cards only to their owner (`Player A` sees Hand A, `Player B` sees Hand B, `Spectator` sees neither face-up hand; everyone sees hand counts, Casting Area, and Discard Pile).
  - **Mid-Battle Rejoin (`ADR-0004`)**: When `Player B` drops mid-battle and rejoins during the grace period, `sync_all()` restores the live Timing, Time Board, Boss Monster HP/bars, Enemy Adventurers, puck positions, and Hands on the rejoined Peer's newly instantiated Battlefield.
  - **Self-Owned Local Data**: Changing camera angle or opening the Discard Pile window on one Peer does not affect any other Peer.
- **Prior art**: `tests/test_multiplayer_manager.gd` (multi-instance Host + Peers driven deterministically over `FakeTransport`), `tests/test_single_player.gd` (Single-Player loader verification), and `tests/test_time_board_view.gd` (asserting Time Board view state from model syncs).

## Out of Scope

- **Co-op vs. Versus win/loss rules for 2-player games** — undecided in the game design; this spec covers the 2-player seat/monster/energy/card sync infrastructure while leaving specific co-op vs. PvP victory rules to a future gameplay spec.
- **Card selection in-hand preview during `Play Time`** — marked TBC during grilling; only the 3D drag aiming line and Time Board Energy cost preview are synced in `Play Time` for now.
- **Final visual layout of the 2-player Time Board and Spectator HUD** — functional dual-energy display and Spectator hand hiding are included; artistic HUD layout is tuned separately with UI verification.
- **In-game local config menu** — does not exist yet and is ignored for now.
- **Steam transport implementation** — slots into the `MpTransport` seam later.

## Further Notes

- All display text added for 2-player Energy labels or `Playing Right` indicators must live in `src/multiLang/localization.gd` (`AGENTS.md` rule).
- Per `AGENTS.md`, any UI change (such as the 2-player Time Board Energy display) should be done early and paused for human visual verification.
