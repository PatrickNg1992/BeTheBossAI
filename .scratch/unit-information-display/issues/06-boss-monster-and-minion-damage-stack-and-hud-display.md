# 06 — Boss Monster & Minion Damage Stack, Ghost HP Trail, and Upper-Left HUD Integration

**What to build:** Complete the **Damage Stack**, blood-red **Ghost HP** trail, gradual green-to-greenish-yellow HP fill, hit-count badge, and large settled negative HP change display (`-567`) for **Boss Monsters** and **Minions** across both the **Unit Information Board** (`L1`, `L2–L4`, `L5`, `L6–L8`, `R1`, `R2–R4`) and the local seated player's upper-left Boss Monster HUD panel.

**Blocked by:** 02 — Damage Stack, Hit Level, Frenzy Power & Ghost HP Trailing Pipeline, 03 — Migrate Unit HP/Stats to Unit Information, Scale Adventurer HP & Wire Linear Impulse Collision Damage

**Status:** ready-for-agent

- [ ] When the local seated player's **Boss Monster** (shown in the upper-left screen HUD) takes staged damage during `Puck-puck Time!` or `Action Time` (such as colliding with a Knight puck, enemy attacks, or falling into a Pocket Area), the upper-left Boss Monster HUD displays:
  - A **Damage Stack** hit-count badge on the left of the Boss HP bar (with a large, smart count number and subtle circle background, invisible when count is `0`, shaking proportionally on each hit).
  - A blood-red **Ghost HP** trail (`(Sum of Damage Stack) * 1.1^(Hit Level)`, clamped at `0` of the active Health Bar) against a green-to-greenish-yellow remaining HP fill.
  - A large settled negative HP change number (e.g. `-567`) when `Settle Time` resolves the Boss Monster's Damage Stack (capped at clearing at most 1 Health Bar per Settle Phase).
- [ ] For any non-local **Boss Monster** rendered with an HP bar inside its 2-cell **Unit Display** (`L5` in 2-Player Co-op, `L1`/`R1` in 2-Player Versus, or when viewed by the other seat), its 2-cell **Unit Display** shows the same **Damage Stack** hit-count badge, blood-red **Ghost HP** trail, `x N` Health Bar count, and large settled negative HP change number (`-567`).
- [ ] When any **Minion** (`ω1..ω6`, `ψ1..ψ6` in `L2–L4`, `L6–L8`, `R2–R4`) takes damage from collisions, enemy attacks, or Pocket Area falls during `Puck-puck Time!` or `Action Time`, its `DamageDO` entries accumulate in its `UnitInformationDO.damage_stack`, its **Unit Display** shows the shaking **Damage Stack** hit-count badge and blood-red **Ghost HP** trail (`(Sum of Damage Stack) * 1.1^(Hit Level)`), and at `Settle Time` its damage settles with the large `-567` HP change popup and defeat check.
- [ ] Automated tests verify Boss Monster and Minion `Damage Stack` accumulation, upper-left Boss HUD and 2-cell Unit Display Damage Stack badge & blood-red Ghost HP synchronization, Minion collision/pocket damage staging and settlement, and settled `-567` HP change display.
