# Units as pucks on a cue table

Every unit — Boss Monster, Enemy Heroes, future Minions — is a physics-driven puck on a cue-table battlefield, not a free-moving RPG character. Movement, knockback, pockets and chain collisions all come out of the physics simulation; the player intervenes through the Cue-Shot and force-effect cards. Combat damage flows through two explicit channels: Auto-Attacks (damage only, never force) and Collision Damage (an explicit matrix — only Knight impacts hurt the Boss Monster).

We chose this over conventional steer-and-swing units because chain-collision play — knocking Enemy Heroes into each other and into Pocket Areas — is the core fantasy ("snooker with cards"). It is hard to reverse: movement, combat, cards and the battlefield all hang off the physics spine.

## Considered Options

- **Free-moving RPG units with scripted attack animations** — rejected: loses the chain-collision fantasy, which is the game's reason to exist.
- **Collision-only combat (no Auto-Attacks)** — rejected: leaves the player with nothing to do between Cue-Shots and makes Enemy Heroes inert; both coexist.

## Consequences

- AI steering applies forces to pucks; it never teleports units or animates position directly. *(Amended by ADR-0002: hero move actions are scripted glides; physics runs only in Puck-puck Time.)*
- The collision matrix (who damages whom) is a design artifact, not an emergent accident — the Knight exceptions are deliberate; see `CONTEXT.md`.
- The Cue-Shot rest rule and Shot Resolution freeze exist to keep physics readable: nothing acts while the table is moving.
