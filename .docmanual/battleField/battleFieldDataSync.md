# Battlefield data sync

In multiplayer games, the data in battlefield scene should be synchronize from the host player to other players, including table players and spectators.

In single-player games, use the same logic for standardisation: the local player acts as both the Host and Player A, while the Player B seat is empty. Even in single-player or on the Host's own machine, player inputs do not change battlefield state directly — they send action notifications to the Host logic, which updates the state and syncs it back to the display.

The Host is always the single source of truth for the battle, even if the Host is sitting as a Spectator while two other Peers play as Player A and Player B.


The following lists how to handle different data in the battlefield scene: 

- Data to sync. For these data, only the host can manage them. Other players sync them from the host. The two players, who are not necessarily the host, sync the data from the host.
  
  - Boss monster stat: HP, Energy (for Player A, and for Player B if the seat is taken)
  - Pucks positions
  - Action indicator data (the data controlling Action Tags on the Time Board)
  - Enemy and minion stats
  - Cards information
  - Timing information (including which player holds the "playing right" in Play Time)
  - Live drag aiming line in Play Time (synced so other players and spectators can see the active player aiming; whether card selection in hand is also shown to others is TBC)
  - One-shot effect start triggers for discrete events (collision hit point + staged damage popup in Puck-puck Time!, and start of a unit's action animation in Action Time). Do not sync frame-by-frame animation details; UI/status animations (timing banners, HP bar break flashes, energy rewind, focusing glow) trigger automatically on each client when the synced state changes.
  - Players’ completed action will notify the host to update

- Display based on data sync on players side
  
  - Time board display (shared Time Board; in a 2-player game, a 2-player Time Board displays both Player A's and Player B's Energy to everyone)
  - The player’s hands (Only Player A and B see their own face-up hand; Spectators see neither face-up hand, while hand counts, Casting Area, and Discard Pile are public)
  - pucks position
  - collision effects and unit action animations (played locally from one-shot start triggers)
  - Minion and enemy display
  - Active player's drag aiming line (card selection preview TBC)

- Player self-own data
  
  - uncompleted local UI state (e.g. hovering cards outside Play Time, opening deck/discard inspection windows)
  - Data that controls player visibility (camera settings and any objects that control the player's screen and what they see)
  - game config (a local settings menu for the player to change game config — not yet implemented, ignore for now)

## Modular Sync Functions

Synchronization should be split into separate sync functions by category rather than one monolithic sync call, so that the game can trigger either a full sync (`sync_all()`, calling 1–7 on battle init or mid-battle rejoin) or individual category syncs whenever only a specific part changes:

1. `sync_timing()` — current Timing (`Prepare`, `Charging`, `Play`, `Action`, `Puck-puck Time!`, `Settle`), who holds the Playing Right (`active_player`), and Wave/Stage index.
2. `sync_time_board()` — Turn progress, Player A & Player B Energy, and Action Tags.
3. `sync_boss_stats()` — HP and Health Bars for Player A's Boss Monster (and Player B's if seated).
4. `sync_units()` — Enemy Hero and Minion spawn/removal and stats (HP, Class, Focusing state, pocketed state).
5. `sync_puck_positions()` — 3D positions (and velocities) of all pucks on the Cue Table.
6. `sync_cards()` — Deck, Hand, Casting Area, and Discard Pile for Player A (and Player B if seated).
7. `sync_aiming()` — live drag aiming line + Energy cost preview during `Play Time`.
8. `sync_effect_trigger()` — one-shot start trigger for collision hit / staged damage popup / unit action animation.
9. `sync_all()` — calls 1–7 together (used on battle start and mid-battle rejoin).

## Player Action & System Messages (Peer → Host)

All players (including the Host's own local input and Single-Player) notify the Host via action messages rather than mutating battlefield state directly:

### Gameplay Actions (Seated Players: Player A and Player B only; Spectators cannot send these)

1. `action_start_wave` — in `Prepare Time`, the player finishes their preparation and presses Start Wave. When both Player A and Player B are seated, **both** players must complete their preparation (`action_start_wave`) before the Host starts the Wave; in single-player (when Player B is empty), only Player A is required.
2. `action_request_play` — in `Charging Time`, the player presses the Play button to compete for the **Playing Right** and enter `Play Time`.
3. `action_aim_update` — in `Play Time`, the `active_player` updates (or clears/cancels) their live drag aiming vector and Energy cost preview so the Host can call `sync_aiming()`.
4. `action_cue_shot` — in `Play Time`, the `active_player` releases a valid drag to launch their Boss Monster with the chosen direction and Energy cost.
5. `action_play_card` — in `Play Time`, the `active_player` plays a card from their Hand (`hand_index` + target position/unit).
6. `action_cancel_play` — in `Play Time`, the `active_player` clicks the Play/Cancel button to return to `Charging Time` without taking a shot or playing a card.

*(Host validation: Actions 1–2 require the sender to be Player A or Player B; Actions 3–6 require the sender to be the current `active_player` holding the Playing Right in `Play Time`.)*

### System Actions (Handled with the Multiplayer Scene Manager)

- **Leave Game / Leave Room**: Any Peer (including Player A, Player B, or a Spectator) can send a leave action.
- **Close Room**: The Host can send a Close Room action, which kicks all connected Peers with a Notification and returns everyone to the Menu.
