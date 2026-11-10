# 02 — Drag-and-Shot input, straight 3D aiming arrow, impulse launch, and 20 Hz ground friction

**What to build:** Replace placeholder Boss Monster keyboard movement (and pause Enemy Adventurer AI wandering in the demo) with Drag-and-Shot aiming, launch, and a `PuckVelocityManager` that updates positions every frame while updating velocities at 20 Hz (`0.05s`). Each Puck stores `radius`, `mass`, and `velocity`. Each `TableBlock` provides an extendable ground-effect function taking the Puck as input and applying a standard friction deceleration of `-1.0 unit/sec²` (scaled by `friction_factor`, independent of mass in the normal case) with a stop threshold so Pucks never reverse direction. In the demo battlefield, Energy starts at `15.0` and refills to `15.0` every `20` seconds on the Time Board. Clicking the Boss Monster puck when all Pucks are at rest and dragging on the table plane aims a Cue-Shot opposite the drag direction, quantizes required Energy to `1.0..9.0` in `0.5`-slot steps, updates the Time Board preview live, and displays a straight 3D arrowed aiming line at `Y = 1.55` whose length is proportional to the Impulse to be applied (turning red in the cancel deadzone or when over-dragged). Releasing inside the deadzone or while over-dragged cancels the drag with a cancellation sound without spending Energy. Releasing a valid drag deducts the Energy, applies Impulse $\vec{J} = k \cdot E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$ so a heavier Boss Monster starts slower), and decelerates the moving Puck via the 20 Hz ground-friction tick until it comes to rest.

**Blocked by:** 01 — Time Board half-slot Energy and bottom-left consume/over-drag preview

**Status:** implemented (93/93 tests green)

- [x] Enemy Adventurer AI movement is paused in the demo battlefield so Pucks stand stationary outside `Puck-puck Time!`
- [x] Each Puck stores `radius`, `mass`, and `velocity`; `PuckVelocityManager` updates Puck positions each frame and recalculates velocity changes at 20 Hz (`0.05s`)
- [x] `TableBlock` exposes an extendable ground-effect function taking `puck: BasePuck` that decelerates moving Pucks at `-1.0 unit/sec²` on standard blocks (e.g. `5 units/sec` slows to `4 units/sec` after `1s`) and clamps to `Vector3.ZERO` below the stop threshold
- [x] Demo Energy starts at `15.0` on the Time Board and refills to `15.0` every `20` seconds
- [x] Clicking the Boss Monster at rest and dragging on the `Y = 1.5` table plane computes shot direction opposite the drag and required Energy in `[1.0, 9.0]` at `0.5`-slot steps, updating the Time Board preview live
- [x] A 3D arrowed aiming line renders at `Y = 1.55` with length proportional to the selected Impulse, turning red when inside the cancel deadzone or over-dragged
- [x] Releasing inside the deadzone or when `required_energy > owned_energy` cancels the shot, plays a cancellation sound, and spends no Energy
- [x] Releasing a valid shot deducts `required_energy`, launches the Boss Monster with $\vec{v}_0 = (k \cdot E / m_{\text{boss}})\hat{u}$, and decelerates it to rest
- [x] Automated tests verify `0.5`-slot quantization, deadzone/over-drag cancellation, mass-dependent launch speed ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$), and `-1.0 unit/sec²` ground friction deceleration to rest
