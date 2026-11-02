# 03 — Puck–Puck and Puck–Cushion collision physics and pocket respawn

**What to build:** Full `Puck-puck Time!` collision physics on the Cue Table. Configure relative masses per Puck (Boss Monster `3.0`, Knight `2.0`, Warrior `1.5`, Ranger `1.2`, Mage `1.0`). When a moving Puck collides with another Puck, resolve the impact using the 4-step classical impulse equations ($\hat{n} = (\vec{p}_1 - \vec{p}_2)/\|\vec{p}_1 - \vec{p}_2\|$, $v_{\text{rel}} = (\vec{v}_1 - \vec{v}_2)\cdot\hat{n}$, $J = -(1+e)v_{\text{rel}} / (1/m_1 + 1/m_2)$, updating both $\vec{v}_{1f}$ and $\vec{v}_{2f}$) so both Pucks move and decelerate under Friction until all Pucks stop. When a moving Puck collides with a Cushion, resolve the rebound using the perpendicular restitution ($e$) and parallel Cushion friction ($f_c$) equation. If any Puck falls into a Pocket Area during `Puck-puck Time!`, respawn it at the nearest free non-pocket Tile once all Pucks come to rest.

**Blocked by:** 02 — Drag-and-Shot input, straight 3D aiming arrow, impulse launch, and friction

**Status:** ready-for-agent

- [ ] Default relative masses are set on each Puck type (Boss Monster `3.0`, Knight `2.0`, Warrior `1.5`, Ranger `1.2`, Mage `1.0`)
- [ ] Colliding Pucks exchange opposite Impulses along the collision normal $\hat{n}$ when approaching ($v_{\text{rel}} < 0$), transferring velocity according to their masses ($\vec{v}_{1f}$ and $\vec{v}_{2f}$)
- [ ] Pucks colliding with a Cushion rebound according to $\vec{v}_{1f} = (1 - f_c)(\vec{v}_1 - (\vec{v}_1 \cdot \hat{n})\hat{n}) - e(\vec{v}_1 \cdot \hat{n})\hat{n}$
- [ ] All moving Pucks continue colliding and decelerating under constant Friction until every Puck on the Cue Table is at rest
- [ ] Any Puck that falls into a Pocket Area during `Puck-puck Time!` respawns at the nearest unoccupied non-pocket Tile once all Pucks come to rest
- [ ] Automated tests verify Puck–Puck momentum transfer across different masses, Puck–Cushion rebound during motion, and pocketed Puck respawn after settle
