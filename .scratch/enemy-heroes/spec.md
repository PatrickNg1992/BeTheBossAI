# Spec: Enemy Heroes

The four Classes, their behaviour, and the collision matrix. Vocabulary per `CONTEXT.md` (Enemy Hero, Class, Puck, Auto-Attack, Collision Damage, Shot Resolution).

## Classes

All classes share the same simple AI (wander / chase / attack) and differ in attack profile, stats and visuals. Auto-Attacks deal damage only — never force.

| Class | Range | Cooldown | Notes |
|---|---|---|---|
| Warrior | short | short | Melee brawler, closes distance aggressively. |
| Knight | short (longer than Warrior) | long | **Auto-Attack is a dash toward the Boss Monster.** Tank. |
| Mage | longest | longest | Ranged caster, keeps distance. |
| Ranger | middle | short | Mobile skirmisher, kites. |

## Collision matrix

Collision Damage applies above a small minimum-speed threshold (value tuned visually).

- Enemy Heroes take Collision Damage from **any** puck impact — except impacts with a Knight: a Knight protects its allies, so heroes colliding with a Knight take none.
- **Only Knight impacts damage the Boss Monster, whoever initiated the collision** — the Knight is a porcupine; ramming one hurts you. The Knight itself still takes Collision Damage like any hero (including mid-dash into the boss: both are damaged).
- Nothing else damages the Boss Monster via collision.
- Minions (future system) follow the same rules as Enemy Heroes, except the Knight protection does NOT extend to them — a Minion colliding with a Knight takes damage.
- Cushion impacts deal no damage. No friendly fire.

## Parked / deferred

- Auto-Attack damage values, Collision Damage value, speed threshold — tune visually in the test scene.
- Equipment and Hero Skills — future concepts, not specified.
- More classes may be added later; record new ones in `CONTEXT.md`.
