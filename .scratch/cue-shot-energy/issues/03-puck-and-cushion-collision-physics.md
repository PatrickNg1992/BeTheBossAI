# 03 — Puck–Puck and Puck–Cushion collision physics and pocket respawn

**What to build:** Full `Puck-puck Time!` collision physics in `PuckVelocityManager` at the 20 Hz (`0.05s`) physics update using a simple swept/overlap check. Configure relative masses per Puck (Boss Monster `3.0`, Knight `2.0`, Warrior `1.5`, Ranger `1.2`, Mage `1.0`). When two Pucks collide, resolve the impact using the 4-step classical impulse equations ($\hat{n} = (\vec{p}_1 - \vec{p}_2)/\|\vec{p}_1 - \vec{p}_2\|$, $v_{\text{rel}} = (\vec{v}_1 - \vec{v}_2)\cdot\hat{n}$, $J = -(1+e)v_{\text{rel}} / (1/m_1 + 1/m_2)$, updating both $\vec{v}_{1f}$ and $\vec{v}_{2f}$) so both Pucks move and decelerate under ground Friction until all Pucks stop. When a Puck hits a `CushionBlock`, call an extendable impact function on `CushionBlock` taking `(puck: BasePuck, normal: Vector3)` that computes the rebound velocity change (mass-independent in the normal case: $\vec{v}_{1f} = (1 - f_c)(\vec{v}_1 - (\vec{v}_1 \cdot \hat{n})\hat{n}) - e(\vec{v}_1 \cdot \hat{n})\hat{n}$). If any Puck falls into a Pocket Area during `Puck-puck Time!`, respawn it at the nearest free non-pocket Tile once all Pucks come to rest.

**Blocked by:** 02 — Drag-and-Shot input, straight 3D aiming arrow, impulse launch, and 20 Hz ground friction

**Status:** ready-for-agent

- [ ] Default relative masses (`mass`) and `radius` are set on each Puck type (Boss Monster `3.0`, Knight `2.0`, Warrior `1.5`, Ranger `1.2`, Mage `1.0`)
- [ ] At each 20 Hz velocity update, `PuckVelocityManager` performs a simple swept/overlap collision check between Pucks and against Cushions
- [ ] Colliding Pucks exchange opposite Impulses along the collision normal $\hat{n}$ when approaching ($v_{\text{rel}} < 0$), transferring velocity according to their masses ($\vec{v}_{1f}$ and $\vec{v}_{2f}$)
- [ ] `CushionBlock` exposes an extendable impact function taking `(puck: BasePuck, normal: Vector3)` that rebounds the Puck according to $\vec{v}_{1f} = (1 - f_c)(\vec{v}_1 - (\vec{v}_1 \cdot \hat{n})\hat{n}) - e(\vec{v}_1 \cdot \hat{n})\hat{n}$ (mass-independent in the normal case)
- [ ] All moving Pucks continue colliding and decelerating under ground Friction until every Puck on the Cue Table is at rest
- [ ] Any Puck that falls into a Pocket Area during `Puck-puck Time!` respawns at the nearest unoccupied non-pocket Tile once all Pucks come to rest
- [ ] Automated tests verify Puck–Puck momentum transfer across different masses, `CushionBlock` impact rebound during motion, and pocketed Puck respawn after settle
