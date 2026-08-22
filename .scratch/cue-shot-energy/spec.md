# Spec: Cue-Shot & Energy

The player's basic action and its resource. Vocabulary per `.docs/contexts/battlefield.md` (Cue-Shot, Energy, Puck-puck Time!, Puck).

## Energy

- Bar displayed at the top of the screen.
- Capacity 20. Regenerates one slot at a time during Charging Time; the per-slot charge time is configurable (default 1s).
- A Cue-Shot costs 1–7 Energy. No free shots — minimum cost 1.

## Firing a Cue-Shot

- Drag to aim, release to fire. Power is proportional to drag length, capped by current Energy.
- Force applied to the Boss Monster ∝ (1 + Energy consumed).
- Deceleration on the table is constant, so max travel distance ∝ force².
- **Rest rule**: a Cue-Shot is allowed only when every puck on the table is at rest.

## Puck-puck Time!

From the shot until all pucks stop:

- Every Auto-Attack and AI behaviour (all pucks, both sides) is frozen.
- Only the physics simulation runs.

## Parked / deferred

- Base force scale, drag-to-power mapping, deceleration value, speed-threshold for "at rest" — tune visually in the test scene.
