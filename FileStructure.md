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
│   ├── card.gd                 # Card UI component (hover/click/animations)
│   └── card.tscn               # Card scene template
│
└── canvas/
	└── canvas.gd               # CanvasLayer: hand cards, player HP, enemy HP bars
```

## Health Bar System

Enemy health bars are 2D UI widgets (ColorRect + Label) rendered on the
**CanvasLayer** via `canvas.gd`. Each frame, `Camera3D.unproject_position()`
converts the enemy's 3D world position to screen coordinates so bars always
face the camera and never clip into geometry.
