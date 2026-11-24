extends McpTestSuite

## Ticket 03 tests:
## - Per-puck ordered Collision History (pucks and cushions collided, cleared at Settle Time)
## - Default collision damage `(J / 10.0) * hitter.POW` with no hardcoded class rules (Boss takes 0 default collision damage; 0.25x friendly fire in 2P PvP)
## - Every non-Boss unit puck (`unit_kind != "boss"`, including Adventurers, Minions, Target Pucks) gains `Hit Level +1` on Cushion collision during `Puck-puck Time!` (Boss pucks do not)
## - Guard's `SPA10001 Protect`:
##   * Reduces opponent Boss Monster's Frenzy Power on hit by `Y% = X * (4% + Lv * 1%)` (counting non-defeated non-Guard-tree teammates in the SAME Adventurer Team, including pocketed teammates, excluding other teams)
##   * Multiplies the reduction by `2` (`+10.0% - 2 * Y%`) when this Guard puck is the very first puck in the Boss Monster's Collision History for that shot, and `1x` (`+10.0% - Y%`) on subsequent collisions
##   * Reduces collision damage on BOTH pucks by `50%` (fixed, not affected by skill Lv, applied at most once per collision even if both colliding pucks have `Protect`) when colliding with a same-team ally
## - Scout's `SPA10003 Safety Rope`:
##   * Reduces Pocket Area fixed damage (`is_fixed = true`, baseline `50%` of `max_hp`) by `-(10 + Lv * 3)%` for units in the SAME Adventurer Team while that Scout is on the cue table
##   * Excludes the falling Scout itself if the Scout falls into a Pocket Area (and excludes pocketed/defeated Scouts or Scouts on a different team)
## - Acolyte's `SPA10004 Chanting`:
##   * Falling into a Pocket Area resets the Acolyte's chanting counter `N` to `0` and recalculates its effective `POW` back to unbuffed base POW

const UNIT_INFO_MANAGER_PATH := "res://src/battlefield/unit_information_manager.gd"
const UNIT_SKILL_MANAGER_PATH := "res://src/battlefield/unit_skill_manager.gd"


func suite_name() -> String:
	return "collision-history-and-passive-skills"


func test_per_puck_collision_history_recording_and_settle_time_clear() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := Node3D.new()
	tree.root.add_child(root)

	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var pvm := PuckVelocityManager.new()
	pvm.timing_manager = tm
	pvm.unit_information_manager = uim
	root.add_child(tm)
	root.add_child(uim)
	root.add_child(usm)
	root.add_child(pvm)
	usm.bind_unit_information_manager(uim)

	var boss := DragonPlayer.new()
	var brawler := EnemyAdventurer.new()
	brawler.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	var minion := BasePuck.new()
	root.add_child(boss)
	root.add_child(brawler)
	root.add_child(minion)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "power": 400, "puck": boss})
	uim.register_minion("minion_1", "a", 1, {"max_hp": 500, "current_hp": 500, "power": 150, "puck": minion})
	uim.register_adventurer_team(1, [
		{"unit_id": "u_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": brawler},
	])

	assert_true(boss.has_method("get_collision_history"), "BasePuck exposes get_collision_history()")
	if not boss.has_method("get_collision_history"):
		tree.root.remove_child(root)
		root.free()
		return

	# 1. Boss collides with Brawler puck -> both record a "puck" entry in collision_history
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	brawler.global_position = Vector3(1.35, 1.675, 0.0)
	boss.velocity = Vector3(6.0, 0.0, 0.0)
	brawler.velocity = Vector3.ZERO
	minion.global_position = Vector3(-10.0, 1.675, -6.0)
	assert_true(pvm.resolve_puck_puck_collision(boss, brawler), "Boss and Brawler collide")

	var boss_hist: Array = boss.get_collision_history()
	var brawler_hist: Array = brawler.get_collision_history()
	assert_eq(boss_hist.size(), 1, "Boss collision history has 1 entry after colliding with Brawler")
	assert_eq(str(boss_hist[0].get("kind", "")), "puck", "First entry kind is 'puck'")
	assert_eq(str(boss_hist[0].get("target_unit_id", "")), "u_brawler", "Boss collision history records target_unit_id 'u_brawler'")
	assert_eq(brawler_hist.size(), 1, "Brawler collision history has 1 entry")
	assert_eq(str(brawler_hist[0].get("target_unit_id", "")), "boss_a", "Brawler collision history records 'boss_a'")

	# 2. Both Brawler AND Minion hit a Cushion -> both record a "cushion" entry AND both non-Boss units gain Hit Level +1 (while Boss does not)
	brawler.global_position = Vector3(14.8, 1.675, 0.0)
	brawler.velocity = Vector3(5.0, 0.0, 0.0)
	minion.global_position = Vector3(-14.8, 1.675, -4.0)
	minion.velocity = Vector3(-5.0, 0.0, 0.0)
	boss.global_position = Vector3(-14.8, 1.8, 4.0)
	boss.velocity = Vector3(-5.0, 0.0, 0.0)
	pvm.step_velocities(0.05, 1.0)

	assert_eq(uim.get_unit("u_brawler").hit_level, 1, "Enemy Adventurer hitting Cushion gains Hit Level +1")
	assert_eq(uim.get_unit("minion_1").hit_level, 1, "Minion (non-Boss puck) hitting Cushion ALSO gains Hit Level +1")
	assert_eq(uim.get_unit("boss_a").hit_level, 0, "Boss Monster puck hitting Cushion does NOT gain Hit Level")
	assert_eq(brawler.get_collision_history().size(), 2, "Brawler collision history now has 2 entries (puck + cushion)")
	assert_eq(str(brawler.get_collision_history()[1].get("kind", "")), "cushion", "2nd entry in Brawler history is 'cushion'")

	# 3. At the end of Settle Time, every puck's collision history is cleared!
	uim.settle_all_damage(true)
	assert_eq(boss.get_collision_history().size(), 0, "Boss collision history cleared at the end of Settle Time")
	assert_eq(brawler.get_collision_history().size(), 0, "Brawler collision history cleared at the end of Settle Time")
	assert_eq(minion.get_collision_history().size(), 0, "Minion collision history cleared at the end of Settle Time")

	tree.root.remove_child(root)
	root.free()


func test_spa10001_protect_first_hit_2x_frenzy_reduction_same_team_count_and_50_pct_ally_collision_damage() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := Node3D.new()
	tree.root.add_child(root)

	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var pvm := PuckVelocityManager.new()
	pvm.timing_manager = tm
	pvm.unit_information_manager = uim
	root.add_child(tm)
	root.add_child(uim)
	root.add_child(usm)
	root.add_child(pvm)
	usm.bind_unit_information_manager(uim)

	var boss := DragonPlayer.new()
	var guard1 := EnemyAdventurer.new()
	guard1.adventurer_class = EnemyAdventurer.AdventurerClass.GUARD
	var guard2 := EnemyAdventurer.new()
	guard2.adventurer_class = EnemyAdventurer.AdventurerClass.GUARD
	var brawler := EnemyAdventurer.new()
	brawler.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	var scout := EnemyAdventurer.new()
	scout.adventurer_class = EnemyAdventurer.AdventurerClass.SCOUT
	var acolyte := EnemyAdventurer.new()
	acolyte.adventurer_class = EnemyAdventurer.AdventurerClass.ACOLYTE
	var team2_brawler := EnemyAdventurer.new()
	team2_brawler.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	for p in [boss, guard1, guard2, brawler, scout, acolyte, team2_brawler]:
		root.add_child(p)
		p.global_position = Vector3(-12.0, 1.7, -8.0)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "power": 400, "frenzy_power": 1.50, "puck": boss})
	# Team 1 has: 2 Guards (guard1, guard2) + 3 non-Guard teammates (brawler, scout, acolyte)
	uim.register_adventurer_team(1, [
		{"unit_id": "t1_guard1", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": guard1},
		{"unit_id": "t1_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": brawler},
		{"unit_id": "t1_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT, "puck": scout},
		{"unit_id": "t1_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE, "puck": acolyte},
		{"unit_id": "t1_guard2", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": guard2},
	])
	# Team 2 has 1 Brawler (must NOT be counted in Team 1 Guard's Protect ?X!)
	uim.register_adventurer_team(2, [
		{"unit_id": "t2_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": team2_brawler},
	])

	# Pocket t1_scout -> pocketed non-defeated teammates in the same team STILL count for SPA10001 Protect!
	uim.set_unit_pocketed("t1_scout", true)
	# So for t1_guard1 (Protect Lv 1):
	#   ?X = 3 non-defeated non-Guard teammates in Team 1 (t1_brawler, t1_scout [pocketed], t1_acolyte)
	#   ?Y = 3 * (4 + 1*1) = 15% (0.15)
	#   - If t1_guard1 is the FIRST puck Boss hits in the shot: net Frenzy delta = +10% - 2 * 15% = -20% (1.50 -> 1.30)
	#   - On a SUBSEQUENT hit on t1_guard1 in the same shot: net Frenzy delta = +10% - 1 * 15% = -5% (1.30 -> 1.25)

	# 1. Very first puck Boss hits in this shot is t1_guard1 -> 2x reduction (-30% + 10% = -20% -> 1.50 to 1.30)
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	guard1.global_position = Vector3(1.40, 1.7, 0.0)
	boss.velocity = Vector3(6.0, 0.0, 0.0)
	guard1.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(boss, guard1), "Boss hits Guard 1 as very first puck in shot")
	var boss_do := uim.get_unit("boss_a")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.30),
		"First-hit Guard Protect (X=3, Y=15%%) applies +10%% - 2*15%% = -20%% (150%% -> 130%%, got %.2f)" % boss_do.frenzy_power)

	# 2. Second collision in the SAME shot with t1_guard1 -> 1x reduction (-15% + 10% = -5% -> 1.30 to 1.25)
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	guard1.global_position = Vector3(1.40, 1.7, 0.0)
	boss.velocity = Vector3(6.0, 0.0, 0.0)
	guard1.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(boss, guard1), "Boss hits Guard 1 a second time in the same shot")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.25),
		"Subsequent Guard Protect hit applies +10%% - 15%% = -5%% (130%% -> 125%%, got %.2f)" % boss_do.frenzy_power)

	# 3. Defeat t1_acolyte -> now X = 2 non-defeated non-Guard teammates (t1_brawler, t1_scout) -> Y = 2 * 5% = 10%
	#    On a subsequent hit: +10% - 10% = 0% change (stays 1.25)!
	uim.get_unit("t1_acolyte").is_dead = true
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	guard1.global_position = Vector3(1.40, 1.7, 0.0)
	boss.velocity = Vector3(6.0, 0.0, 0.0)
	guard1.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(boss, guard1), "Boss hits Guard 1 after Acolyte is defeated (X=2, Y=10%)")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.25),
		"Defeated teammate is excluded from Protect X (X=2 -> +10%% - 10%% = 0%% net change, stays 125%%)")

	# 4. Same-team ally collision damage reduction (-50% fixed on BOTH pucks, applied at most ONCE even when two Guards collide!):
	uim.settle_all_damage(true) # Clear damage stacks
	guard1.global_position = Vector3(-12.0, 1.7, -8.0)

	# (a) Guard 1 collides with same-team Brawler: both take 50% of `(J / 40) * hitter.POW`!
	#     At Lv 5, Guard mass=1.75, POW=280; Brawler mass=1.50, POW=280; restitution=0.85, closing speed=6.0:
	#     J = (1 + 0.85) * 6.0 / (1/1.75 + 1/1.50) = 11.1 / 1.238095 = 8.96538
	#     Unreduced damage = (8.96538 / 40.0) * 280 = 62.758; with -50% Protect reduction = 31.379!
	guard1.global_position = Vector3(0.0, 1.7, 0.0)
	brawler.global_position = Vector3(1.20, 1.675, 0.0)
	guard1.velocity = Vector3(6.0, 0.0, 0.0)
	brawler.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(guard1, brawler), "Guard 1 and same-team Brawler collide")
	var g1_dmg := uim.get_unit("t1_guard1").damage_stack[0].value
	var br_dmg := uim.get_unit("t1_brawler").damage_stack[0].value
	var expected_j := (1.0 + 0.85) * 6.0 / ((1.0 / 1.75) + (1.0 / 1.50))
	var expected_half_dmg := ((expected_j / PhysicsConstant.COLLISION_DAMAGE_IMPULSE_DIVISOR) * 280.0) * 0.50
	assert_true(absf(g1_dmg - expected_half_dmg) < 0.5, "Guard 1 takes 50%% reduced collision damage from same-team Brawler (got %.2f vs %.2f)" % [g1_dmg, expected_half_dmg])
	assert_true(absf(br_dmg - expected_half_dmg) < 0.5, "Same-team Brawler ALSO takes 50%% reduced collision damage from Guard 1 (got %.2f vs %.2f)" % [br_dmg, expected_half_dmg])

	# (b) Guard 1 collides with same-team Guard 2 (BOTH have SPA10001 Protect):
	#     The -50% reduction applies only ONCE (0.50x), NOT twice (0.25x or 0x)!
	uim.settle_all_damage(true)
	brawler.global_position = Vector3(-12.0, 1.675, -8.0)
	guard1.global_position = Vector3(0.0, 1.7, 0.0)
	guard2.global_position = Vector3(1.25, 1.7, 0.0)
	guard1.velocity = Vector3(6.0, 0.0, 0.0)
	guard2.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(guard1, guard2), "Guard 1 and same-team Guard 2 collide")
	var g2_dmg := uim.get_unit("t1_guard2").damage_stack[0].value
	var expected_j_gg := (1.0 + 0.85) * 6.0 / ((1.0 / 1.75) + (1.0 / 1.75))
	var expected_half_gg := ((expected_j_gg / PhysicsConstant.COLLISION_DAMAGE_IMPULSE_DIVISOR) * 280.0) * 0.50
	assert_true(absf(g2_dmg - expected_half_gg) < 0.5,
		"Two same-team Guards colliding apply -50%% reduction only ONCE (0.5x = %.2f, got %.2f)" % [expected_half_gg, g2_dmg])

	# (c) Guard 1 (Team 1) collides with Team 2 Brawler (different team!):
	#     No Protect reduction -> full 1.0x collision damage!
	uim.settle_all_damage(true)
	guard2.global_position = Vector3(-12.0, 1.7, -8.0)
	guard1.global_position = Vector3(0.0, 1.7, 0.0)
	team2_brawler.global_position = Vector3(1.20, 1.675, 0.0)
	guard1.velocity = Vector3(6.0, 0.0, 0.0)
	team2_brawler.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(guard1, team2_brawler), "Team 1 Guard and Team 2 Brawler collide")
	var t2_dmg := uim.get_unit("t2_brawler").damage_stack[0].value
	assert_true(absf(t2_dmg - expected_half_dmg * 2.0) < 0.5,
		"Different-team collision receives full 100%% collision damage (%.2f)" % t2_dmg)

	tree.root.remove_child(root)
	root.free()


func test_spa10003_safety_rope_on_table_same_team_pocket_damage_and_spa10004_chanting_pocket_reset() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	tree.root.add_child(uim)
	tree.root.add_child(usm)
	usm.bind_unit_information_manager(uim)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	# Register Team 1 with:
	# - Guard (max_hp = 3500)
	# - Scout 1 (SPA10003 Safety Rope Lv 1 -> -13% Pocket Area damage)
	# - Acolyte (SPA10004 Chanting Lv 1 -> +10% POW per chant stack; base_power = 280)
	uim.register_adventurer_team(1, [
		{"unit_id": "t1_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD},
		{"unit_id": "t1_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
		{"unit_id": "t1_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
	])
	# Register Team 2 with a Scout (must NOT reduce Team 1's pocket damage!)
	uim.register_adventurer_team(2, [
		{"unit_id": "t2_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
	])

	# 1. Team 1 Guard falls into a Pocket Area while Team 1 Scout (Lv 1 Safety Rope -> -13%) is on the cue table:
	#    Pocket damage % = 50% - 13% = 37% of 3500 = ceil(3500 * 0.37) = 1295 fixed damage!
	var guard_pocket_dmg: DamageDO = uim.push_pocket_fall_damage("t1_guard")
	assert_true(guard_pocket_dmg != null and guard_pocket_dmg.is_fixed, "Pocket fall creates fixed DamageDO")
	assert_eq(int(guard_pocket_dmg.value), 1295,
		"On-table same-team Scout (Safety Rope Lv 1: -13%%) reduces Guard pocket damage from 50%% (1750) to 37%% (1295)")

	# 2. Now Team 1 Scout ITSELF falls into a Pocket Area:
	#    Because the falling Scout is no longer on the cue table when its pocket damage is calculated
	#    (and Team 2's Scout is on a different team), Team 1 Scout takes the full 50% of 2800 = 1400 fixed damage!
	var scout_pocket_dmg: DamageDO = uim.push_pocket_fall_damage("t1_scout")
	assert_eq(int(scout_pocket_dmg.value), 1400,
		"When the Scout itself falls into a pocket, its own Safety Rope does not count (takes full 50%% of 2800 = 1400)")

	# 3. Acolyte with SPA10004 Chanting (Lv 1) has built up counter N = 2 (+20% POW -> 280 * 1.20 = 336 POW):
	#    When the Acolyte falls into a Pocket Area, its Chanting counter N resets to 0 and its POW recalculates back to 280!
	var acolyte_do := uim.get_unit("t1_acolyte")
	var chanting_sk: UnitSkill = usm.get_unit_passive_skills("t1_acolyte")[0]
	chanting_sk.counter = 2
	usm.apply_stat_modifier(acolyte_do, "SPA10004_chanting", "power", 0.20, 0)
	assert_eq(acolyte_do.power, 336, "Acolyte with N=2 Chanting has 336 POW before falling into pocket")

	uim.push_pocket_fall_damage("t1_acolyte")
	assert_eq(chanting_sk.counter, 0, "Falling into a Pocket Area resets Acolyte's SPA10004 Chanting counter N to 0")
	assert_eq(acolyte_do.power, 280, "Falling into a Pocket Area removes Chanting POW buff and restores base POW 280")

	tree.root.remove_child(usm)
	tree.root.remove_child(uim)
	usm.free()
	uim.free()
