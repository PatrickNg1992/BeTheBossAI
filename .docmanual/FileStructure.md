# src/ Directory Structure

```
src/
├── demo_battlefield.tscn       # Demo battlefield
├── multiplayer_scene.tscn      # Main test scene
│
├── player/
│   └── dragon_player.gd        # Player controller (WASD + auto-attack)
│
├── enemies/
│   ├── enemy_adventurer.gd           # Enemy Adventurer (class config + hit flash)
│   └── health_bar_3d.gd        # (unused — replaced by CanvasLayer bars)
│
├── pucks/
│   ├── base_puck.gd            # Shared puck: HP, damage, death, attack cooldown
│   ├── base_boss_monster.gd    # Boss base: "player" group membership
│   └── base_enemy.gd           # Enemy base: AI state machine (wander/chase/attack)
│
├── cards/
│   ├── base_card_info.gd       # Card data class: type, name, description, color
│   ├── test_deck.gd            # Test deck: 52 BaseCardInfo instances
│   ├── card.gd                 # Card UI component (hover/select/animations)
│   ├── card.tscn               # Card scene template
│   └── card_manager.gd         # Deck, hand, discard pile logic
│
├── battlefield/
│   └── battlefield.gd           # Procedural cue table: tiles, cushions, pockets
│
├── multiLang/
│   └── localization.gd          # Multi-language support (EN/ZH autoload)
│
├── multiplayer/
│   └── multiplayer_manager.gd  # the manager script for multiplayer scene
│   └── network_autoload.gd      # the singleton script to handle multiplayer as autoload
│   └── role_selector.gd        # the manager script for role_selector scene
│   └── role_selector.tscn      # multiplayer sub-scene: role selector
|
└── canvas/
    └── canvas.gd               # CanvasLayer: hand display, player HP, enemy HP bars, deck/discard UI
```

## Health Bar System

Enemy health bars are 2D UI widgets (ColorRect + Label) rendered on the
**CanvasLayer** via `canvas.gd`. Each frame, `Camera3D.unproject_position()`
converts the enemy's 3D world position to screen coordinates so bars always
face the camera and never clip into geometry.

## Card System

`card_manager.gd` handles all card logic:

- **Deck**: 52 cards (4 types x 13 each: Environment, Monster Skill, Summoner, Minion)
- **Hand**: max 10 cards, starts with 5 drawn at game init
- **Discard pile**: used cards go here; reshuffled into deck when empty and draw needed
- **Signals**: `hand_updated`, `deck_count_changed`, `discard_count_changed`, `card_played`

`canvas.gd` handles all card UI:

- Hand cards rendered in HBoxContainer at screen bottom
- Single-click selects a card (shifts up, white border)
- Double-click plays the card (discards it)
- Deck and discard counts shown at bottom-right
- **Card effects are not yet implemented**
