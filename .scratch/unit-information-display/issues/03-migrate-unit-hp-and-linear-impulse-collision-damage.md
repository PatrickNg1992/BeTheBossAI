# 03 — Migrate Unit HP/Stats to Unit Information, Scale Adventurer HP & Wire Linear Impulse Collision Damage

**What to build:** Move unit combat state (`current_hp`, `max_hp`, `bars_remaining`, `power`, and defeated status) out of the puck physics scripts (`BasePuck`, `BaseBossMonster`, `EnemyAdventurer`) into `UnitInformationDO` inside **Unit Information Manager** (leaving puck scripts with physics state only: `radius`, `mass`, `restitution`, `position`, `velocity`, `rotation`), scale Enemy Adventurer default HP to the thousands level (**Mage = 1500**, **Warrior = 2200**, **Ranger = 2200**, **Knight = 3000**), and wire `PuckVelocityManager` collision resolution so puck–puck impacts during `Puck-puck Time!` push `DamageDO` records linearly proportional to the collision **Impulse** (`~50–200` damage per collision based on hitting velocity) onto the **Damage Stack** and update Boss Monster **Frenzy Power**.

**Blocked by:** 02 — Damage Stack, Hit Level, Frenzy Power & Ghost HP Trailing Pipeline

**Status:** completed

- [x] `current_hp`, `max_hp`, `bars_remaining`, `attack_damage`, and damage/death state are moved from the puck scripts (`BasePuck`, `BaseBossMonster`, `EnemyAdventurer`) into `UnitInformationDO` managed by **Unit Information Manager**, leaving the puck scripts responsible only for physics properties (`radius`, `mass`, `restitution`, `position`, `velocity`, `rotation`, and pocket-fall physics) and a link to their owning unit.
- [x] Default Enemy Adventurer max HP values are scaled to the thousands level: **Mage = 1500**, **Warrior = 2200**, **Ranger = 2200**, and **Knight = 3000**.
- [x] When two pucks collide in `PuckVelocityManager.resolve_puck_puck_collision(p1, p2)`, after computing the collision **Impulse** scalar `J`, `PuckVelocityManager` calculates collision damage linearly from `J` (tuned so typical impacts deal approximately `50 ~ 200` damage depending on hitting velocity).
- [x] Collision damage in `PuckVelocityManager` enforces the collision matrix and pushes `DamageDO` records (`source_unit_id`, `owner_boss_unit_id`, `value`, `damage_type = "collision"`) onto the affected unit's **Damage Stack** in **Unit Information Manager**:
  - Enemy Adventurers take collision damage from any impact above the speed threshold, except impacts with an allied Knight puck.
  - Boss Monsters only take collision damage when colliding with a Knight puck.
- [x] When a Boss Monster puck collides with a non-Knight Enemy Adventurer puck in `PuckVelocityManager`, that Boss Monster's **Frenzy Power** increases by `+10%`; when colliding with a Knight puck, its **Frenzy Power** decreases by `-20%` (clamped to the `50%` floor).
- [x] Each collision in `PuckVelocityManager` notifies **Unit Information Manager** with the collision **Impulse** so the affected units' **Unit Displays** and **Damage Stack** count badges shake proportionally.
- [x] Automated tests verify that unit HP/stats live authoritatively in `UnitInformationDO` (with Mage 1500, Warrior 2200, Ranger 2200, Knight 3000), that `PuckVelocityManager` collisions generate linear Impulse-based `DamageDO` entries (~50–200 range) on the **Damage Stack**, respect Knight collision rules, adjust Boss **Frenzy Power**, and settle cleanly at `Settle Time`.
