# src/ Directory Structure

```
src/
├── node_3d.tscn                # Main game scene
│
├── player/
│   ├── character_base.gd       # Base class: HP, damage, death
│   └── dragon_player.gd        # Player controller (WASD + auto-attack)
│
├── enemies/
│   ├── enemy_hero.gd           # Enemy AI (wander/chase/attack, fights all)
│   └── health_bar_3d.gd        # (unused — replaced by CanvasLayer bars)
│
├── cards/
│   ├── card.gd                 # Card UI component (hover/select/animations)
│   ├── card.tscn               # Card scene template
│   └── card_manager.gd         # Deck, hand, discard pile logic (52 cards)
│
├── battlefield/
│   └── battlefield.gd           # Procedural cue table: tiles, cushions, pockets
│
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
