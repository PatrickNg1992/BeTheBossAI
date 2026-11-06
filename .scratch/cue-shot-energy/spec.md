# Spec: Cue-Shot, First-Rebound Aiming & Puck Physics System

Status: ready-for-agent

The player's core physical action and the tailor-made Puck physics engine in the Battlefield Scene: dragging from the Boss Monster puck to aim with a 3D first-rebound preview and Time Board Energy preview, releasing to apply an Impulse, and resolving motion, ground Friction Forces, and Puck/Cushion collision Impulses during `Puck-puck Time!`. Vocabulary per `CONTEXT.md`, `.docs/contexts/battlefield.md`, and `GLOSSARY.md` (Boss Monster, Enemy Hero, Class, Cue Table, Tile, Cushion, Pocket Area, Puck, Cue-Shot, Impulse, Force, Friction, Energy, Time Board, Play Time, Puck-puck Time!).

## Problem Statement

Today on the demo Battlefield, the Boss Monster is driven by placeholder keyboard input and Enemy Heroes run continuous `move_and_slide()` wandering AI. Pucks do not store explicit `radius` and `mass` state for custom physics, there is no central velocity manager separating high-frequency position updates from 20 Hz velocity/collision/friction calculations, floor blocks do not expose an extendable ground-friction function to bring moving Pucks to a stop, and there is no Drag-and-Shot aiming UI, Time Board Energy preview, or first-rebound aiming line. Without these systems, Pucks cannot be launched, bounced, or reliably brought to rest after a Cue-Shot.

## Solution

Introduce a tailor-made Puck physics and Drag-and-Shot system across the Puck scripts, Cue Table blocks, Time Board view, and a central `PuckVelocityManager` on the Battlefield:

1. **Puck State & `PuckVelocityManager` (60 Hz Position / 20 Hz Velocity)**:
   - Every Puck (`BasePuck` and subclasses) belongs to the `"pucks"` group and stores `radius`, `mass`, and `velocity` (default masses: Boss Monster `3.0`, Knight `2.0`, Warrior `1.5`, Ranger `1.2`, Mage `1.0`; `radius` read from its cylinder collider or exported property).
   - A Battlefield-level `PuckVelocityManager` advances moving Puck positions every frame ($\Delta \vec{p} = \vec{v} \cdot \Delta t$, host-authoritative for `MultiplayerSynchronizer`) and runs velocity updates at **20 Hz (`0.05s` interval)** to resolve collisions and ground Friction Forces with minimal CPU overhead.
2. **Extendable Ground Friction on `TableBlock` (`-1.0 unit/sec²`)**:
   - Each `TableBlock` exposes an extendable method taking `puck: BasePuck` that computes the continuous ground effect on velocity.
   - In the normal case, mass cancels out ($\vec{F}_{\text{friction}} \propto m \implies \vec{a} = \vec{F}/m$): a standard grass block decelerates a moving Puck at **$-1.0\text{ unit/sec}^2$** (scaled by `friction_factor`, so a Puck at `5 units/sec` slows to `4 units/sec` after `1s`), clamping velocity to `Vector3.ZERO` below a small stop threshold so Friction never reverses direction.
3. **Extendable Cushion Impact on `CushionBlock` & Swept Puck Collisions**:
   - At each 20 Hz velocity tick, `PuckVelocityManager` performs a simple swept/overlap check for moving Pucks against other Pucks and Cushions.
   - Puck–Puck impacts exchange opposite Impulses along the collision normal $\hat{n}$ according to their relative masses ($m_1, m_2$) and restitution ($e$).
   - Puck–Cushion impacts call an extendable impact method on the struck `CushionBlock` taking `(puck: BasePuck, normal: Vector3)` that applies the perpendicular restitution ($e$) and parallel Cushion friction ($f_c$) rebound equation (mass-independent in the normal case).
4. **Time Board Half-Slot Energy & Bottom-Left Preview**:
   - The Time Board view supports half-slot (`0.5`) Energy amounts (`0.0..20.0`) and an aiming `preview_cost` (`1.0..9.0` in `0.5` steps).
   - While dragging, required Energy is highlighted starting from the **bottom-left (`slot 0`)** in a consume-preview colour up to owned Energy, and any over-dragged excess continues past the filled Energy slots in **red**.
5. **Drag-and-Shot Input & 3D First-Rebound Aiming Line**:
   - Clicking the Boss Monster when all Pucks are at rest and dragging on the `Y = 1.5` table plane aims opposite the drag direction.
   - A 3D arrowed aiming line at `Y = 1.55` (swept with the Boss Monster's radius $R_{\text{boss}}$) extends up to a reach proportional to the selected Impulse. When a Cushion or another Puck lies within that reach, it renders a ghost contact ring at the impact point, the Boss Monster's first-rebound arrow ($\vec{v}_{1f}$), and (when hitting a Puck) a contrasting arrow from the struck Puck's center along $\vec{v}_{2f}$, with post-hit arrow lengths proportional to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$.
   - Releasing inside the deadzone or while over-dragged cancels the shot with a cancellation sound. Releasing a valid drag deducts the Energy and applies Impulse $\vec{J} = k \cdot E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$) to enter `Puck-puck Time!`.

## User Stories

1. As a player, I want every moving Puck on the Cue Table to gradually slow down and come to a complete stop due to ground Friction, so that every Cue-Shot finishes cleanly and transitions out of `Puck-puck Time!`.
2. As a player, I want a Puck on a standard grass Tile to decelerate at `-1.0 unit/sec²` (slowing from `5 units/sec` to `4 units/sec` after `1` second) and stop cleanly at zero without ever reversing direction, so that shot stopping distances are predictable.
3. As a designer, I want different `TableBlock` types (`GRASS`, `STONE`, `MUD`, `ICE`, and future custom blocks) to modify ground Friction or apply custom Forces via an extendable method on `TableBlock` that receives the Puck as input, so that swapping table blocks creates fun gameplay variations.
4. As a player, I want each Puck to have a `radius` and a relative `mass` based on the unit it represents (Boss Monster > Knight > Warrior > Ranger > Mage), so that heavier Pucks are harder to knock around and transfer more momentum to lighter Pucks.
5. As a developer, I want Puck positions updated every frame while velocity changes (collisions and ground Friction) are calculated at ~20 Hz (`0.05s`) by a central `PuckVelocityManager`, so that motion looks smooth at 60+ FPS while physics calculation overhead stays low.
6. As a player, I want two colliding Pucks to exchange opposite Impulses along their contact normal using classical mechanics ($m_1, m_2, e$), so that chain collisions feel physical and reward hitting lighter Enemy Heroes with a heavy Boss Monster.
7. As a player, I want a Puck hitting a Cushion to rebound with perpendicular restitution ($e$) and parallel Cushion friction ($f_c$) via an extendable impact method on `CushionBlock`, so that bank shots behave like a cue game and future Special Cushions can override the impact.
8. As a player, I want any Puck that falls into a hollow Pocket Area during `Puck-puck Time!` to respawn at the nearest unoccupied non-pocket Tile once all Pucks come to rest in the demo sandbox, so that I can keep testing shots without running out of Pucks.
9. As a player, I want the Time Board to display half-slot (`0.5`) Energy amounts (`0.0..20.0`), so that spending `.5` Energy increments is accurately reflected on the bar.
10. As a player, I want the Time Board to highlight the required Energy for my shot starting from the bottom-left (`slot 0`) while I drag, so that I can see the Energy cost at a glance.
11. As a player, I want any required Energy exceeding my currently owned Energy to continue past the filled Energy slots in red on the Time Board, so that I clearly see when I am over-dragging.
12. As a player, I want to click on the Boss Monster puck when all Pucks are at rest and drag on the table plane to aim a Cue-Shot opposite the drag direction, so that aiming feels like drawing back a cue or slingshot.
13. As a player, I want my drag distance to select an Energy cost from `1.0` to `9.0` slots in `0.5`-slot steps, so that I can control shot power precisely.
14. As a player, I want releasing the drag very close to the Boss Monster puck (inside the deadzone) or while over-dragged to cancel the shot, play a cancellation sound, and stay in `Play Time` without spending Energy, so that I can safely abort or adjust my aim.
15. As a player, I want releasing a valid drag to spend the selected Energy and apply an Impulse $\vec{J} \propto E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$) to the Boss Monster, so that a heavier Boss Monster starts with a slower speed for the same Energy while carrying heavy mass into impacts.
16. As a player, I want a 3D arrowed aiming line at `Y = 1.55` whose reach scales with the selected Impulse, so that I can see whether my shot has enough power to reach a target.
17. As a player, I want the aiming line to sweep the Boss Monster's physical radius $R_{\text{boss}}$ and show a ghost contact ring plus the Boss Monster's first-rebound arrow ($\vec{v}_{1f}$) when a Cushion or Puck lies within reach, so that I can aim angled cuts and bank shots accurately.
18. As a player, I want a second contrasting arrow drawn from a struck Puck's center along its post-impact velocity ($\vec{v}_{2f}$) when the first hit is another Puck, with both post-hit arrow lengths proportional to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$, so that I can predict where both Pucks will go after impact.
19. As a player, I want all 3D aiming visuals to turn red when I am inside the cancel deadzone or over-dragged, so that I can see on the table when the shot will cancel.
20. As a designer, I want Enemy Hero wandering AI paused in the demo battlefield and Energy to start at `15.0` and refill to `15.0` every `20` seconds, so that I can test Drag-and-Shot, friction stopping, and rebounds interactively before the full `TimingManager` rotation is wired.

## Implementation Decisions

- **Puck State (`BasePuck`, `DragonPlayer`, `EnemyHero`)**:
  - `BasePuck` registers itself in the `"pucks"` group and owns:
    - `@export var mass: float = 1.0`
    - `@export var radius: float = 0.5` (auto-initialized on `_ready()` from its `CollisionShape3D`'s `CylinderShape3D.radius` if present)
    - `@export var restitution: float = 0.85`
    - `velocity: Vector3` (horizontal motion in `velocity.x` and `velocity.z`)
    - `apply_impulse(impulse: Vector3) -> void`: one-off velocity change `velocity += impulse / mass`.
  - Default unit masses:
    - Boss Monster (`DragonPlayer`): `3.0`
    - Knight: `2.0`
    - Warrior: `1.5`
    - Ranger: `1.2`
    - Mage: `1.0`
  - In the demo sandbox, `BaseEnemy` autonomous wandering/chasing is gated by an `@export var ai_enabled: bool = false` flag so Enemy Heroes stay stationary unless moved by `PuckVelocityManager`.
- **`PuckVelocityManager` (60 Hz Position / 20 Hz Velocity & Swept Collision)**:
  - Hosted on the Battlefield (and callable directly in tests via `step_positions(delta: float)` and `step_velocities(tick_dt: float)`):
    - **`_process(delta)` → `step_positions(delta)`**: Advances each moving Puck's horizontal position by `velocity * delta` (and vertical pocket fall via `apply_table_physics(delta)`).
    - **20 Hz accumulator (`TICK_INTERVAL = 0.05s`) → `step_velocities(tick_dt)`**:
      1. **Swept / Overlap Collision Check**: Over the `tick_dt` window, checks moving Pucks against other active Pucks (swept circle–circle intersection of combined radius $r_1 + r_2$) and against Cushion inner boundaries ($x = \pm(15 - r)$, $z = \pm(10 - r)$). Separates any positional overlap along $\hat{n}$ so Pucks never snag inside each other or inside a Cushion.
      2. **Puck–Puck Impulse**: When two Pucks collide with relative closing velocity $v_{\text{rel}} = (\vec{v}_1 - \vec{v}_2) \cdot \hat{n} < 0$:
         $$J = \frac{-(1 + e)\,v_{\text{rel}}}{(1 / m_1) + (1 / m_2)}, \qquad \vec{v}_{1f} = \vec{v}_1 + \frac{J}{m_1}\hat{n}, \qquad \vec{v}_{2f} = \vec{v}_2 - \frac{J}{m_2}\hat{n}$$
      3. **Puck–Cushion Impact**: Calls the struck `CushionBlock`'s extendable impact function `calculate_cushion_impact(puck, normal)` to update the Puck's velocity.
      4. **Ground Friction Force**: Queries the `TableBlock` beneath each moving Puck (`Battlefield.get_table_block_at_world(puck.global_position)`) and calls its extendable ground-effect function `apply_ground_effect(puck, tick_dt)` (or `calculate_ground_velocity_delta(puck, tick_dt)`).
      5. **All-at-rest & Pocket Respawn**: When all non-pocketed Pucks reach `velocity == Vector3.ZERO`, any Puck that fell into a Pocket Area (`is_pocket_at_world` or `global_position.y < 1.0`) is repositioned at the nearest unoccupied non-pocket Tile at `Y = 1.5 + half_height` with `velocity = Vector3.ZERO`.
- **Extendable `TableBlock` Ground Friction (`-1.0 unit/sec²` Standard)**:
  - `TableBlock` defines `@export var base_deceleration: float = 1.0` (`1.0 unit/sec²` for standard blocks) and `friction_factor: float` (`1.0` for grass, `0.75` for stone, `2.0` for mud, `0.2` for ice).
  - Extendable method on `TableBlock`:
    ```gdscript
    func calculate_ground_velocity_delta(puck: BasePuck, dt: float) -> Vector3
    ```
  - In the normal case, mass cancels out: for a Puck with horizontal speed $s = \|\vec{v}_{xz}\| > 0$, deceleration magnitude is $d = \text{base\_deceleration} \times \text{friction\_factor} \times dt$. If $s \le d$ or $s - d < \text{ STOP\_THRESHOLD}$, velocity snaps to `Vector3.ZERO`; otherwise horizontal speed reduces by $d$ along $-\hat{v}$.
- **Extendable `CushionBlock` Impact**:
  - `CushionBlock` defines an extendable method:
    ```gdscript
    func calculate_cushion_impact(puck: BasePuck, normal_override: Vector3 = Vector3.ZERO) -> Vector3
    ```
  - Returns the velocity change $\Delta \vec{v} = \vec{v}_{1f} - \vec{v}_1$ (where $\vec{v}_{1f} = (1 - f_c)(\vec{v}_1 - (\vec{v}_1 \cdot \hat{n})\hat{n}) - e(\vec{v}_1 \cdot \hat{n})\hat{n}$, independent of `puck.mass` in the normal case) when `puck` approaches the cushion ($\vec{v}_1 \cdot \hat{n} < 0$).
- **Time Board Half-Slot Energy & Bottom-Left Preview**:
  - `TimeBoard` supports floating-point `energy` (`0.0..20.0` in `0.5` steps) and `preview_cost` (`0.0` when idle, `1.0..9.0` in `0.5` steps while aiming).
  - When `preview_cost > 0`, slots starting from **`slot 0` (bottom-left)** up to `min(preview_cost, energy)` display the consume-preview colour; any portion from `energy` to `preview_cost` (when `preview_cost > energy`) continues past the filled Energy slots in **red**; any remaining owned Energy from `preview_cost` to `energy` displays in the normal gold Energy colour.
- **Drag-and-Shot & Swept 3D First-Rebound Aiming Line**:
  - Dragging starts on left-click on the Boss Monster when all Pucks are at rest, raycasting the mouse onto the `Y = 1.5` plane.
  - Drag distance outside `deadzone_radius` maps to `required_energy` in `[1.0, 9.0]` snapped to `0.5`-slot steps.
  - Releasing inside `deadzone_radius` or with `required_energy > owned_energy` cancels the shot, plays a cancellation sound, clears `preview_cost`, and stays in `Play Time`.
  - Releasing a valid drag deducts `required_energy`, applies Impulse $\vec{J}_{\text{shot}} = (k_{\text{impulse}} \cdot E)\hat{u}$ to the Boss Monster ($\vec{v}_0 = \vec{J}_{\text{shot}} / m_{\text{boss}}$), and enters `Puck-puck Time!`.
  - While dragging, the 3D aiming line at `Y = 1.55` sweeps $R_{\text{boss}}$ up to reach $L_{\text{max}} \propto \|\vec{J}_{\text{shot}}\|$. If a Cushion or Puck is hit within $L_{\text{max}}$, it displays a ghost contact ring of radius $R_{\text{boss}}$ at the contact center, the Boss Monster's first-rebound arrow ($\vec{v}_{1f}$), and (for a Puck hit) a contrasting arrow from the struck Puck's center along $\vec{v}_{2f}$, with arrow lengths proportional to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$. All aiming visuals turn red when in the deadzone or over-dragged.

## Testing Decisions

- **What makes a good test**: Drive public methods (`render_state`, `begin_drag` / `update_drag` / `release_drag`, `step_positions`, `step_velocities`) and assert observable state (slot fill ratios and preview colours on `TimeBoard`, Puck velocities and positions after 20 Hz ticks, and aiming preview trajectory data) — never private node hierarchies or tween internals.
- **Modules tested**:
  1. `TimeBoard` view (`src/canvas/time_board.gd`) — half-slot fills (`0.5`), consume preview starting from `slot 0`, and red over-drag preview past owned Energy.
  2. `TableBlock` (`src/battlefield/table_block.gd`) & `PuckVelocityManager` — standard `-1.0 unit/sec²` friction deceleration (e.g. `5.0 → 4.0 units/sec` after `1.0s` of 20 Hz ticks), stop-threshold clamping without reversing direction, and block-type friction scaling (`ICE` vs `MUD`).
  3. `CushionBlock` (`src/battlefield/cushion_block.gd`) & `PuckVelocityManager` — swept Puck–Puck impulse collisions across different masses ($m_1, m_2$), `CushionBlock.calculate_cushion_impact` rebounds, and pocketed Puck respawn after all Pucks come to rest.
  4. Drag-and-Shot controller & First-Rebound Aiming calculator — `0.5`-slot Energy quantization in `[1.0, 9.0]`, deadzone/over-drag cancellation, mass-dependent launch speed ($\vec{v}_0 = \vec{J}/m_{\text{boss}}$), and swept first-rebound vectors ($\vec{v}_{1f}, \vec{v}_{2f}$).
- **Prior art**: `tests/test_time_board_view.gd` and `tests/test_cue_table.gd`.

## Out of Scope

- Full `TimingManager` state machine (`Prepare`, `Charging`, `Play`, `Action`, `Puck-puck Time!`, `Settle`) and Action Tag scheduling.
- Collision Damage calculation, Knight protection rules, Focusing Interrupts, and staged damage in Settle Time.
- Multiplayer `MultiplayerSynchronizer` scene wiring (covered by `.docmanual/battleField/battleFieldDataSync.md`).
- Card effects and final audio/VFX assets.

## Further Notes

- All physics and aiming constants (`impulse_per_energy`, `drag_distance_per_energy`, `deadzone_radius`, `base_deceleration`, `stop_speed_threshold`, `aim_length_per_impulse`) are `@export` properties for live tuning in the Godot Inspector.
