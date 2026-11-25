extends McpTestSuite

## Ticket 04 & 05 tests (also covering timing-system/03 & 04):
## - AutoFightManager & PresentationManager:
##   * ON_ACTION_TIME_START: on-table acting Acolytes increment SPA10004 Chanting counter N by +1 and recalculate POW (+N * (7.5 + Lv * 2.5)%), while pocketed Acolytes returning on that turn skip the increment
##   * Three-Phase SPD-ordered execution across acting units: All Active Skills -> All Attack Skills -> All Move Skills (ordered within each phase by unit SPD descending, tie-broken by game order; at Lv 5: Brawler 160 > Scout 145 > Acolyte 140 > Guard 125)
##   * Skill Countdown gating & reset: Lance (9) and Spell Attack (12) start at full countdown at wave start, tick down by 1 per Turn, and reset ONLY when their conditions are met and they activate
##   * Base Attack Skills (SAA10001..10004): edge-to-edge range for Lance (3.5) and Melee (1.5), centre-to-centre range for Shoot (7.5), global Boss targeting for Spell Attack; pushing `unit.POW * ratio` DamageDO and applying `Hit Level+X` before Settle Time; `Skip Movement` marking on Lance, Melee, Spell Attack (while Shoot does NOT skip movement)
##   * Move Glide Logic (unitSkills.md):
##     - Raw Target Position from Move Skill effect (`SMA10001 Block`, `SMA10002 Approach`, `SMA10003 Patrol`, `SMA10004 Move Away`)
##     - Adjusted Target Position validation & 3-circle spiral search (Distance = 0.5, 1.0, 1.5, 8 clockwise 45-degree steps per circle = 24 candidates, cancelling move if all 3 circles fail)
##     - Considering the Adjusted Target Position instead of the original position for pucks that shall move in the Move Skill phase
##     - Constant-speed glide with collider disabled during movement
##   * Separated Pocket Return Lifecycle:
##     - Surviving pocketed Boss Monster respawns at the end of that turn's Settle Time
##     - Surviving pocketed Adventurer stays pocketed (`is_pocketed = true`, keeping Action Tag count and Action Countdown unchanged) and respawns in Phase 4 of its next Action Time (after all on-table acting units finish moving, in SPD descending order, consuming its action for that turn and skipping Chanting increment)

const AUTO_FIGHT_MANAGER_PATH := "res://src/battlefield/auto_fight_manager.gd"
const PRESENTATION_MANAGER_PATH := "res://src/battlefield/presentation_manager.gd"
const UNIT_INFO_MANAGER_PATH := "res://src/battlefield/unit_information_manager.gd"
const UNIT_SKILL_MANAGER_PATH := "res://src/battlefield/unit_skill_manager.gd"
const TIME_BOARD_MODEL_PATH := "res://src/canvas/time_board_model.gd"


func suite_name() -> String:
	return "auto-fight-action-time-and-move-glides"


func test_three_phase_spd_order_chanting_pow_buff_attack_skills_and_skip_movement() -> void:
	assert_true(ResourceLoader.exists(AUTO_FIGHT_MANAGER_PATH), "AutoFightManager script exists")
	assert_true(ResourceLoader.exists(PRESENTATION_MANAGER_PATH), "PresentationManager script exists")
	if not ResourceLoader.exists(AUTO_FIGHT_MANAGER_PATH) or not ResourceLoader.exists(PRESENTATION_MANAGER_PATH):
		return

	var tree := Engine.get_main_loop() as SceneTree
	var root := Node3D.new()
	tree.root.add_child(root)

	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var pm = load(PRESENTATION_MANAGER_PATH).new()
	pm.instant_mode = true
	var afm = load(AUTO_FIGHT_MANAGER_PATH).new()
	var model: TimeBoardModel = load(TIME_BOARD_MODEL_PATH).new()
	root.add_child(tm)
	root.add_child(uim)
	root.add_child(usm)
	root.add_child(pm)
	root.add_child(afm)
	usm.bind_unit_information_manager(uim)

	var boss := DragonPlayer.new()
	var guard := EnemyAdventurer.new()
	guard.adventurer_class = EnemyAdventurer.AdventurerClass.GUARD
	var brawler := EnemyAdventurer.new()
	brawler.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	var scout := EnemyAdventurer.new()
	scout.adventurer_class = EnemyAdventurer.AdventurerClass.SCOUT
	var acolyte := EnemyAdventurer.new()
	acolyte.adventurer_class = EnemyAdventurer.AdventurerClass.ACOLYTE
	for p in [boss, guard, brawler, scout, acolyte]:
		root.add_child(p)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_boss("boss_a", "a", {"max_hp": 5000, "current_hp": 5000, "power": 400, "puck": boss})
	uim.register_adventurer_team(1, [
		{"unit_id": "u_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": guard},
		{"unit_id": "u_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": brawler},
		{"unit_id": "u_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT, "puck": scout},
		{"unit_id": "u_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE, "puck": acolyte},
	])
	model.bind(tm, uim, usm)
	afm.bind(tm, uim, usm, pm, null, model)
	tm.enter_prepare()
	tm.start_charging()

	# Place pucks for Turn 12 test where ALL 4 units act together:
	# - Boss at (0, 0)
	# - Brawler (SPD 160) at (1.8, 0): edge-to-edge distance to Boss = 1.8 - (0.8 + 0.6) = 0.4 <= 1.5 -> Melee triggers (Skip Movement!)
	# - Scout (SPD 145) at (-5.0, 0): centre-to-centre distance to Boss = 5.0 <= 7.5 -> Shoot triggers (does NOT skip movement -> also moves in Move phase!)
	# - Acolyte (SPD 140) at (10.0, -4.0): Spell Attack (Skill Countdown 12) is ready at Turn 12 -> targets Boss anywhere (Skip Movement!)
	# - Guard (SPD 125) at (0.0, 3.0): edge-to-edge distance to Boss = 3.0 - (0.8 + 0.65) = 1.55 <= 3.5 -> Lance (Skill Countdown 9) is ready at Turn 12 -> triggers (Skip Movement!)
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	brawler.global_position = Vector3(1.8, 1.675, 0.0)
	scout.global_position = Vector3(-5.0, 1.675, 0.0)
	acolyte.global_position = Vector3(10.0, 1.675, -4.0)
	guard.global_position = Vector3(0.0, 1.7, 3.0)

	# 1. Simulate Turn 6 first for Acolyte (`SPA10004 Chanting` N: 0 -> 1, POW: 280 * 1.10 = 308; Spell Attack CD is 6 so Acolyte only moves):
	var acolyte_do := uim.get_unit("u_acolyte")
	var chanting_sk: UnitSkill = usm.get_unit_passive_skills("u_acolyte")[0]
	assert_eq(chanting_sk.counter, 0, "Chanting starts at counter N = 0")
	assert_eq(acolyte_do.power, 280, "Acolyte base POW at Lv 5 is 280")

	# Set all 4 units to act at Turn 12 with their Skill Countdowns ready (0), and Acolyte already at N=1 from Turn 6 so Turn 12 increments N to 2 (+20% POW -> 280 * 1.20 = 336)!
	chanting_sk.counter = 1
	usm.apply_stat_modifier(acolyte_do, "SPA10004_chanting", "power", 0.10, 0)
	# Verify during Action Time that acting units (whose next_action_turns == 0) display a larger Red "0" on their UnitDisplay!
	var uib_script := load("res://src/canvas/unit_information_board.gd")
	var uib: UnitInformationBoard = uib_script.new()
	root.add_child(uib)
	uib.bind_manager(uim)
	for uid in ["u_guard", "u_brawler", "u_scout", "u_acolyte"]:
		uim.set_unit_action_turns(uid, [0])
		var atk := usm.get_unit_attack_skill(uid)
		if atk != null:
			atk.current_countdown = 0
	var g_cell_info := uib.get_cell_info("R21")
	assert_eq(str(g_cell_info.get("action_turns_text", "")), "0", "Acting unit displays '0' on its UnitDisplay during Action Time")
	assert_true(bool(g_cell_info.get("action_turns_is_acting_red_zero", false)), "Acting unit's '0' is highlighted as a larger Red 0")

	# Verify PhysicsConstant speed constants and 2.5x Move Skill distances & 2x Attack Skill ranges:
	assert_true(is_equal_approx(PhysicsConstant.ENERGY_CHARGING_SPEED, 0.50), "Energy charging speed is 50% slower (0.50) in PhysicsConstant")
	assert_true(is_equal_approx(PhysicsConstant.GLIDE_SPEED_UNITS_PER_SEC, 6.0), "Glide speed is 20% slower (6.0) in PhysicsConstant")
	assert_true(is_equal_approx(usm.get_unit_attack_skill("u_guard").attack_range, 7.0), "Guard Lance attack range is 2x (7.0)")
	assert_true(is_equal_approx(usm.get_unit_attack_skill("u_brawler").attack_range, 3.0), "Brawler Melee attack range is 2x (3.0)")
	assert_true(is_equal_approx(usm.get_unit_attack_skill("u_scout").attack_range, 15.0), "Scout Shoot attack range is 2x (15.0)")
	assert_true(is_equal_approx(usm.get_unit_move_skill("u_brawler").base_dist_min, 2.0), "Brawler Approach min distance is 2.5x (2.0)")
	assert_true(is_equal_approx(usm.get_unit_move_skill("u_acolyte").base_dist_max, 5.0), "Acolyte Move Away max distance is 2.5x (5.0)")

	var scout_start_pos := scout.global_position
	var brawler_start_pos := brawler.global_position
	var guard_start_pos := guard.global_position
	var acolyte_start_pos := acolyte.global_position

	# 2. Execute Action Time on AutoFightManager!
	afm.execute_action_time()

	# 3. Verify ON_ACTION_TIME_START: Acolyte's Chanting counter incremented from 1 -> 2, boosting POW to 280 * 1.20 = 336 BEFORE Spell Attack fired!
	assert_eq(chanting_sk.counter, 2, "Acolyte Chanting counter incremented to 2 at start of Action Time")
	assert_eq(acolyte_do.power, 336, "Acolyte POW recalculated to 280 * 1.20 = 336 before Attack phase")

	# 4. Verify Three-Phase SPD-ordered execution trace:
	#    In Phase 2 (Attack Skills), all 4 units attacked in strict SPD descending order:
	#      1st: u_brawler (SPD 160, SAA10002 Melee: 280 * 100% = 280 dmg, Hit Level+1)
	#      2nd: u_scout   (SPD 145, SAA10003 Shoot: 280 * 50%  = 140 dmg, Hit Level+1)
	#      3rd: u_acolyte (SPD 140, SAA10004 Spell Attack: 336 * 250% = 840 dmg, Hit Level+3)
	#      4th: u_guard   (SPD 125, SAA10001 Lance: 280 * 100% = 280 dmg, Hit Level+2)
	#    In Phase 3 (Move Skills), ONLY u_scout moved (because Melee, Spell Attack, and Lance all have Skip Movement = true, while Shoot has Skip Movement = false)!
	var trace: Array = afm.last_execution_trace
	assert_eq(trace.size(), 5, "4 Attack Skills + 1 Move Skill (Scout) executed across the phases")
	if trace.size() >= 5:
		assert_eq(str(trace[0].get("phase")), "attack", "Trace[0] is Attack phase")
		assert_eq(str(trace[0].get("unit_id")), "u_brawler", "Highest SPD (160) Brawler attacks 1st")
		assert_eq(str(trace[1].get("unit_id")), "u_scout", "2nd highest SPD (145) Scout attacks 2nd")
		assert_eq(str(trace[2].get("unit_id")), "u_acolyte", "3rd highest SPD (140) Acolyte attacks 3rd")
		assert_eq(str(trace[3].get("unit_id")), "u_guard", "4th highest SPD (125) Guard attacks 4th")
		assert_eq(str(trace[4].get("phase")), "move", "Phase 3 (Move Skills) runs AFTER all Attack Skills complete")
		assert_eq(str(trace[4].get("unit_id")), "u_scout", "Only Scout executes its Move Skill (Brawler, Acolyte, Guard skipped movement)")

	# 5. Verify Boss Monster Damage Stack and Hit Level before Settle Time:
	#    - 4 DamageDO entries: 280 (Melee) + 140 (Shoot) + 840 (Spell Attack with 336 POW * 2.5) + 280 (Lance) = 1540 raw damage
	#    - Total Hit Level added = +1 (Melee) + 1 (Shoot) + 3 (Spell Attack) + 2 (Lance) = +7
	#    - Skill Countdowns reset to 9 on Lance and 12 on Spell Attack!
	var boss_do := uim.get_unit("boss_a")
	assert_eq(boss_do.damage_stack.size(), 4, "Boss received 4 attack DamageDO entries")
	assert_true(is_equal_approx(boss_do.get_damage_stack_sum(), 1540.0), "Total raw attack damage on Boss is 280 + 140 + 840 + 280 = 1540")
	assert_eq(boss_do.hit_level, 7, "Boss Hit Level increased to 1+1+3+2 = 7 before Settle Time")
	assert_eq(usm.get_unit_attack_skill("u_guard").current_countdown, 9, "Guard Lance reset its Skill Countdown to 9 upon activation")
	assert_eq(usm.get_unit_attack_skill("u_acolyte").current_countdown, 12, "Acolyte Spell Attack reset its Skill Countdown to 12 upon activation")

	# 6. Verify Scout moved while Brawler, Guard, and Acolyte stayed at their starting positions:
	assert_true(scout.global_position.distance_to(scout_start_pos) > 0.2, "Scout glided during Move phase after firing Shoot")
	assert_true(brawler.global_position.distance_to(brawler_start_pos) < 0.01, "Brawler skipped movement after Melee")
	assert_true(guard.global_position.distance_to(guard_start_pos) < 0.01, "Guard skipped movement after Lance")
	assert_true(acolyte.global_position.distance_to(acolyte_start_pos) < 0.01, "Acolyte skipped movement after Spell Attack")

	tree.root.remove_child(root)
	root.free()


func test_move_glide_logic_three_circle_adjusted_target_search_and_pocket_return_lifecycle() -> void:
	if not ResourceLoader.exists(AUTO_FIGHT_MANAGER_PATH) or not ResourceLoader.exists(PRESENTATION_MANAGER_PATH):
		return

	var tree := Engine.get_main_loop() as SceneTree
	var root := Node3D.new()
	tree.root.add_child(root)

	var tm := TimingManager.new()
	var uim: UnitInformationManager = load(UNIT_INFO_MANAGER_PATH).new()
	var usm: UnitSkillManager = load(UNIT_SKILL_MANAGER_PATH).new()
	var pm = load(PRESENTATION_MANAGER_PATH).new()
	pm.instant_mode = true
	var afm = load(AUTO_FIGHT_MANAGER_PATH).new()
	root.add_child(tm)
	root.add_child(uim)
	root.add_child(usm)
	root.add_child(pm)
	root.add_child(afm)
	usm.bind_unit_information_manager(uim)

	var boss := DragonPlayer.new()
	var blocker := BasePuck.new()
	blocker.radius = 0.6
	var mover := EnemyAdventurer.new()
	mover.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	var pocketed_acolyte := EnemyAdventurer.new()
	pocketed_acolyte.adventurer_class = EnemyAdventurer.AdventurerClass.ACOLYTE
	var pocketed_brawler := EnemyAdventurer.new()
	pocketed_brawler.adventurer_class = EnemyAdventurer.AdventurerClass.BRAWLER
	for p in [boss, blocker, mover, pocketed_acolyte, pocketed_brawler]:
		root.add_child(p)
		p.global_position = Vector3(-10.0, 1.7, -5.0)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_boss("boss_a", "a", {"max_hp": 2000, "current_hp": 2000, "power": 400, "puck": boss})
	uim.register_minion("blocker_m", "a", 1, {"max_hp": 500, "current_hp": 500, "puck": blocker})
	uim.register_adventurer_team(1, [
		{"unit_id": "u_mover", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": mover},
		{"unit_id": "u_pocket_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE, "puck": pocketed_acolyte},
		{"unit_id": "u_pocket_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": pocketed_brawler},
	])
	afm.bind(tm, uim, usm, pm)

	# 1. Test Move Glide Logic 3-circle spiral search (`resolve_adjusted_target_position`):
	#    Place stationary `blocker` at (2.0, 1.7, 0.0) (radius 0.6).
	#    If `mover` (radius 0.6) has a raw Target Position right on top of `blocker` at (2.0, 1.7, 0.0),
	#    the raw Target Position is NOT valid (overlaps `blocker`), so the 3-circle search (Distance = 0.5, 1.0, 1.5,
	#    rotating 45 deg clockwise) finds a valid Adjusted Target Position at distance >= 1.2 from `blocker`!
	boss.global_position = Vector3(-8.0, 1.8, 0.0)
	blocker.global_position = Vector3(2.0, 1.7, 0.0)
	mover.global_position = Vector3(0.0, 1.675, 0.0)
	var raw_target := Vector3(2.0, 1.675, 0.0)
	var res_adj: Dictionary = afm.resolve_adjusted_target_position(mover, raw_target, {}, {})
	assert_true(bool(res_adj.get("valid", false)), "3-circle spiral search finds a valid Adjusted Target Position around an occupied target")
	var adj_pos: Vector3 = res_adj.get("position", raw_target)
	var dist_to_blocker := Vector2(adj_pos.x - blocker.global_position.x, adj_pos.z - blocker.global_position.z).length()
	assert_true(dist_to_blocker >= mover.radius + blocker.radius - 0.001,
		"Adjusted Target Position does not overlap stationary blocker puck (dist %.2f >= %.2f)" % [dist_to_blocker, mover.radius + blocker.radius])

	# 2. Verify that if another puck `mover` SHALL MOVE in this phase and has already claimed `planned_positions[mover] = (5.0, 1.675, 0.0)`,
	#    its original position `(0.0, 1.675, 0.0)` is now considered FREE (valid) while its Adjusted Target Position `(5.0, 1.675, 0.0)` is considered OCCUPIED!
	var moving_set := {mover: true}
	var planned_map := {mover: Vector3(5.0, 1.675, 0.0)}
	assert_true(afm.is_valid_glide_position(pocketed_brawler, Vector3(0.0, 1.675, 0.0), moving_set, planned_map),
		"Original position of a puck that shall move is treated as free once its Adjusted Target Position is planned")
	assert_false(afm.is_valid_glide_position(pocketed_brawler, Vector3(5.0, 1.675, 0.0), moving_set, planned_map),
		"Adjusted Target Position of a puck that shall move is treated as occupied for subsequent pucks")

	# 3. Verify that if a raw Target Position is completely surrounded so all 3 circles (Distance = 0.5, 1.0, 1.5) are blocked
	#    (e.g. far outside the table cushions at X = 25.0), the 3-circle search cancels the move (`valid == false`)!
	var res_cancel: Dictionary = afm.resolve_adjusted_target_position(mover, Vector3(25.0, 1.675, 0.0), {}, {})
	assert_false(bool(res_cancel.get("valid", true)), "Move is cancelled after 3 circles when no Valid Position exists within 1.5 radius")

	# 4. Verify Phase 4 Pocketed Units Return in Action Time:
	#    - Mark `u_pocket_acolyte` (SPD 140) and `u_pocket_brawler` (SPD 160) as pocketed with `next_action_turns = 0`
	#    - Give `u_pocket_acolyte` Chanting counter N = 0
	#    - Place `u_mover` far from enemies so it only moves (Phase 3)
	#    - When `execute_action_time()` runs:
	#      * `u_mover` moves in Phase 3 FIRST
	#      * Then in Phase 4, `u_pocket_brawler` (SPD 160) and `u_pocket_acolyte` (SPD 140) respawn in SPD descending order!
	#      * Neither returning unit executes Attack or Move skills on their return turn (returning consumes their action for that turn!)
	#      * `u_pocket_acolyte` skips the `SPA10004 Chanting` counter increment on its pocket return turn (counter stays 0)!
	uim.set_unit_pocketed("u_pocket_acolyte", true, 0)
	uim.set_unit_pocketed("u_pocket_brawler", true, 0)
	blocker.global_position = Vector3(8.0, 1.7, 0.0) # Out of 1.5 melee range so u_mover executes Move Skill in Phase 3
	pocketed_acolyte.begin_pocket_fall(Vector3(-14.0, 1.5, -9.0))
	pocketed_acolyte.global_position = Vector3(-14.0, -3.0, -9.0)
	pocketed_brawler.begin_pocket_fall(Vector3(14.0, 1.5, -9.0))
	pocketed_brawler.global_position = Vector3(14.0, -3.0, -9.0)

	uim.get_unit("u_mover").next_action_turns = 0
	uim.get_unit("u_pocket_acolyte").next_action_turns = 0
	uim.get_unit("u_pocket_brawler").next_action_turns = 0
	var chanting_sk: UnitSkill = usm.get_unit_passive_skills("u_pocket_acolyte")[0]
	chanting_sk.counter = 0

	afm.execute_action_time()

	var trace: Array = afm.last_execution_trace
	assert_eq(trace.size(), 3, "1 on-table Move + 2 Pocket Returns")
	if trace.size() >= 3:
		assert_eq(str(trace[0].get("phase")), "move", "On-table unit moves in Phase 3 before pocketed units return")
		assert_eq(str(trace[0].get("unit_id")), "u_mover", "u_mover executes Move Skill")
		assert_eq(str(trace[1].get("phase")), "pocket_return", "Phase 4 pocket return runs after all on-table units move")
		assert_eq(str(trace[1].get("unit_id")), "u_pocket_brawler", "Higher-SPD pocketed Brawler (160) respawns first")
		assert_eq(str(trace[2].get("phase")), "pocket_return", "2nd pocket return")
		assert_eq(str(trace[2].get("unit_id")), "u_pocket_acolyte", "Lower-SPD pocketed Acolyte (140) respawns second")

	assert_false(uim.get_unit("u_pocket_brawler").is_pocketed, "Pocketed Brawler is back on the table")
	assert_false(uim.get_unit("u_pocket_acolyte").is_pocketed, "Pocketed Acolyte is back on the table")
	assert_false(pocketed_brawler.is_falling_in_pocket, "Pocketed Brawler puck reset_from_pocket_fall called")
	assert_false(pocketed_acolyte.is_falling_in_pocket, "Pocketed Acolyte puck reset_from_pocket_fall called")
	assert_eq(chanting_sk.counter, 0, "Acolyte returning from pocket skips SPA10004 Chanting counter increment (stays 0)")

	tree.root.remove_child(root)
	root.free()
