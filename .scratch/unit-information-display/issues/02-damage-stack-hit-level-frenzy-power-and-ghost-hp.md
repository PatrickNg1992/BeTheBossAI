# 02 — Damage Stack, Hit Level, Frenzy Power & Ghost HP Trailing Pipeline

**What to build:** The end-to-end staged damage calculation and visual feedback pipeline across **Unit Information Manager** and **Unit Display**: accumulating `DamageDO` entries in each unit's **Damage Stack** during `Puck-puck Time!` and `Action Time`, rendering the shaking **Damage Stack** hit-count circle badge and **Impulse**-proportional **Unit Display** collision shake, tracking per-unit **Hit Level** and per-Boss **Frenzy Power**, displaying pre-settle **Ghost HP** trailing (`(Sum of Damage Stack) * 1.1^(Hit Level)`), and resolving damage at `Settle Time` (including per-`DamageDO` source Boss Frenzy Power on Enemy Adventurers, the strict 1-Health-Bar-per-Settle cap on all Boss Monsters, and post-Settle reset/decay).

**Blocked by:** 01 — Unit Information Board 2×8 Grid, Reference Marks & Colour Coding

**Status:** completed

- [x] Whenever any unit (Boss Monster, Minion, or Enemy Adventurer) takes damage from collisions, effects, or projectiles during `Puck-puck Time!` or `Action Time`, a `DamageDO` (`source_unit_id`, `owner_boss_unit_id`, `value`, `damage_type`) is appended in time order to that unit's **Damage Stack** (including damage routed from any of the unit's `0..N` active pucks).
- [x] On the left of each unit's HP bar, a small circle badge displays the unit's current **Damage Stack** hit count; it is invisible when the count is `0`, appears with the count when `> 0`, and shakes briefly whenever the unit takes damage (with a harder hit producing a larger shake).
- [x] During `Puck-puck Time!`, when a unit's puck collides on the Cue Table, its **Unit Display** shakes to a degree proportional to the **Impulse** received.
- [x] Every unit holds an integer **Hit Level** (default `0`, adjustable up or down by conditional effects such as hitting a Focusing puck, special cushions, or type effectiveness) that scales damage exponentially by `1.1^(Hit Level)`.
- [x] Only Boss Monsters hold **Frenzy Power** (baseline `100%`, minimum floor `50%`, displayed on the right side of each Boss Monster's 2-cell Unit Display); a Boss Monster colliding with a non-Knight Enemy Adventurer puck increases its Frenzy Power by `+10%` (default), and colliding with a Knight puck decreases its Frenzy Power by `-20%` (default) clamped to at least `50%`.
- [x] Before `Settle Time`, each unit's **Ghost HP** bar (HP trailing) on its **Unit Display** previews pending damage from **Damage Stack** and **Hit Level** only (`round(sum(Damage Stack) * 1.1^(Hit Level))`), excluding **Frenzy Power** and clamping at `0` of the active Health Bar.
- [x] When `Settle Time` resolves damage:
  - A visual effect triggers to spread **Frenzy Power** to opposing Enemy Adventurers' HP bars.
  - Each Enemy Adventurer takes settled damage equal to `round(sum_i(Damage_i * Frenzy(SourceBoss_i)) * 1.1^(Hit Level))` (where `Frenzy(SourceBoss_i)` defaults to `100%` if a `DamageDO` has no Boss Monster source).
  - Each Boss Monster and Minion takes settled damage equal to `round(sum(Damage Stack) * 1.1^(Hit Level))`.
- [x] Every Boss Monster in every `Settle Time` is strictly capped at losing at most **1 Health Bar**: if settled damage reaches or exceeds its current Health Bar's remaining HP, the active Health Bar clears (`bars_remaining` decrements by `1` and HP refills to `100%` of the next bar if `bars_remaining > 0`, or the Boss Monster is defeated if `bars_remaining == 0`) and all excess damage is discarded.
- [x] Immediately after `Settle Time` damage settlement, every unit's **Damage Stack** is cleared, every unit's **Hit Level** resets to `0`, and every Boss Monster's **Frenzy Power** decays via `new_frenzy = (current_frenzy / 2) + 50%` (pulling values either above or below `100%` halfway toward `100%`).
- [x] Automated unit and view tests verify `Damage Stack` count badge visibility, pre-settle Ghost HP calculation, per-source Boss Frenzy Power settlement in 1-player and 2-player co-op, the Boss Monster 1-Health-Bar-per-Settle cap, and post-Settle `Hit Level` reset and `Frenzy Power` decay.
