# Hybrid movement: scripted adventurer moves, physics only for Puck-puck Time

Physics simulation runs only during Puck-puck Time (player Cue-Shots, any unit skill that explicitly launches a self Cue-Shot, force-effect cards). An adventurer's own move action is a scripted constant-speed glide with physics disabled: it may pass through other pucks and Pocket Areas mid-glide, but it must never come to rest on a pocket or overlapping another puck, and it runs fast so Action Time stays snappy. This amends ADR-0001's consequence "AI steering applies forces to pucks; it never teleports or animates position directly."

We chose scripted glides because approach movement needs no collision response, destination rules are cheaper to tune than steering forces, and Action Time duration stays bounded regardless of table state. The core of ADR-0001 is untouched: units are still physics pucks, and knockback/pockets/chain collisions still emerge from simulation — but only in the dedicated physics window.

## Considered Options

- **Physics forces for all AI movement** (ADR-0001's original consequence) — rejected: needs collision handling for glides, makes Action Time duration depend on physics settling, and buys nothing the glide can't do.
- **Free continuous movement** — rejected in ADR-0001 already.

## Consequences

- The two damage channels stay cleanly separated and total: **Auto-Attacks / Attack Skills** are scripted damage events with a simple animation in Action Time and never apply force; **Collision Damage** exists only inside Puck-puck Time. Only a skill that explicitly launches a self Cue-Shot enters physics.
- Move pathing needs only destination rules (never rest on a pocket, keep separation between pucks at rest), not obstacle avoidance.
- Every puck has two movement modes — scripted glide for its own actions, physics when impacted — and the code must keep them cleanly separated.
