# File Structure

The code map. Read this first to locate files. **Keep it updated whenever code files are added, removed, or moved.** Supersedes `/FileStructure.md` and `/doc/FileStructure.md` (both stale; `/doc` is the human-written doc folder — do not edit it).

## Repo layout

- `CONTEXT.md` — domain glossary (game-wide terms + scene pointers). Read before gameplay work.
- `.docs/contexts/` — per-scene domain glossaries (e.g. `battlefield.md` for battle vocabulary).
- `.docs/adr/` — architecture decision records.
- `.docs/agents/` — agent workflow conventions (issue tracker, triage labels, domain docs).
- `.scratch/<feature>/spec.md` — feature specs: `battlefield-data-sync`, `card-effects`, `cue-shot-energy`, `cue-table`, `enemy-adventurers`, `menu`, `multiplayer-scene`, `stage-wave-loop`, `timing-system`, `time-board-display`.
- `doc/` — human-written design docs (the source the specs were distilled from). Do not edit.
- `tests/` — test suites (`test_*.gd` McpTestSuite files) + `_run_all.tscn`/`.gd` headless bootstrap + `fake_transport.gd` (in-memory MpTransport injected by the multiplayer tests).
- `src/` — game code, below.
- `player_movement.gd` (repo root) — legacy script, referenced nowhere; not part of the game.

## src/

```
src/
├── demo_bettlefield.tscn        # Battlefield test scene (loaded by the Single-Player Scene)
│
├── menu/
│   ├── menu.tscn, menu.gd       # Menu, the game's first page (run/main_scene)
│   ├── single_player_scene.tscn + single_player_loader.gd  # Invisible loader: LoopbackTransport + Battlefield
│   └── pending_notification.gd  # Pending-Notification autoload (one-slot localization key holder)

├── multiplayer_scene.tscn       # Multiplayer Scene (invisible): Container swaps Role Selector / Waiting Room /
│                                # Battlefield; BattleOverlay holds the battle-time Leave button (testing hatch)

├── multiplayer/
│   ├── multiplayer_manager.gd   # Manager: sub-scene swapping, connection logic, room state, role validation
│   ├── mp_transport.gd          # MpTransport seam: serve/join/leave/close_room/kick + message channel + events + poll()
│   ├── dev_transport.gd         # Dev transport: raw ENetConnection, handshake carries name+version
│   ├── loopback_transport.gd    # Local loopback MpTransport for Single-Player (is_host = true, local peer ID 1)
│   ├── role_selector.tscn/.gd   # Role Selector view: Host / Join (form + Connecting…) / Back
│   └── waiting_room.tscn/.gd    # Waiting Room view: config bar, seats, spectator list, start/close/leave
│
├── pucks/
│   ├── base_puck.gd            # Shared puck base: HP, damage, death, attack cooldown
│   ├── base_boss_monster.gd    # Boss Monster base ("player" group)
│   └── base_enemy.gd           # Enemy base: AI state machine (wander/chase/attack)
│
├── player/
│   └── dragon_player.gd        # Boss Monster controller (movement + auto-attack)
│
├── enemies/
│   ├── enemy_adventurer.gd           # Enemy Adventurer (class config + hit flash)
│   └── health_bar_3d.gd        # (unused — replaced by CanvasLayer bars)
│
├── battlefield/
│   ├── cue_table.tscn           # Hardcoded 30×20 medieval Cue Table: numbered TableBlocks (1..150),
│   │                            # CushionBlocks (1..54), hollow corner Pocket Areas, 4 CornerFlags
│   ├── battlefield.gd           # Cue Table controller: block lookup, type customization & swapping
│   ├── table_block.gd           # TableBlock (StaticBody3D): block_number, swappable BlockType & ground friction
│   ├── cushion_block.gd         # CushionBlock (StaticBody3D): cushion_number, wood/grass CushionType & rebound math
│   ├── timing_manager.gd        # TimingManager: 6-Timing state machine, Energy charging, staged damage, Pause & Fast Play
│   ├── puck_velocity_manager.gd # PuckVelocityManager: 60 Hz position updates, 20 Hz ground friction & at-rest detection
│   ├── cue_shot_manager.gd      # CueShotManager: Play-Time gated drag-to-shot, 0.5-slot Energy preview, 3D aiming arrow & launch
│   └── demo_battlefield.gd      # Demo battlefield root: wires TimingManager + Play/Fast Play/Pause UI + surfaces `battle_finished`
│
├── cards/
│   ├── base_card_info.gd       # Card data Resource: type, name, description, color
│   ├── test_deck.gd            # Test deck: 52 BaseCardInfo instances
│   ├── card.gd, card.tscn      # Card UI component (hover/select/animations)
│   └── card_manager.gd         # Deck / hand / casting area / discard logic + signals
│
├── canvas/
│   ├── canvas.gd               # HUD: boss multi-bar HP, enemy health bars, warnings
│   ├── card_canvas.gd          # Card UI: hand, selection, casting area + CD, deck/discard windows
│   └── time_board.tscn/.gd     # Time Board view: serpentine bars, energy fill, tag arrows (dumb view)
│
├── resource/
│   └── battlefield/            # Generated UI art: wood_panel, arrow_up/down, double_arrow, goal_flag, sword,
│                               # puck_puck_banner, pocket_swirl PNGs (regenerate via tests/_gen_assets.tscn)
│
└── multiLang/
    └── localization.gd         # EN/ZH localization (autoload)
```

## Subsystem notes

- **Health bars** — enemy bars are 2D widgets on the CanvasLayer; each frame `Camera3D.unproject_position()` converts the enemy's world position to screen coordinates (`canvas.gd`). The boss's multi-bar HP with break flash also lives there.
- **Cards** — `card_manager.gd` holds logic and signals (`hand_updated`, `deck_count_changed`, `discard_count_changed`, `card_played`, casting updates); `card_canvas.gd` is all card UI. Card effects are not yet implemented; demo effects (Rush / Teleport / Recover) are specced in `.scratch/card-effects/spec.md`.
- **Battlefield** — the 30×20 medieval Cue Table lives in `src/battlefield/cue_table.tscn` (instanced as `Battlefield` in `demo_bettlefield.tscn`) with hardcoded numbered `TableBlock_1..150` (`table_block.gd`), `Cushion_1..54` (`cushion_block.gd`), and `CornerFlag_1..4`.
