# File Structure

The code map. Read this first to locate files. **Keep it updated whenever code files are added, removed, or moved.** Supersedes `/FileStructure.md` and `/doc/FileStructure.md` (both stale; `/doc` is the human-written doc folder — do not edit it).

## Repo layout

- `CONTEXT.md` — domain glossary (game-wide terms + scene pointers). Read before gameplay work.
- `.docs/contexts/` — per-scene domain glossaries (e.g. `battlefield.md` for battle vocabulary).
- `.docs/adr/` — architecture decision records.
- `.docs/agents/` — agent workflow conventions (issue tracker, triage labels, domain docs).
- `.scratch/<feature>/spec.md` — feature specs: `card-effects`, `cue-shot-energy`, `cue-table`, `enemy-heroes`, `menu`, `multiplayer-scene`, `stage-wave-loop`, `timing-system`, `time-board-display`.
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
│   ├── single_player_scene.tscn + single_player_loader.gd  # Invisible loader: OfflineMultiplayerPeer + Battlefield
│   └── pending_notification.gd  # Pending-Notification autoload (one-slot localization key holder)
│
├── multiplayer_scene.tscn       # Multiplayer Scene (invisible): Container swaps Role Selector / Waiting Room
│
├── multiplayer/
│   ├── multiplayer_manager.gd   # Manager: sub-scene swapping, connection logic, room state, role validation
│   ├── mp_transport.gd          # MpTransport seam: serve/join/leave/close_room + message channel + events
│   ├── dev_transport.gd         # Dev ENet transport — stub, real impl is ticket 07
│   ├── role_selector.tscn/.gd   # Role Selector view: Host / Join (form + Connecting…) / Back
│   ├── waiting_room.tscn/.gd    # Waiting Room view: config bar, seats, spectator list, start/close/leave
│   └── network_autoload.gd      # Legacy NetworkManager autoload — to be replaced by ticket 07
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
│   ├── enemy_hero.gd           # Enemy Hero (class config + hit flash)
│   └── health_bar_3d.gd        # (unused — replaced by CanvasLayer bars)
│
├── battlefield/
│   └── battlefield.gd          # Procedural Cue Table: tiles, cushions, pockets.
│                               # Still 20×20 square — 30×20 pending, see .scratch/cue-table/spec.md
│
├── cards/
│   ├── base_card_info.gd       # Card data Resource: type, name, description, color
│   ├── test_deck.gd            # Test deck: 52 BaseCardInfo instances
│   ├── card.gd, card.tscn      # Card UI component (hover/select/animations)
│   └── card_manager.gd         # Deck / hand / casting area / discard logic + signals
│
├── canvas/
│   ├── canvas.gd               # HUD: boss multi-bar HP, enemy health bars, warnings
│   └── card_canvas.gd          # Card UI: hand, selection, casting area + CD, deck/discard windows
│
└── multiLang/
    └── localization.gd         # EN/ZH localization (autoload)
```

## Subsystem notes

- **Health bars** — enemy bars are 2D widgets on the CanvasLayer; each frame `Camera3D.unproject_position()` converts the enemy's world position to screen coordinates (`canvas.gd`). The boss's multi-bar HP with break flash also lives there.
- **Cards** — `card_manager.gd` holds logic and signals (`hand_updated`, `deck_count_changed`, `discard_count_changed`, `card_played`, casting updates); `card_canvas.gd` is all card UI. Card effects are not yet implemented; demo effects (Rush / Teleport / Recover) are specced in `.scratch/card-effects/spec.md`.
- **Battlefield** — the table is generated at runtime from constants in `battlefield.gd`; the table base mesh/shape is in `demo_bettlefield.tscn`.
