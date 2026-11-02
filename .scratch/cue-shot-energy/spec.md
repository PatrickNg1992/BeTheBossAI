# Spec: Cue-Shot, First-Rebound Aiming & Collision Physics

Status: ready-for-agent

The player's core physical action in the Battlefield Scene: dragging from the Boss Monster puck to aim with a 3D first-rebound preview and Time Board Energy preview, releasing to launch with an Impulse, and resolving puck–puck and puck–cushion impacts during `Puck-puck Time!`. Vocabulary per `CONTEXT.md`, `.docs/contexts/battlefield.md`, and `GLOSSARY.md` (Boss Monster, Enemy Hero, Class, Cue Table, Tile, Cushion, Pocket Area, Puck, Cue-Shot, Impulse, Friction, Energy, Time Board, Play Time, Puck-puck Time!).

## Problem Statement

Today on the demo Battlefield, the Boss Monster moves via placeholder keyboard input and Enemy Heroes wander continuously with basic slide movement. There is no way for the player to drag and aim a Cue-Shot, no visual prediction of where the Boss Monster or a struck Enemy Hero will travel after impact, no Energy cost preview on the Time Board, and no classical-mechanics rebound physics when pucks strike each other or the Cushions. Without Drag-and-Shot aiming and `Puck-puck Time!` collision physics, the core "snooker with cards" gameplay loop cannot be played or tuned.

## Solution

Replace placeholder Boss Monster keyboard movement (and pause continuous Enemy Hero wandering in the demo) with a Drag-and-Shot controller and a classical-mechanics collision engine:

1. **Drag-and-Aim Input**: When all Pucks on the Cue Table are at rest, clicking the Boss Monster and dragging on the table surface aims a Cue-Shot opposite the drag direction. Drag distance selects the required Energy from `1.0` to `9.0` slots in `0.5`-slot increments.
2. **Time Board Energy Preview (from Bottom-Left Slot 0)**: While dragging, the Time Board highlights the required Energy starting from `slot 0` (bottom-left) in a consume-preview colour. If the player drags past their owned Energy, the preview continues past the filled Energy slots in **red**.
3. **3D First-Rebound Aiming Line**: A 3D arrowed aiming line lies just above the table surface, swept using the Boss Monster's cylinder radius. Its reach scales proportionally to the selected Impulse. If a Cushion or another Puck lies within that reach, a ghost contact ring is shown at the impact point along with the Boss Monster's first rebound arrow ($\vec{v}_{1f}$); if the first hit is another Puck, a second contrasting arrow from the struck Puck's center shows its outgoing direction ($\vec{v}_{2f}$). Both post-hit arrow lengths scale with their post-impact speeds.
4. **Release, Cancel & `Puck-puck Time!` Physics**: Releasing inside a small cancel deadzone around the Boss Monster or while over-dragged (requiring more Energy than owned) cancels the drag with a cancellation sound and consumes no Energy. Releasing a valid drag deducts the Energy, applies an Impulse $\vec{J} \propto E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$, so heavier Boss Monsters launch slower), and runs `Puck-puck Time!` physics — constant-rate Friction deceleration, mass-weighted puck–puck impulse collisions, perpendicular/parallel Cushion rebounds, and Pocket Area falls — until every Puck comes to rest.

## User Stories

1. As a player, I want to click on the Boss Monster puck and drag to aim a Cue-Shot, so that I can launch the Boss Monster across the Cue Table like a cue ball.
2. As a player, I want the shooting direction to be opposite the drag direction, so that pulling back feels like drawing a slingshot or cue stick.
3. As a player, I want to aim only when all Pucks on the Cue Table are at rest, so that I cannot interfere with an ongoing shot.
4. As a player, I want the drag distance on the table plane to control how much Energy the shot consumes, so that pulling farther produces a stronger shot.
5. As a player, I want Energy consumption for a single Cue-Shot to step in `0.5`-slot increments from a minimum of `1.0` slot to a maximum of `9.0` slots, so that I have fine-grained control over shot power.
6. As a player, I want the Time Board to highlight the required Energy slots starting from the bottom-left (`slot 0`) while I drag, so that I can see how much Energy my shot will consume.
7. As a player, I want any required Energy exceeding my currently owned Energy to continue past the filled Energy slots in red on the Time Board, so that I can immediately tell when I am over-dragging.
8. As a player, I want to release the drag very close to the Boss Monster puck to cancel the shot, so that I can abort and re-aim without spending Energy.
9. As a player, I want releasing the drag while over-dragged (requiring more Energy than I own) to cancel the shot, so that I never fire an unaffordable shot.
10. As a player, I want a cancellation sound to play whenever a drag is cancelled, so that I get clear audio feedback that no shot was fired.
11. As a player, I want cancelling a drag to keep the game in `Play Time` without spending Energy, so that I can immediately re-aim.
12. As a player, I want a 3D arrowed aiming line displayed just above the Cue Table floor while dragging, so that I can see the exact path my Boss Monster will take.
13. As a player, I want the primary aiming line's reach to be proportional to the Impulse to be applied, so that shorter drags show shorter reach and only reach distant obstacles when pulled hard enough.
14. As a player, I want the aiming prediction to account for the Boss Monster's physical radius, so that glancing edge hits against other Pucks and Cushions are predicted accurately.
15. As a player, I want the aiming line to show a ghost contact ring and the Boss Monster's first rebound arrow ($\vec{v}_{1f}$) when a Cushion or another Puck is within reach, so that I can plan bank shots and deflections.
16. As a player, I want a second arrow in a contrasting colour drawn from the struck Puck's center showing its outgoing direction ($\vec{v}_{2f}$) when the first hit is another Puck, so that I can aim enemies into other Pucks or Pocket Areas.
17. As a player, I want the lengths of both post-hit arrows ($\vec{v}_{1f}$ and $\vec{v}_{2f}$) to be proportional to their post-impact speeds from the collision equations, so that hitting a light Mage visibly shows a longer launch than hitting a heavy Knight.
18. As a player, I want all 3D aiming line segments to turn red when I over-drag past my owned Energy or stay inside the cancel deadzone, so that I don't have to look away from the table to know the shot will cancel.
19. As a player, I want a valid release to deduct the selected Energy from my owned Energy (rewinding the Time Board fill) and apply an Impulse proportional to the Energy spent, so that higher-Energy shots hit harder.
20. As a player, I want the Boss Monster's initial launch speed to be $\vec{v}_0 = \vec{J} / m_{\text{boss}}$, so that a heavier Boss Monster starts with a slower speed for the same Energy while carrying greater momentum into collisions.
21. As a player, I want each Puck to have a relative mass based on the unit it represents (Boss Monster > Knight > Warrior > Ranger > Mage), so that heavier units are harder to knock around and transfer more momentum to lighter units.
22. As a player, I want moving Pucks to decelerate at a constant rate due to table Friction (scaled by the underlying Tile's friction factor) until they stop, so that travel distance scales with $v_0^2$.
23. As a player, I want two colliding Pucks to exchange opposite Impulses along their collision normal using classical elastic/inelastic mechanics ($e$), so that chain reactions feel physical and predictable.
24. As a player, I want a Puck colliding with a Cushion to rebound with perpendicular restitution ($e$) and parallel Cushion friction ($f_c$), so that bank shots behave like a real cue table.
25. As a player, I want a Puck that enters a hollow Pocket Area during `Puck-puck Time!` to fall into the pocket and, in the demo sandbox, respawn at the nearest free Tile once all Pucks come to rest, so that I can continuously test shots without running out of targets.
26. As a designer, I want Enemy Hero AI movement paused in the demo sandbox and Energy to start at `15.0` and refill to `15.0` every `20` seconds, so that I can freely test Drag-and-Shot, rebounds, and mass values before integrating the full `TimingManager` rotation.

## Implementation Decisions

- **Drag Plane & Input Mapping**:
  - Mouse input is raycast from the active 3D camera onto the horizontal Cue Table top plane (`Y = 1.5`).
  - Dragging begins when the player presses left mouse button on (or within the pick radius of) the Boss Monster puck while all Pucks on the table are at rest.
  - The drag vector is $\vec{d} = \vec{p}_{\text{mouse}} - \vec{p}_{\text{boss}}$ on the XZ plane (`Y = 0` component). The shot direction is $\hat{u} = -\vec{d} / \|\vec{d}\|$.
  - If $\|\vec{d}\| < d_{\text{deadzone}}$ (very close to the Boss Monster puck), the drag is in the cancel zone.
  - Beyond $d_{\text{deadzone}}$, drag distance maps linearly up to a max drag distance, quantized to `0.5`-slot steps in the range `[1.0, 9.0]`:
    $$\text{required\_energy} = \text{clamp}(\text{ snapped}(1.0 + t \cdot 8.0,\; 0.5),\; 1.0,\; 9.0)$$
  - A drag is **over-dragged** when $\text{required\_energy} > \text{owned\_energy}$. Releasing while in the deadzone or while over-dragged cancels the drag, plays a procedural/audio cancellation sound, clears the preview, and stays ready to aim in `Play Time`.
- **Time Board Energy & Preview Contract**:
  - The Time Board state contract is extended to support half-slot Energy values (`energy: float` in `0.0..20.0`) and an optional aiming preview (`preview_cost: float`, `0.0` when not aiming).
  - When `preview_cost > 0.0`, the Time Board colours slots starting from the **bottom-left (`slot 0`)** along the serpentine path up to `preview_cost`:
    - The portion from `0.0` to $\min(\text{preview\_cost}, \text{owned\_energy})$ renders in a distinct consume-preview colour.
    - Any over-dragged portion from $\text{owned\_energy}$ to $\text{preview\_cost}$ continues past the filled Energy slots in **red**.
    - Any remaining owned Energy from $\text{preview\_cost}$ to $\text{owned\_energy}$ stays in the normal gold Energy colour.
    - Half-slot boundaries (`0.5`) fill half of the corresponding slot cell horizontally in that slot's travel direction.
- **Impulse, Mass & Friction Model**:
  - Every Puck carries an exported `mass: float` and `restitution: float` (`e`), plus a horizontal velocity vector (`velocity.x`, `velocity.z`).
  - Default relative masses:
    - Boss Monster: `3.0`
    - Knight: `2.0`
    - Warrior: `1.5`
    - Ranger: `1.2`
    - Mage: `1.0`
  - Firing a Cue-Shot with consumed Energy $E \in [1.0, 9.0]$ applies an Impulse magnitude $J_{\text{shot}} = k_{\text{impulse}} \cdot E$ along $\hat{u}$, setting the Boss Monster's initial velocity to:
    $$\vec{v}_0 = \frac{J_{\text{shot}}}{m_{\text{boss}}} \, \hat{u}$$
  - During `Puck-puck Time!`, each moving Puck decelerates at a constant rate per second:
    $$a_{\text{friction}} = \text{base\_deceleration} \times \text{tile\_friction\_factor}$$
    reducing $\|\vec{v}_{xz}\|$ linearly toward `0` and snapping to rest (`Vector3.ZERO`) below a small rest speed threshold.
- **Puck–Puck & Puck–Cushion Collision Equations**:
  - **Puck–Puck impact** between Puck 1 ($\vec{p}_1, \vec{v}_1, m_1$) and Puck 2 ($\vec{p}_2, \vec{v}_2, m_2$) with combined restitution $e$:
    1. Collision normal on the table plane: $\hat{n} = (\vec{p}_1 - \vec{p}_2) / \|\vec{p}_1 - \vec{p}_2\|$
    2. Relative closing velocity: $v_{\text{rel}} = (\vec{v}_1 - \vec{v}_2) \cdot \hat{n}$
    3. Guard: only apply impulse when approaching ($v_{\text{rel}} < 0$), plus positional separation if cylinders overlap:
       $$J = \frac{-(1 + e)\,v_{\text{rel}}}{(1 / m_1) + (1 / m_2)}$$
    4. Velocity update:
       $$\vec{v}_{1f} = \vec{v}_1 + \frac{J}{m_1}\hat{n}, \qquad \vec{v}_{2f} = \vec{v}_2 - \frac{J}{m_2}\hat{n}$$
  - **Puck–Cushion impact** against a Cushion with inward normal $\hat{n}$, restitution $e$, and parallel Cushion friction $f_c$:
    $$\vec{v}_{1f} = (1 - f_c)\left(\vec{v}_1 - (\vec{v}_1 \cdot \hat{n})\hat{n}\right) - e\,(\vec{v}_1 \cdot \hat{n})\hat{n}$$
- **Swept 3D Aiming Line & First-Rebound Calculation**:
  - A pure trajectory prediction helper sweeps a circle of radius $R_{\text{boss}}$ from the Boss Monster's XZ position along $\hat{u}$ up to a reach distance proportional to the selected Impulse ($L_{\text{max}} = k_{\text{aim}} \cdot J_{\text{shot}}$).
  - It finds the earliest time-of-impact $t_{\text{hit}} \in [0, L_{\text{max}}]$ against:
    - Any active Puck cylinder $(p_2, R_2)$ via ray–circle intersection of radius $R_{\text{boss}} + R_2$, or
    - The inner Cushion planes ($x = \pm(15 - R_{\text{boss}})$, $z = \pm(10 - R_{\text{boss}})$).
  - If no hit occurs within $L_{\text{max}}$, the primary arrow ends at $\vec{p}_{\text{boss}} + L_{\text{max}}\hat{u}$ with no rebound arrows.
  - If a hit occurs at contact center $\vec{p}_{\text{hit}}$:
    - Primary line runs from $\vec{p}_{\text{boss}}$ to $\vec{p}_{\text{hit}}$ with a 3D contact ring of radius $R_{\text{boss}}$ at $\vec{p}_{\text{hit}}$.
    - Post-impact velocity $\vec{v}_{1f}$ (and $\vec{v}_{2f}$ if hitting another Puck with $\vec{v}_2 = \vec{0}$) is computed using the exact collision equations above, and the post-hit arrow lengths scale proportionally to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$.
- **Demo Sandbox Mode & Pocket Respawn**:
  - In the demo battlefield (`demo_bettlefield.tscn`), Enemy Hero AI wandering/chasing is disabled by default so Pucks remain stationary outside `Puck-puck Time!`.
  - Demo Energy starts at `15.0` and refills to `15.0` every `20.0` seconds (with `TimeBoard.demo_mode` set to `false` on the battlefield instance so the board reflects real shot Energy and drag previews).
  - If any Puck falls into a Pocket Area during `Puck-puck Time!`, it is flagged as pocketed and, once all remaining Pucks come to rest, respawns at the nearest unoccupied non-pocket Tile at `Y = 1.5 + half_height` with zero velocity.

## Testing Decisions

- **What makes a good test**: Tests drive public methods and assert observable state and physics outcomes (calculated required Energy, cancel/fire decision, aiming trajectory points and post-hit velocity vectors, Puck velocities/positions after impacts, and Time Board slot fill/colour states) — never internal mesh nodes, shader parameters, or audio stream internals.
- **Two seams**:
  1. **Battlefield Shot & Physics Seam**: Drive drag start/update/release and physics steps; assert:
     - `0.5`-slot quantization in `[1.0, 9.0]`, deadzone cancellation, and over-drag cancellation.
     - Launch velocity $\vec{v}_0 = (k \cdot E / m_{\text{boss}})\hat{u}$ verifying that a heavier Boss Monster launches slower for the same Energy.
     - First-rebound aiming calculation against both a Cushion and an Enemy Hero Puck (contact point, $\vec{v}_{1f}$, and $\vec{v}_{2f}$).
     - Puck–puck impulse exchange (heavy vs. light Puck momentum transfer) and Puck–cushion rebound velocity.
     - Constant-friction deceleration to rest and pocketed Puck respawn at the nearest free Tile when all Pucks settle.
  2. **Time Board View Seam**: Extend `test_time_board_view.gd` (or a dedicated suite) to assert that feeding `preview_cost` highlights slots starting from `slot 0` (including `.5` half-slots) and colours slots beyond `owned_energy` in red.
- **Prior art**: `tests/test_cue_table.gd` (3D table & cushion rebound assertions) and `tests/test_time_board_view.gd` (crafted state → observable slot ratios/colours on `TimeBoard`).

## Out of Scope

- Full `TimingManager` turn rotation (`Prepare` → `Charging` → `Play` → `Action` → `Puck-puck Time!` → `Settle`) and Action Tag scheduling (covered by `.scratch/timing-system/spec.md`).
- Collision Damage numbers, Knight protection rules, Focusing Interrupts, and staged damage application in Settle Time.
- Card effects that launch or move Pucks (covered by `.scratch/card-effects/spec.md`).
- Final audio assets and VFX particles.

## Further Notes

- All tuning knobs (`impulse_per_energy`, `drag_distance_per_energy`, `deadzone_radius`, `base_deceleration`, `aim_length_per_impulse`, `rest_speed_threshold`) should be `@export` properties so they can be tweaked live in the Godot Inspector while testing in `demo_bettlefield.tscn`.
