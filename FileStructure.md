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
│   └── health_bar_3d.gd        # 3D billboard health bar above enemies
│
└── cards/
	├── card.gd                 # Card UI component (hover/click/animations)
	├── card.tscn               # Card scene template
	└── cards_ui.gd             # Hand manager + player HP bar (CanvasLayer)
```
