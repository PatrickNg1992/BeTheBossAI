# Spec: Stage / Wave Loop

The battle structure. Vocabulary per `CONTEXT.md` (Stage) and `.docs/contexts/battlefield.md` (Wave, Adventurer Team, Preparation Phase, Start Wave).

## Demo scope

One Stage of 5 Waves. All Adventurer Team compositions are rolled once, when the Stage begins.

## Adventurer Team composition

- Wave sizes: 4 / 6 / 7 / 8 / 10 (designed escalation; counts may be tuned).
- Every Wave contains at least one puck of **each** Class (Warrior, Knight, Mage, Ranger).
- Remaining slots: fully random, uniform class pick.
- Spawn positions: random Tiles along the four Cushions.

## Flow

1. Stage begins in a Preparation Phase.
2. Preparation Phase:
   - The coming Wave's Adventurer Team stands inert at its spawn Tiles (preview only — pucks do not act).
   - All cards (Hand, Casting Area, Discard Pile) return to the Deck, which is reshuffled; the player draws a fresh hand of 5.
   - No boss movement. No card play. Energy does not regenerate; when the phase ends, the player's Energy is set to exactly 10.
   - The player presses **Start Wave** to end the phase; the previewed Adventurer Team activates.
3. Wave runs until every Enemy Adventurer is defeated → Preparation Phase of the next Wave.
4. Boss Monster defeated → game over. Final Wave cleared → Stage won.

## Parked / deferred

- Richer Preparation Phase mechanics (repositioning, card play, shop, etc.) — explicitly future work; the simple version above ships first.
- Random composition for future Stages may get weights/curves per Stage.
