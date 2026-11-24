# Spec: Cue Table (Battlefield)

The physical arena. Vocabulary per `CONTEXT.md` (Cue Table, Tile, Cushion, Pocket Area, Puck).

## Implementation status

Implemented in `src/battlefield/cue_table.tscn` (instanced as `Battlefield` in `src/demo_bettlefield.tscn`) with `src/battlefield/battlefield.gd`, `src/battlefield/table_block.gd`, and `src/battlefield/cushion_block.gd`; verified by `tests/test_cue_table.gd`:

- **Hardcoded 30×20 scene**: Replaced runtime loop generation with hardcoded scene nodes in `cue_table.tscn`:
  - `TableBlocks/TableBlock_1` .. `TableBlock_150` (`TableBlock`, `block_number = 1..150`, 15×10 grid of `2×3×2` blocks).
  - `Cushions/Cushion_1` .. `Cushion_54` (`CushionBlock`, `cushion_number = 1..54`: 15 top, 15 bottom, 10 left, 10 right, 4 corner posts).
  - `Decorations/CornerFlag_1` .. `CornerFlag_4` on the four corners.
- **Swappable block & cushion types**:
  - `TableBlock.BlockType`: `GRASS_DARK`, `GRASS_LIGHT`, `POCKET`, `STONE`, `MUD`, `ICE` (each configuring visuals, floor collider state, and `friction_factor`).
  - `CushionBlock.CushionType`: `WOOD_DARK`, `WOOD_LIGHT`, `GRASS_DARK`, `GRASS_LIGHT`, `CORNER_DARK`, `CORNER_LIGHT`.
  - `Battlefield` helpers: `get_table_block`, `set_table_block_type`, `swap_table_block_types`, `get_cushion_block`, `set_cushion_block_type`, `swap_cushion_block_types`, `get_table_block_at_grid`, `get_table_block_at_world`, `is_pocket_at_world`.
- **Collision bodies & cushion rebound math**:
  - Non-pocket `TableBlock`s carry active `StaticBody3D` + `BoxShape3D(2, 3, 2)` colliders (layer 1) supporting pucks at `Y = 1.5`.
  - `POCKET` `TableBlock`s (corners `1, 15, 136, 150` by default, or any block swapped to `POCKET`) disable their floor `CollisionShape3D` so pucks fall into the hollow pocket area (`BasePuck.apply_table_physics`).
  - `CushionBlock`s carry active `StaticBody3D` + `BoxShape3D(2, 5, 2)` colliders (layers 1 & 2) preventing pucks from leaving the table and provide `compute_rebound_velocity()` implementing `v1f = (1 - fc)(v1 - (v1·n)n) - e(v1·n)n`.
- **Medieval style**:
  - Generated textures in `src/resource/battlefield/`: `grass_dark.png`, `grass_light.png`, `wood_dark.png`, `wood_light.png`.
  - Alternating lush grass tiles, oak-and-iron wooden cushions with grassy inner bumper strips, stone-rimmed corner pits, and 4 corner flag posts with battlements, gold finials, and crimson/blue heraldic banners.

## Geometry

- Inner floor: **30 × 20** (X × Z), table height 3. Rectangular, like a real snooker table.
- Tiles (`TableBlock_1..150`): 2×2 each (height 3) → a 15×10 grid. Alternating dark/light medieval grass; corners `1, 15, 136, 150` default to `POCKET`. Individual blocks can be customized or swapped by number.
- Cushions (`Cushion_1..54`): on all four sides, width 2, height above the table 2 (total block height 5 from table base `-1.5` to `+3.5`), split into 2-length segments. Outer rail spans: 34 on the long sides, 24 on the short sides. Corner squares (`Cushion_51..54`): upper-left and lower-right share one colour (`CORNER_DARK` + crimson banner), the other two share another (`CORNER_LIGHT` + blue banner).
- Cushion impacts deal no damage. **Special Cushions** (segments with triggered effects) are future work.
- Pocket Areas: hollow 2×2 zones at the four corners (`TableBlock_1`, `TableBlock_15`, `TableBlock_136`, `TableBlock_150`). Damage / kill / next-Action-Time return rules: see `.docs/contexts/battlefield.md` → Pocket Area.
- Obstacles: TBA, future.

## Puck sizes (test scene)

Radius, height, and mass, sized by what the puck represents (Adventurer class defaults are defined in `.docmanual/codexList/classes/`):

| Puck | Radius | Height | Mass |
|---|---|---|---|
| Boss Monster | 0.8 | 0.6 | 3.2 |
| Guard | 0.65 | 0.4 | 1.75 |
| Brawler | 0.6 | 0.35 | 1.5 |
| Scout | 0.57 | 0.35 | 1.35 |
| Acolyte | 0.55 | 0.35 | 1.25 |

## Camera

- Fixed-side view; two on-screen buttons (left / right) move the camera to the adjacent rail side, ~1 second per move.

## Parked / deferred

- Camera-button behaviour while a move is already in progress (the source doc sentence trails off — needs a decision when the camera is revisited).
- Gameplay rules triggered by special-effect Tiles, Special Cushions, pocket damage/return lifecycle, and obstacles.
