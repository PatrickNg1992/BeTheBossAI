# 05 — Hover Puck Highlighting & Click-to-Inspect Unit Detail Display Popup

**What to build:** Interactive mouse hover and click inspection on the **Unit Information Board**: hovering a **Unit Display** highlights all `0..N` active pucks belonging to that unit on the 3D Cue Table, and clicking a **Unit Display** opens the **Unit Detail Display** popup showing the unit's full localized stats, numeric HP bar, puck physics properties, skills, and status conditions (closing when clicking elsewhere or re-clicking the same cell).

**Blocked by:** 03 — Migrate Unit HP/Stats to Unit Information, Scale Adventurer HP & Wire Linear Impulse Collision Damage, 04 — Action Tag Turn Countdowns, Defeated & Pocketed Unit Display States, and Skill Popups

**Status:** completed

- [x] Hovering the mouse over a **Unit Display** highlights all `0..N` active Pucks linked to that unit on the Cue Table so the player can easily spot them; moving the mouse away removes the highlight.
- [x] Clicking on a **Unit Display** opens the **Unit Detail Display** popup alongside the board for that unit (hovering alone does not open it).
- [x] Clicking anywhere outside the **Unit Detail Display** (or clicking the same **Unit Display** again) closes the **Unit Detail Display**; clicking a different **Unit Display** switches the popup to inspect the newly clicked unit.
- [x] The **Unit Detail Display** shows:
  - Unit name
  - Detailed Class name and Class Mark icon (if the unit is an Enemy Adventurer)
  - HP bar displaying the numeric `HP / Max HP` value (plus remaining Health Bar count if the unit is a Boss Monster)
  - Attack power of the unit
  - Mass and radius of the unit's puck
  - Skills of the unit
  - Special condition of the unit (e.g. Focusing, Pocketed + return turns, Stunned/Recovering)
  - Unit's active statuses (buffs, debuffs, conditional statuses), current **Hit Level**, and **Frenzy Power** (for Boss Monsters)
- [x] All display labels and status texts in the **Unit Detail Display** are sourced from the multi-language localization holder.
- [x] Automated tests verify hover-to-highlight across single-puck, multi-puck, and zero-puck (pocketed/defeated) units, click-to-open and outside-click-to-close transitions, and accurate rendering of live unit stats and numeric `HP / Max HP` in the **Unit Detail Display**; implementation pauses for human UI verification of the popup layout.
