# 02 — Drag-and-Shot input, straight 3D aiming arrow, impulse launch, and friction

**What to build:** Replace placeholder Boss Monster keyboard movement (and pause Enemy Hero AI wandering in the demo) with Drag-and-Shot aiming and launch. In the demo battlefield, Energy starts at `15.0` and refills to `15.0` every `20` seconds on the Time Board. Clicking the Boss Monster puck when all Pucks are at rest and dragging on the table plane aims a Cue-Shot opposite the drag direction, quantizes required Energy to `1.0..9.0` in `0.5`-slot steps, updates the Time Board preview live, and displays a straight 3D arrowed aiming line at `Y = 1.55` whose length is proportional to the Impulse to be applied (turning red in the cancel deadzone or when over-dragged). Releasing inside the deadzone or while over-dragged cancels the drag with a cancellation sound without spending Energy. Releasing a valid drag deducts the Energy, applies Impulse $\vec{J} = k \cdot E$ ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$ so a heavier Boss Monster starts slower), and decelerates the moving Puck at a constant Friction rate (scaled by Tile friction) until it comes to rest.

**Blocked by:** 01 — Time Board half-slot Energy and bottom-left consume/over-drag preview

**Status:** ready-for-agent

- [ ] Enemy Hero AI movement is paused in the demo battlefield so Pucks stand stationary outside `Puck-puck Time!`
- [ ] Demo Energy starts at `15.0` on the Time Board and refills to `15.0` every `20` seconds
- [ ] Clicking the Boss Monster at rest and dragging on the `Y = 1.5` table plane computes shot direction opposite the drag and required Energy in `[1.0, 9.0]` at `0.5`-slot steps, updating the Time Board preview live
- [ ] A 3D arrowed aiming line renders at `Y = 1.55` with length proportional to the selected Impulse, turning red when inside the cancel deadzone or over-dragged
- [ ] Releasing inside the deadzone or when `required_energy > owned_energy` cancels the shot, plays a cancellation sound, and spends no Energy
- [ ] Releasing a valid shot deducts `required_energy`, launches the Boss Monster with $\vec{v}_0 = (k \cdot E / m_{\text{boss}})\hat{u}$, and decelerates it at a constant Friction rate until it stops
- [ ] Automated tests verify `0.5`-slot quantization, deadzone/over-drag cancellation, mass-dependent launch speed ($\vec{v}_0 = \vec{J} / m_{\text{boss}}$), and constant-friction deceleration to rest
