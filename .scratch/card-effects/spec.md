# Spec: Card Effects

How cards behave once played. Vocabulary per `CONTEXT.md` (Deck, Hand, Casting Area, Discard Pile, Preparation Phase).

## Card flow

- Deck of 52: 13 each of Environment, Monster Skill, Summoner, Minion. Order hidden, reshuffled every Preparation Phase.
- Hand max 10. A draw attempted at 10 is skipped, with a notification animation.
- Playing a card: select in Hand, click a target position on the Cue Table. Played card moves to the Casting Area (holds 1 card), then to the Discard Pile when its cooldown ends.
- Casting Area occupied → playing is blocked; clicking the table with a card selected shows an error. Re-selecting cards in Hand is always allowed.
- Discard Pile is ordered and inspectable via its icon.

## Draw triggers

| Trigger | Cards |
|---|---|
| Preparation Phase (fresh hand) | 5 |
| Enemy Adventurer defeated | 1 |
| Boss Monster Health Bar cleared | 1 |
| Card/skill draw effects | per card (deferred) |

## Demo card effects (in scope)

All three have a cooldown for simplicity. Persistent no-CD cards are a future plan; none are designed.

- **Rush**: apply force to the Boss Monster toward the clicked position.
- **Teleport**: move the Boss Monster to the clicked position.
- **Recover**: heal 20% of one Boss Monster Health Bar. Boss-only for now; extends to Minions once the Minion system exists.

## Parked / deferred

- Buff/Debuff, Attack, Interrupt, Draw Cards, Summon effects — params TBD when designed.
- Cooldown durations for the demo cards — tune visually.
