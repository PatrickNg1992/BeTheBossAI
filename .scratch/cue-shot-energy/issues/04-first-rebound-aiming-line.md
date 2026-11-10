# 04 — 3D first-rebound and struck-puck aiming line preview

**What to build:** Upgrade the 3D aiming line with swept Boss-radius collision prediction and first-rebound arrows. While dragging, sweep the Boss Monster's cylinder radius $R_{\text{boss}}$ along the shot direction up to the Impulse-proportional reach distance. When a Cushion or another Puck lies within that reach, stop the primary aiming line at the contact center, render a 3D ghost contact ring of radius $R_{\text{boss}}$, and draw the Boss Monster's first-rebound arrow along $\vec{v}_{1f}$. When the first hit is another Puck, also draw a contrasting 3D arrow from the struck Puck's center along its post-impact velocity $\vec{v}_{2f}$. Scale both post-hit arrow lengths proportionally to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$ computed from the collision equations in ticket `03`, and colour all aiming visuals red when inside the deadzone or over-dragged.

**Blocked by:** 03 — Puck–Puck and Puck–Cushion collision physics and pocket respawn

**Status:** ready-for-agent

- [ ] When no Cushion or Puck lies within the Impulse-proportional reach, only the primary 3D aiming arrow is shown
- [ ] Swept collision detection accounts for the Boss Monster's radius $R_{\text{boss}}$ against both Cushion inner planes and other Pucks' radii
- [ ] When a Cushion or Puck is hit within reach, a ghost contact ring of radius $R_{\text{boss}}$ renders at the impact point along with the Boss Monster's first-rebound arrow ($\vec{v}_{1f}$)
- [ ] When the first hit is another Puck, a second arrow in a contrasting colour renders from the struck Puck's center along its outgoing velocity ($\vec{v}_{2f}$)
- [ ] Post-hit arrow lengths scale proportionally to $\|\vec{v}_{1f}\|$ and $\|\vec{v}_{2f}\|$ from the Puck–Puck and Puck–Cushion collision equations
- [ ] All aiming line segments and the contact ring turn red when inside the cancel deadzone or over-dragged
- [ ] Automated tests verify swept first-hit contact points and post-hit preview vectors ($\vec{v}_{1f}, \vec{v}_{2f}$) against both a Cushion and an Enemy Adventurer Puck
