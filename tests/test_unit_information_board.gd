extends McpTestSuite

## Tests for Ticket 01: Unit Information Board 2x8 Grid, Reference Marks & Colour Coding.
## Tests only at the two agreed public seams:
## 1. UnitInformationManager public API (registration, {L|R}{1..8}{1..2} grid mapping,
##    uncompacted missing class slots, custom stage overrides, 0..N multi-puck links,
##    Reference Marks, slot/mark colours, and 1P / 2P Co-op / 2P Versus layouts).
## 2. UnitInformationBoard public view seam (cell occupancy, Boss 2-cell spans,
##    Frenzy Power display, role-based Boss HP bar visibility, and demo battlefield
##    integration with 10 Enemy Adventurer pucks: Team 1 = 6 members with ?5 != ?6,
##    Team 2 = 4 members, and removal of floating 3D-to-2D enemy health bars).

const MANAGER_SCRIPT := "res://src/battlefield/unit_information_manager.gd"
const BOARD_SCRIPT := "res://src/canvas/unit_information_board.gd"
const DEMO_SCENE := "res://src/demo_bettlefield.tscn"


func suite_name() -> String:
	return "unit-information-board-grid-and-reference-marks"


func _new_manager() -> Node:
	var s := ResourceLoader.load(MANAGER_SCRIPT, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	assert_true(s != null, "UnitInformationManager script exists")
	if s == null:
		return null
	return s.new()


func _new_board() -> Control:
	var s := ResourceLoader.load(BOARD_SCRIPT, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	assert_true(s != null, "UnitInformationBoard script exists")
	if s == null:
		return null
	return s.new()


func test_single_player_pve_layout_and_class_to_slot_mapping_with_uncompacted_gaps() -> void:
	var mgr := _new_manager()
	if mgr == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(mgr)
	assert_true(mgr.is_in_group("unit_information_manager"), "Manager registers in unit_information_manager group")

	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)

	# Register Player A Boss Monster -> L1 span (L11..L12), Reference Mark Ω in Gold, slot colour Black
	var boss_a = mgr.register_boss("boss_a", "a", {"max_hp": 100, "current_hp": 100, "bars_remaining": 15, "max_bars": 15})
	assert_eq(boss_a.grid_id, "L11", "Player A Boss starts at L11 (Row L1 span)")
	assert_eq(boss_a.span_cols, 2, "Boss Unit Display spans 2 horizontal cells")
	assert_eq(boss_a.reference_mark, "Ω", "Player A Boss Reference Mark is Ω")
	assert_eq(boss_a.reference_mark_color, mgr.COLOR_MARK_GOLD, "Player A Boss Reference Mark colour is Gold")
	assert_eq(boss_a.slot_color, mgr.COLOR_SLOT_BOSS_BLACK, "Boss Monster slot/puck colour is Black")

	# Register 2 Player A Minions at slots 1 and 3 -> L21 (ω1) and L31 (ω3)
	var m1 = mgr.register_minion("minion_a1", "a", 1)
	var m3 = mgr.register_minion("minion_a3", "a", 3)
	assert_eq(m1.grid_id, "L21", "Player A Minion 1 is at L21")
	assert_eq(m1.reference_mark, "ω1", "Player A Minion 1 Reference Mark is ω1")
	assert_eq(m1.reference_mark_color, mgr.COLOR_MARK_GOLD, "Player A Minion Reference Mark colour is Gold")
	assert_eq(m3.grid_id, "L31", "Player A Minion 3 is at L31")
	assert_eq(m3.reference_mark, "ω3", "Player A Minion 3 Reference Mark is ω3")

	# Register Team 1 (full 6 members: Guard, Brawler, Scout, Acolyte + 2 distinct duplicate classes at ?5 and ?6)
	var puck_t1_k := EnemyAdventurer.new()
	var puck_t1_dup1 := EnemyAdventurer.new()
	var puck_t1_dup2 := EnemyAdventurer.new()
	var team1_units: Array = mgr.register_adventurer_team(1, [
		{"unit_id": "t1_k", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": puck_t1_k},
		{"unit_id": "t1_w", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER},
		{"unit_id": "t1_r", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
		{"unit_id": "t1_m", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
		{"unit_id": "t1_dup1", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER, "puck": puck_t1_dup1},
		{"unit_id": "t1_dup2", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": puck_t1_dup2},
	])
	assert_eq(team1_units.size(), 6, "Team 1 registered 6 adventurers")
	assert_eq(mgr.get_unit_at_grid("R21").reference_mark, "G", "Guard maps to slot 1 -> G (Guard) at R21")
	assert_eq(mgr.get_unit_at_grid("R21").name_key, "uib_class_guard", "Guard localization key is uib_class_guard")
	assert_eq(mgr.get_unit_at_grid("R21").slot_color, mgr.COLOR_SLOT_1_BLUE, "Guard colour is Blue")
	assert_eq(mgr.get_unit_at_grid("R22").reference_mark, "B", "Brawler maps to slot 2 -> B (Brawler) at R22")
	assert_eq(mgr.get_unit_at_grid("R22").name_key, "uib_class_brawler", "Brawler localization key is uib_class_brawler")
	assert_eq(mgr.get_unit_at_grid("R22").slot_color, mgr.COLOR_SLOT_2_RED, "Brawler colour is Red")
	assert_eq(mgr.get_unit_at_grid("R31").reference_mark, "S", "Scout maps to slot 3 -> S (Scout) at R31")
	assert_eq(mgr.get_unit_at_grid("R31").name_key, "uib_class_scout", "Scout localization key is uib_class_scout")
	assert_eq(mgr.get_unit_at_grid("R31").slot_color, mgr.COLOR_SLOT_5_GREEN, "Scout colour is Green")
	assert_eq(mgr.get_unit_at_grid("R32").reference_mark, "A", "Acolyte maps to slot 4 -> A (Acolyte) at R32")
	assert_eq(mgr.get_unit_at_grid("R32").name_key, "uib_class_acolyte", "Acolyte localization key is uib_class_acolyte")
	assert_eq(mgr.get_unit_at_grid("R32").slot_color, mgr.COLOR_SLOT_4_PURPLE, "Acolyte colour is Purple")
	assert_eq(mgr.get_unit_at_grid("R41").reference_mark, "F", "1st duplicate maps to slot 5 -> F (Free) at R41")
	assert_eq(mgr.get_unit_at_grid("R41").slot_color, mgr.COLOR_SLOT_2_RED, "Duplicate Brawler in F keeps Brawler Red colour")
	assert_eq(mgr.get_unit_at_grid("R42").reference_mark, "E", "2nd duplicate maps to slot 6 -> E (Extra) at R42")
	assert_eq(mgr.get_unit_at_grid("R42").slot_color, mgr.COLOR_SLOT_1_BLUE, "Duplicate Guard in E keeps Guard Blue colour!")
	assert_eq(mgr.get_unit_at_grid("R21").reference_mark_color, mgr.COLOR_MARK_TEAM1_GREY, "Team 1 Reference Mark colour is Deep Grey")
	assert_true(mgr.get_unit_at_grid("R22").avatar_path != mgr.get_unit_at_grid("R41").avatar_path, "Duplicate Brawler gets a distinct avatar image from the first Brawler")

	# Verify Team 1 puck stripe & free-position 8-ball circle rules:
	# Team 1 pucks have White 4-sided X stripe (team_x_stripe_mode == 1);
	# slot 1 (G) has no center circle, while slots 5 (F) and 6 (E) have the white 8-ball circle behind the letter!
	assert_eq(puck_t1_k.get_team_x_stripe_mode(), 1, "Team 1 puck has White 4-sided X stripe (mode 1)")
	assert_false(puck_t1_k.has_free_slot_center_circle(), "Slot 1 (G) has no free-position center circle")
	assert_eq(puck_t1_dup1.get_team_x_stripe_mode(), 1, "Team 1 slot 5 puck has White 4-sided X stripe (mode 1)")
	assert_true(puck_t1_dup1.has_free_slot_center_circle(), "Slot 5 (F) puck has 8-ball circle behind the letter")
	assert_true(puck_t1_dup2.has_free_slot_center_circle(), "Slot 6 (E) puck has 8-ball circle behind the letter")

	# Register Team 2 with a missing Brawler (slot 2) and missing Scout (slot 3): only Guard, Acolyte, and a duplicate Acolyte!
	# Missing class slots R62 (b) and R71 (s) must stay empty rather than compacting!
	var puck_t2_k := EnemyAdventurer.new()
	var puck_t2_m2 := EnemyAdventurer.new()
	mgr.register_adventurer_team(2, [
		{"unit_id": "t2_k", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD, "puck": puck_t2_k},
		{"unit_id": "t2_m", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
		{"unit_id": "t2_m2", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE, "puck": puck_t2_m2},
	])
	assert_true(mgr.get_unit_at_grid("R61") != null, "Team 2 Guard is at R61 (g)")
	assert_eq(mgr.get_unit_at_grid("R61").reference_mark, "g", "Team 2 Guard Reference Mark is small letter 'g'")
	assert_eq(mgr.get_unit_at_grid("R61").reference_mark_color, mgr.COLOR_MARK_TEAM2_BROWN, "Team 2 Reference Mark colour is Deep Brown")
	assert_eq(puck_t2_k.get_team_x_stripe_mode(), 2, "Team 2 puck has Black 4-sided X stripe (mode 2)")
	assert_false(puck_t2_k.has_free_slot_center_circle(), "Team 2 slot 1 (g) has no free-position center circle")
	assert_true(mgr.get_unit_at_grid("R62") == null, "Missing Brawler leaves R62 (b) empty (not compacted)")
	assert_true(mgr.get_unit_at_grid("R71") == null, "Missing Scout leaves R71 (s) empty (not compacted)")
	assert_true(mgr.get_unit_at_grid("R72") != null, "Team 2 Acolyte is at R72 (a)")
	assert_eq(mgr.get_unit_at_grid("R72").reference_mark, "a", "Team 2 Acolyte Reference Mark is small letter 'a'")
	assert_true(mgr.get_unit_at_grid("R81") != null, "Duplicate Acolyte takes first free position R81 (f)")
	assert_eq(mgr.get_unit_at_grid("R81").reference_mark, "f", "Duplicate Acolyte Reference Mark is small letter 'f'")
	assert_eq(mgr.get_unit_at_grid("R81").slot_color, mgr.COLOR_SLOT_4_PURPLE, "Duplicate Acolyte in 'f' keeps Acolyte Purple colour")
	assert_eq(puck_t2_m2.get_team_x_stripe_mode(), 2, "Team 2 duplicate Acolyte puck has Black 4-sided X stripe (mode 2)")
	assert_true(puck_t2_m2.has_free_slot_center_circle(), "Team 2 slot 5 (f) puck has 8-ball circle behind the letter")
	assert_true(mgr.get_unit_at_grid("R82") == null, "Unused 6th slot R82 (e) stays empty")

	puck_t1_k.free()
	puck_t1_dup1.free()
	puck_t1_dup2.free()
	puck_t2_k.free()
	puck_t2_m2.free()
	tree.root.remove_child(mgr)
	mgr.free()


func test_custom_stage_override_and_2p_coop_and_2p_versus_layouts() -> void:
	var mgr := _new_manager()
	if mgr == null:
		return

	# 1. Custom stage override: explicitly place an Acolyte in slot 1 (G / R21)
	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_adventurer_team(1, [
		{"unit_id": "custom_mage_slot1", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE, "slot_override": 1},
	])
	var custom_u = mgr.get_unit_at_grid("R21")
	assert_true(custom_u != null, "Custom stage override places Acolyte in slot 1 (R21)")
	assert_eq(custom_u.reference_mark, "G", "Custom slot 1 unit gets G Reference Mark")
	assert_eq(custom_u.adventurer_class, EnemyAdventurer.AdventurerClass.ACOLYTE, "Custom slot 1 unit keeps Acolyte class")
	assert_eq(custom_u.slot_color, mgr.COLOR_SLOT_4_PURPLE, "Custom slot 1 Acolyte unit gets Acolyte Purple border/puck colour")

	# 2. 2-Player Co-op layout: L1 = Player A Boss (Ω), L2-L4 = Player A Minions (ω1..6),
	#    L5 = Player B Boss (Ψ), L6-L8 = Player B Minions (ψ1..6)
	mgr.clear_all()
	mgr.configure_mode(mgr.MODE_TWO_PLAYER_COOP)
	var coop_boss_a = mgr.register_boss("boss_a", "a", {})
	var coop_boss_b = mgr.register_boss("boss_b", "b", {})
	var coop_min_a = mgr.register_minion("min_a1", "a", 1)
	var coop_min_b = mgr.register_minion("min_b2", "b", 2)
	assert_eq(coop_boss_a.grid_id, "L11", "Co-op Player A Boss at L11 (Row L1 span)")
	assert_eq(coop_boss_b.grid_id, "L51", "Co-op Player B Boss at L51 (Row L5 span)")
	assert_eq(coop_boss_b.reference_mark, "Ψ", "Player B Boss Reference Mark is Ψ")
	assert_eq(coop_boss_b.reference_mark_color, mgr.COLOR_MARK_SILVER, "Player B Reference Mark colour is Silver")
	assert_eq(coop_min_a.grid_id, "L21", "Co-op Player A Minion 1 at L21")
	assert_eq(coop_min_b.grid_id, "L62", "Co-op Player B Minion 2 at L62 (Row L6 Col 2)")
	assert_eq(coop_min_b.reference_mark, "ψ2", "Player B Minion 2 Reference Mark is ψ2")
	assert_eq(coop_min_b.reference_mark_color, mgr.COLOR_MARK_SILVER, "Player B Minion Reference Mark colour is Silver")

	# 3. 2-Player Versus layout: L1 = Player A Boss, L2-L4 = Player A Minions, L5 empty, L6-L8 = Target Pucks
	#    R1 = Player B Boss, R2-R4 = Player B Minions, R5 empty, R6-R8 = Target Pucks
	mgr.clear_all()
	mgr.configure_mode(mgr.MODE_TWO_PLAYER_VS)
	var vs_boss_a = mgr.register_boss("vs_boss_a", "a", {})
	var vs_boss_b = mgr.register_boss("vs_boss_b", "b", {})
	var vs_min_b1 = mgr.register_minion("vs_min_b1", "b", 1)
	var vs_target_a1 = mgr.register_target_puck("vs_tgt_a1", "a", 1)
	var vs_target_b6 = mgr.register_target_puck("vs_tgt_b6", "b", 6)
	assert_eq(vs_boss_a.grid_id, "L11", "Versus Player A Boss at L11 (Row L1)")
	assert_eq(vs_boss_b.grid_id, "R11", "Versus Player B Boss at R11 (Row R1)")
	assert_eq(vs_min_b1.grid_id, "R21", "Versus Player B Minion 1 at R21")
	assert_true(mgr.get_unit_at_grid("L51") == null and mgr.get_unit_at_grid("R51") == null, "Versus Row L5 and R5 are left empty")
	assert_eq(vs_target_a1.grid_id, "L61", "Versus Player A Target Puck 1 at L61")
	assert_eq(vs_target_b6.grid_id, "R82", "Versus Player B Target Puck 6 at R82")

	mgr.free()


func test_multi_puck_registration_links_zero_to_n_pucks_with_same_reference_mark() -> void:
	var mgr := _new_manager()
	if mgr == null:
		return
	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_adventurer_team(1, [
		{"unit_id": "ranger_a3", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
	])
	var unit_do = mgr.get_unit("ranger_a3")
	assert_eq(unit_do.pucks.size(), 0, "Unit starts with 0 pucks before pucks are linked")

	var puck1 := EnemyAdventurer.new()
	var puck2 := EnemyAdventurer.new()
	mgr.register_puck("ranger_a3", puck1)
	mgr.register_puck("ranger_a3", puck2)
	assert_eq(unit_do.pucks.size(), 2, "Unit holds 2 active pucks simultaneously")
	assert_eq(puck1.get_reference_mark(), "S", "Puck 1 carries unit Reference Mark S")
	assert_eq(puck2.get_reference_mark(), "S", "Puck 2 carries unit Reference Mark S")
	assert_eq(puck1.get_slot_color(), mgr.COLOR_SLOT_5_GREEN, "Puck 1 receives Scout Green colour")
	assert_eq(puck2.get_slot_color(), mgr.COLOR_SLOT_5_GREEN, "Puck 2 receives Scout Green colour")

	mgr.unregister_puck("ranger_a3", puck1)
	assert_eq(unit_do.pucks.size(), 1, "Unregistering a puck leaves 1 active puck")
	mgr.unregister_puck("ranger_a3", puck2)
	assert_eq(unit_do.pucks.size(), 0, "Unit can have 0 active pucks (e.g. when pocketed/hidden)")

	puck1.free()
	puck2.free()
	mgr.free()


func test_board_view_renders_2x8_grids_frenzy_power_and_role_based_boss_hp_visibility() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	var board := _new_board()
	if mgr == null or board == null:
		return
	tree.root.add_child(mgr)
	tree.root.add_child(board)

	mgr.configure_mode(mgr.MODE_TWO_PLAYER_COOP)
	mgr.register_boss("boss_a", "a", {"max_hp": 100, "current_hp": 80, "bars_remaining": 12, "max_bars": 15, "frenzy_power": 1.3})
	mgr.register_boss("boss_b", "b", {"max_hp": 100, "current_hp": 60, "bars_remaining": 9, "max_bars": 15, "frenzy_power": 1.1})
	mgr.register_adventurer_team(1, [
		{"unit_id": "t1_k", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT},
		{"unit_id": "t1_w", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR},
	])

	board.bind_manager(mgr)

	# 1. When local role is Player A ("a") or Spectator ("spectator"):
	#    Player A's Boss is in the upper-left HUD -> L1 omits its internal HP bar, while Player B's Boss at L5 shows its HP bar + x9!
	board.set_local_role("a")
	var cell_l1: Dictionary = board.get_cell_info("L11")
	var cell_l5: Dictionary = board.get_cell_info("L51")
	assert_true(cell_l1.get("occupied", false), "L11 is occupied by Player A Boss")
	assert_eq(cell_l1.get("reference_mark"), "Ω", "L11 shows Reference Mark Ω")
	assert_eq(cell_l1.get("frenzy_text"), "130.0%", "L11 shows Player A Boss Frenzy Power to 1 d.p. on right side")
	assert_false(cell_l1.get("hp_bar_visible", true), "Local Player A's own Boss Unit Display omits HP bar")

	assert_true(cell_l5.get("occupied", false), "L51 is occupied by Player B Boss")
	assert_eq(cell_l5.get("reference_mark"), "Ψ", "L51 shows Reference Mark Ψ")
	assert_eq(cell_l5.get("frenzy_text"), "110.0%", "L51 shows Player B Boss Frenzy Power to 1 d.p. on right side")
	assert_true(cell_l5.get("hp_bar_visible", false), "Other Boss Monster (Player B at L51) displays its HP bar")
	assert_eq(cell_l5.get("bars_text"), "x9", "Other Boss Monster displays remaining Health Bar count x9")

	# 2. When local role switches to Player B ("b"):
	#    Player B's Boss is in the upper-left HUD -> L5 omits its internal HP bar, while Player A's Boss at L1 shows its HP bar + x12!
	board.set_local_role("b")
	cell_l1 = board.get_cell_info("L11")
	cell_l5 = board.get_cell_info("L51")
	assert_true(cell_l1.get("hp_bar_visible", false), "When viewed by Player B, Player A's Boss at L11 displays its HP bar")
	assert_eq(cell_l1.get("bars_text"), "x12", "When viewed by Player B, Player A's Boss shows x12")
	assert_false(cell_l5.get("hp_bar_visible", true), "When viewed by Player B, Player B's own Boss at L51 omits HP bar")

	# 3. Verify Team 1 Header at R11 and Adventurer cells at R21 (G) & R22 (B), and empty R31
	var cell_r1: Dictionary = board.get_cell_info("R11")
	assert_true(cell_r1.get("is_team_header", false), "R11 is Adventurer Team 1 header span")
	var cell_r21: Dictionary = board.get_cell_info("R21")
	assert_true(cell_r21.get("occupied", false), "R21 is occupied by G Guard")
	assert_eq(cell_r21.get("reference_mark"), "G", "R21 shows G")
	assert_true(cell_r21.get("class_mark_visible", false), "Enemy Adventurer shows Class Mark in upper-right")
	assert_true(cell_r21.get("hp_bar_visible", false), "Enemy Adventurer shows HP bar")
	var cell_r31: Dictionary = board.get_cell_info("R31")
	assert_false(cell_r31.get("occupied", true), "Unoccupied cell R31 remains an empty grid slot")

	tree.root.remove_child(board)
	tree.root.remove_child(mgr)
	board.free()
	mgr.free()


func test_demo_battlefield_spawns_10_adventurers_in_two_teams_and_removes_floating_bars() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var packed := ResourceLoader.load(DEMO_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(packed != null, "Demo battlefield scene loads")
	if packed == null:
		return
	var bf := packed.instantiate()
	tree.root.add_child(bf)

	var mgr := bf.get_node_or_null("UnitInformationManager")
	assert_true(mgr != null, "Demo battlefield has a UnitInformationManager node")

	var enemies: Array = []
	for child in bf.get_children():
		if child is EnemyAdventurer:
			enemies.append(child)
	assert_eq(enemies.size(), 10, "Demo battlefield has 10 Enemy Adventurer pucks on the Cue Table (Team 1 = 6, Team 2 = 4)")

	if mgr != null:
		# Team 1: 6 members at R21..R42 (A1..A6), with ?5 (R41) class != ?6 (R42) class
		for slot_id in ["R21", "R22", "R31", "R32", "R41", "R42"]:
			var u = mgr.get_unit_at_grid(slot_id)
			assert_true(u != null, "Team 1 slot %s is occupied" % slot_id)
		var u_a5 = mgr.get_unit_at_grid("R41")
		var u_a6 = mgr.get_unit_at_grid("R42")
		if u_a5 != null and u_a6 != null:
			assert_true(u_a5.adventurer_class != u_a6.adventurer_class, "Team 1 free slots ?5 (A5) and ?6 (A6) have different classes")

		# Team 2: 4 members at R61..R72 (B1..B4), R81 and R82 empty
		for slot_id in ["R61", "R62", "R71", "R72"]:
			var u = mgr.get_unit_at_grid(slot_id)
			assert_true(u != null, "Team 2 slot %s is occupied" % slot_id)
		assert_true(mgr.get_unit_at_grid("R81") == null, "Team 2 slot R81 (B5) is empty")
		assert_true(mgr.get_unit_at_grid("R82") == null, "Team 2 slot R82 (B6) is empty")

	# Legacy floating 3D-to-2D enemy health bars on Canvas are gone
	var floating_container := bf.get_node_or_null("Canvas/EnemyHealthBars") as Control
	var floating_count := floating_container.get_child_count() if floating_container != null else 0
	assert_eq(floating_count, 0, "No floating 2D health bars are spawned over the 3D Cue Table")

	tree.root.remove_child(bf)
	bf.free()


# ----- Ticket 02: Damage Stack, Hit Level, Frenzy Power & Ghost HP Trailing Pipeline -----


func test_damage_stack_hit_level_frenzy_power_ghost_hp_and_settle_time_pipeline() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	var board := _new_board()
	if mgr == null or board == null:
		return
	tree.root.add_child(mgr)
	tree.root.add_child(board)

	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "bars_remaining": 15, "max_bars": 15})
	mgr.register_adventurer_team(1, [
		{"unit_id": "adv_knight", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT, "max_hp": 3000, "current_hp": 3000},
		{"unit_id": "adv_warrior", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR, "max_hp": 2200, "current_hp": 2200},
	])
	board.bind_manager(mgr)
	board.set_local_role("a")

	# 1. Initially Damage Stack count is 0 -> circle badge on R22 (Warrior) is invisible, Ghost HP == Current HP (2200)
	var cell_w: Dictionary = board.get_cell_info("R22")
	assert_eq(cell_w.get("damage_stack_count", -1), 0, "Initial Damage Stack count is 0")
	assert_false(cell_w.get("damage_badge_visible", true), "Damage Stack circle badge is invisible when count is 0")
	assert_eq(cell_w.get("ghost_hp", -1), 2200, "Initial Ghost HP equals current HP 2200")
	assert_eq(cell_w.get("current_hp", -1), 2200, "Initial current HP is 2200")

	# 2. Boss Monster collides with non-Knight Adventurer twice (+10% each -> 120.0% Frenzy Power)
	mgr.record_boss_collision_frenzy("boss_a", "adv_warrior")
	mgr.record_boss_collision_frenzy("boss_a", "adv_warrior")
	var boss_do = mgr.get_unit("boss_a")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.2), "Boss Frenzy Power increased by +10% twice to 120%")
	assert_eq(board.get_cell_info("L11").get("frenzy_text"), "120.0%", "Boss Unit Display updates Frenzy Power to 120.0%")

	# 3. Push 2 DamageDO entries onto Warrior's Damage Stack (100 and 200, source boss_a) + set Hit Level = 2 (1.1^2 = 1.21)
	#    Also verify harder hit (200) produces a larger badge shake amplitude than softer hit (100)!
	mgr.push_damage("adv_warrior", 100, "boss_a", "boss_a", "collision")
	var shake_soft := float(board.get_cell_info("R22").get("last_badge_shake_amplitude", 0.0))
	mgr.push_damage("adv_warrior", 200, "boss_a", "boss_a", "collision")
	var shake_hard := float(board.get_cell_info("R22").get("last_badge_shake_amplitude", 0.0))
	assert_true(shake_soft > 0.0, "Damage Stack badge shakes when unit takes damage")
	assert_true(shake_hard > shake_soft, "A harder hit (200) creates a larger badge shake than a softer hit (100)")

	mgr.modify_hit_level("adv_warrior", 2)
	var warrior_do = mgr.get_unit("adv_warrior")
	assert_eq(warrior_do.hit_level, 2, "Warrior Hit Level is 2")
	assert_eq(warrior_do.damage_stack.size(), 2, "Warrior Damage Stack holds 2 DamageDO records in time order")

	# 4. Pre-Settle Ghost HP considers ONLY Damage Stack (100 + 200 = 300) and Hit Level (1.1^2 = 1.21) -> round(300 * 1.21) = 363!
	#    It must NOT include the Boss Monster's 120% Frenzy Power yet!
	#    And Warrior's actual current_hp is still 2200 before Settle Time!
	cell_w = board.get_cell_info("R22")
	assert_true(cell_w.get("damage_badge_visible", false), "Damage Stack circle badge is visible when count > 0")
	assert_eq(cell_w.get("damage_stack_count"), 2, "Damage Stack circle badge shows count 2")
	assert_eq(cell_w.get("damage_badge_text"), "2", "Damage Stack badge label displays '2'")
	assert_eq(cell_w.get("current_hp"), 2200, "Actual HP is unchanged (2200) before Settle Time")
	assert_eq(cell_w.get("ghost_hp"), 2200 - 363, "Pre-settle Ghost HP is 2200 - round(300 * 1.1^2) = 1837 (excluding Frenzy Power)")

	# 5. Impulse-proportional Unit Display shake during Puck-puck Time! collision
	mgr.notify_unit_collision_impulse("adv_warrior", 6.0)
	var display_shake_low := float(board.get_cell_info("R22").get("last_display_shake_amplitude", 0.0))
	mgr.notify_unit_collision_impulse("adv_warrior", 18.0)
	var display_shake_high := float(board.get_cell_info("R22").get("last_display_shake_amplitude", 0.0))
	assert_true(display_shake_low > 0.0, "Unit Display shakes on puck collision")
	assert_true(display_shake_high > display_shake_low, "Higher collision Impulse produces larger Unit Display shake")

	# 6. Settle Time resolution:
	#    - Frenzy Power spread visual triggers
	#    - Warrior final damage = round((100 * 1.2 + 200 * 1.2) * 1.1^2) = round(360 * 1.21) = 436 -> current_hp = 2200 - 436 = 1764
	#    - Damage Stack clears (count = 0, badge hidden)
	#    - Hit Level resets to 0
	#    - Boss Frenzy Power decays: (1.2 / 2) + 0.5 = 1.10 (110%)
	var settle_result: Dictionary = mgr.settle_all_damage()
	assert_true(bool(settle_result.get("frenzy_spread_triggered", false)), "Frenzy Power spread visual effect triggered on Settle")
	assert_eq(warrior_do.current_hp, 2200 - 436, "Settled damage on Warrior includes 120% Frenzy Power and 1.1^2 Hit Level (2200 - 436 = 1764)")
	assert_eq(warrior_do.damage_stack.size(), 0, "Warrior Damage Stack cleared after Settle Time")
	assert_eq(warrior_do.hit_level, 0, "Warrior Hit Level reset to 0 after Settle Time")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.10), "Boss Frenzy Power decayed from 120% to (120%/2 + 50%) = 110%")

	cell_w = board.get_cell_info("R22")
	assert_false(cell_w.get("damage_badge_visible", true), "Damage Stack circle badge hides again after Settle Time")
	assert_eq(cell_w.get("current_hp"), 1764, "Unit Display HP bar reflects settled HP 1764")
	assert_eq(cell_w.get("ghost_hp"), 1764, "Ghost HP matches current HP after Settle Time")
	assert_eq(cell_w.get("last_settled_hp_change_text"), "-436", "Unit Display shows settled HP change as '-436'")
	assert_eq(board.get_cell_info("L11").get("frenzy_text"), "110.0%", "Boss Unit Display shows decayed Frenzy Power 110.0%")

	tree.root.remove_child(board)
	tree.root.remove_child(mgr)
	board.free()
	mgr.free()


func test_two_player_coop_per_source_frenzy_knight_penalty_floor_and_boss_one_bar_cap() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	var board := _new_board()
	if mgr == null or board == null:
		return
	tree.root.add_child(mgr)
	tree.root.add_child(board)

	mgr.configure_mode(mgr.MODE_TWO_PLAYER_COOP)
	var boss_a = mgr.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 400, "bars_remaining": 5, "max_bars": 15, "frenzy_power": 1.4})
	var boss_b = mgr.register_boss("boss_b", "b", {"max_hp": 1000, "current_hp": 500, "bars_remaining": 1, "max_bars": 15, "frenzy_power": 1.0})
	mgr.register_adventurer_team(1, [
		{"unit_id": "adv_knight", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT, "max_hp": 3000, "current_hp": 3000},
		{"unit_id": "adv_mage", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE, "max_hp": 1500, "current_hp": 1500},
	])
	board.bind_manager(mgr)
	board.set_local_role("a")

	# 1. Player B Boss Frenzy Power decreases can be clamped at 50% minimum floor!
	mgr.modify_frenzy_power("boss_b", -0.20)
	assert_true(is_equal_approx(boss_b.frenzy_power, 0.8), "Reducing Boss B Frenzy Power by -20% lowers it to 80%")
	mgr.modify_frenzy_power("boss_b", -0.20)
	assert_true(is_equal_approx(boss_b.frenzy_power, 0.6), "2nd -20% reduction lowers Boss B Frenzy Power to 60%")
	mgr.modify_frenzy_power("boss_b", -0.20)
	assert_true(is_equal_approx(boss_b.frenzy_power, 0.5), "3rd reduction clamps Boss B Frenzy Power at 50% minimum floor")

	# 2. Per-DamageDO source Boss Frenzy Power in 2-Player Co-op:
	#    Mage takes:
	#      - 200 damage from Player A Boss (Frenzy = 140% -> 280)
	#      - 200 damage from Player B Boss (Frenzy = 50% -> 100)
	#      - 100 damage from environment/trap with no Boss owner (defaults to 100% -> 100)
	#    With Mage Hit Level = 1 (1.1^1 = 1.1):
	#      - Pre-settle Ghost HP damage = round((200 + 200 + 100) * 1.1) = 550 -> Ghost HP = 1500 - 550 = 950
	#      - Settle Time final damage = round((280 + 100 + 100) * 1.1) = round(480 * 1.1) = 528 -> Settled HP = 1500 - 528 = 972
	mgr.push_damage("adv_mage", 200, "boss_a", "boss_a", "collision")
	mgr.push_damage("adv_mage", 200, "boss_b", "boss_b", "collision")
	mgr.push_damage("adv_mage", 100, "trap", "", "effect")
	mgr.modify_hit_level("adv_mage", 1)

	assert_eq(mgr.get_preview_ghost_hp("adv_mage"), 1500 - 550, "Pre-settle Ghost HP on Mage is 950 (excludes Frenzy Power)")

	# 3. Strict 1-Health-Bar-per-Settle cap on ALL Boss Monsters:
	#    - Boss A has current_hp = 400 / 1000 and bars_remaining = 5.
	#      Deal 2500 damage to Boss A (enough to clear 2.5 bars if uncapped!).
	#      Pre-settle Ghost HP on Boss A must clamp to 0 of the active Health Bar!
	#      At Settle Time, Boss A loses ONLY 1 Health Bar (bars_remaining: 5 -> 4) and refills to 1000/1000 (all excess damage discarded!).
	#    - Boss B has current_hp = 500 / 1000 and bars_remaining = 1 (last bar).
	#      Deal 900 damage to Boss B -> clears its last bar (bars_remaining: 1 -> 0, current_hp = 0, is_dead = true).
	mgr.push_damage("boss_a", 2500, "adv_knight", "", "collision")
	assert_eq(mgr.get_preview_ghost_hp("boss_a"), 0, "Boss Monster Ghost HP clamps at 0 of the current Health Bar")

	mgr.push_damage("boss_b", 900, "adv_knight", "", "collision")
	assert_eq(board.get_cell_info("L51").get("ghost_hp"), 0, "Boss B Unit Display Ghost HP trails down to 0")

	mgr.settle_all_damage()

	var mage_do = mgr.get_unit("adv_mage")
	assert_eq(mage_do.current_hp, 1500 - 528, "2P Co-op Mage settled damage applies per-DamageDO source Boss Frenzy Power (1500 - 528 = 972)")

	assert_eq(boss_a.bars_remaining, 4, "Boss A lost at most 1 Health Bar (5 -> 4) despite 2500 staged damage")
	assert_eq(boss_a.current_hp, 1000, "Boss A refilled to 100% (1000) of the next Health Bar with excess damage discarded")
	assert_false(boss_a.is_dead, "Boss A is still alive with 4 bars remaining")

	assert_eq(boss_b.bars_remaining, 0, "Boss B cleared its last Health Bar (1 -> 0)")
	assert_eq(boss_b.current_hp, 0, "Boss B HP is 0 when final Health Bar breaks")
	assert_true(boss_b.is_dead, "Boss B is defeated when bars_remaining reaches 0")

	# 4. Verify Frenzy Power decay pulls values BOTH above 100% (140% -> 120%) and below 100% (50% -> 75%) halfway toward 100%
	assert_true(is_equal_approx(boss_a.frenzy_power, 1.20), "Boss A Frenzy Power decayed from 140% to (140%/2 + 50%) = 120%")
	assert_true(is_equal_approx(boss_b.frenzy_power, 0.75), "Boss B Frenzy Power recovered from 50% to (50%/2 + 50%) = 75%")

	tree.root.remove_child(board)
	tree.root.remove_child(mgr)
	board.free()
	mgr.free()


# ----- Ticket 03: Migrate Unit HP/Stats to Unit Information, Scale Adventurer HP & Wire Linear Impulse Collision Damage -----


func test_unit_hp_stats_migrated_to_unit_info_with_thousands_scale_adventurer_hp() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	if mgr == null:
		return
	tree.root.add_child(mgr)

	# 1. Verify puck scripts hold only physics properties (no standalone combat HP/stat fields on BasePuck)
	var raw_puck := BasePuck.new()
	var prop_names: Array[String] = []
	for p in raw_puck.get_property_list():
		prop_names.append(str(p.get("name", "")))
	assert_false(prop_names.has("current_hp"), "current_hp moved out of BasePuck into UnitInformationDO")
	assert_false(prop_names.has("max_hp"), "max_hp moved out of BasePuck into UnitInformationDO")
	assert_false(prop_names.has("attack_damage"), "attack_damage moved out of BasePuck into UnitInformationDO")
	assert_true(prop_names.has("mass") and prop_names.has("radius") and prop_names.has("restitution"),
		"BasePuck retains physics properties (mass, radius, restitution)")
	raw_puck.free()

	# 2. Verify default Enemy Adventurer max HP values at default Unit Lv = 5 (from ClassCodex base + 5 * per_lv):
	#    Guard = 3500, Brawler = 2800, Scout = 2800, Acolyte = 2100
	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_adventurer_team(1, [
		{"unit_id": "u_knight", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT},
		{"unit_id": "u_warrior", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR},
		{"unit_id": "u_ranger", "adventurer_class": EnemyAdventurer.AdventurerClass.RANGER},
		{"unit_id": "u_mage", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE},
	])
	assert_eq(mgr.get_unit("u_knight").max_hp, 3500, "Guard Lv 5 default max HP is 3500")
	assert_eq(mgr.get_unit("u_knight").current_hp, 3500, "Guard starts at 3500 HP in UnitInformationDO")
	assert_eq(mgr.get_unit("u_warrior").max_hp, 2800, "Brawler Lv 5 default max HP is 2800")
	assert_eq(mgr.get_unit("u_ranger").max_hp, 2800, "Scout Lv 5 default max HP is 2800")
	assert_eq(mgr.get_unit("u_mage").max_hp, 2100, "Acolyte Lv 5 default max HP is 2100")

	tree.root.remove_child(mgr)
	mgr.free()


func test_puck_velocity_manager_linear_impulse_collision_damage_matrix_and_frenzy_power() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := Node3D.new()
	tree.root.add_child(root)

	var tm := TimingManager.new()
	tm.name = "TimingManager"
	root.add_child(tm)

	var mgr := _new_manager()
	mgr.name = "UnitInformationManager"
	root.add_child(mgr)

	var pvm := PuckVelocityManager.new()
	pvm.name = "PuckVelocityManager"
	pvm.timing_manager = tm
	root.add_child(pvm)

	var board := _new_board()
	root.add_child(board)
	board.bind_manager(mgr)

	var boss := DragonPlayer.new()
	boss.name = "Player"
	root.add_child(boss)

	var warrior := EnemyAdventurer.new()
	warrior.name = "WarriorPuck"
	warrior.adventurer_class = EnemyAdventurer.AdventurerClass.WARRIOR
	root.add_child(warrior)

	var mage := EnemyAdventurer.new()
	mage.name = "MagePuck"
	mage.adventurer_class = EnemyAdventurer.AdventurerClass.MAGE
	root.add_child(mage)

	var knight := EnemyAdventurer.new()
	knight.name = "KnightPuck"
	knight.adventurer_class = EnemyAdventurer.AdventurerClass.KNIGHT
	root.add_child(knight)

	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "bars_remaining": 15, "max_bars": 15, "puck": boss})
	mgr.register_adventurer_team(1, [
		{"unit_id": "adv_knight", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT, "puck": knight},
		{"unit_id": "adv_warrior", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR, "puck": warrior},
		{"unit_id": "adv_mage", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE, "puck": mage},
	])

	var boss_do = mgr.get_unit("boss_a")
	var warrior_do = mgr.get_unit("adv_warrior")
	var mage_do = mgr.get_unit("adv_mage")
	var knight_do = mgr.get_unit("adv_knight")

	# 1. Boss Monster collides with Warrior at moderate hitting velocity:
	#    Verify damage is linear with Impulse J, lands in ~50..200 range, pushes a DamageDO to Warrior's Damage Stack,
	#    leaves Boss undamaged (only Knights damage Boss on collision), increases Boss Frenzy Power by +10% (to 110%),
	#    and shakes both Warrior's Unit Display and Damage Stack count badge!
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	warrior.global_position = Vector3(1.35, 1.675, 0.0) # combined radius = 0.8 + 0.6 = 1.4
	boss.velocity = Vector3(4.5, 0.0, 0.0)
	warrior.velocity = Vector3.ZERO
	knight.global_position = Vector3(-12.0, 1.7, -8.0)
	mage.global_position = Vector3(12.0, 1.675, -8.0)

	assert_true(pvm.resolve_puck_puck_collision(boss, warrior), "Boss and Warrior collide")
	assert_eq(warrior_do.damage_stack.size(), 1, "Collision pushed 1 DamageDO onto Warrior's Damage Stack")
	var dmg_1: float = float(warrior_do.damage_stack[0].value)
	assert_true(dmg_1 >= 40.0 and dmg_1 <= 250.0, "Collision damage scales with (J / 40) * Boss POW 400 (got %.2f)" % dmg_1)
	assert_eq(warrior_do.damage_stack[0].owner_boss_unit_id, "boss_a", "DamageDO attributes owner_boss_unit_id to boss_a")
	assert_eq(boss_do.damage_stack.size(), 0, "Boss Monster takes no collision damage from non-Knight Warrior")
	assert_true(is_equal_approx(boss_do.frenzy_power, 1.10), "Boss Frenzy Power increased by +10% to 110% on hitting Warrior")
	assert_true(float(board.get_cell_info("R22").get("last_display_shake_amplitude", 0.0)) > 0.0, "Warrior Unit Display shook from collision Impulse")
	assert_true(float(board.get_cell_info("R22").get("last_badge_shake_amplitude", 0.0)) > 0.0, "Warrior Damage Stack badge shook from collision damage")

	# 2. Verify linearity with Impulse: a 2x faster hit produces 2x the collision damage!
	boss.global_position = Vector3(0.0, 1.8, 0.0)
	warrior.global_position = Vector3(1.35, 1.675, 0.0)
	boss.velocity = Vector3(9.0, 0.0, 0.0)
	warrior.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(boss, warrior), "2x speed Boss and Warrior collide")
	assert_eq(warrior_do.damage_stack.size(), 2, "Warrior Damage Stack now has 2 hits")
	var dmg_2: float = float(warrior_do.damage_stack[1].value)
	assert_true(absf(dmg_2 - dmg_1 * 2.0) <= 0.1, "Collision damage scales linearly with Impulse (2x speed -> 2x damage: %.2f vs %.2f)" % [dmg_1, dmg_2])

	# 3. Allied Adventurer vs. Adventurer collision (Warrior knocked into Mage):
	#    Both non-Knight Adventurers take collision damage!
	warrior.global_position = Vector3(5.0, 1.675, 0.0)
	mage.global_position = Vector3(6.1, 1.675, 0.0) # combined radius = 0.6 + 0.55 = 1.15
	warrior.velocity = Vector3(5.0, 0.0, 0.0)
	mage.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(warrior, mage), "Warrior and Mage collide")
	assert_eq(warrior_do.damage_stack.size(), 3, "Warrior took collision damage from hitting Mage")
	assert_eq(mage_do.damage_stack.size(), 1, "Mage took collision damage from being hit by Warrior")

	# 4. Default collision rule (without skills): when a Guard collides with an allied Adventurer (Mage),
	#    both non-Boss pucks take default collision damage (ally damage reduction is handled by SPA10001 Protect skill)!
	var mage_hits_before: int = mage_do.damage_stack.size()
	knight.global_position = Vector3(-5.0, 1.7, 0.0)
	mage.global_position = Vector3(-3.85, 1.675, 0.0) # combined radius = 0.65 + 0.55 = 1.20
	knight.velocity = Vector3(5.0, 0.0, 0.0)
	mage.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(knight, mage), "Guard and allied Mage collide")
	assert_eq(mage_do.damage_stack.size(), mage_hits_before + 1, "Default collision without skill deals collision damage to allied Mage")
	assert_eq(knight_do.damage_stack.size(), 1, "Default collision without skill deals collision damage to Guard")

	# 5. Boss Monster vs. Guard default collision (without skills):
	#    Guard takes collision damage, Boss Monster takes 0 default collision damage, and Boss Frenzy Power increases by +10% baseline!
	var frenzy_before_knight: float = float(boss_do.frenzy_power) # currently 1.20 (from 2 Warrior hits)
	boss.global_position = Vector3(0.0, 1.8, 4.0)
	knight.global_position = Vector3(1.40, 1.7, 4.0) # combined radius = 0.8 + 0.65 = 1.45
	boss.velocity = Vector3(5.0, 0.0, 0.0)
	knight.velocity = Vector3.ZERO
	assert_true(pvm.resolve_puck_puck_collision(boss, knight), "Boss and Guard collide")
	assert_eq(knight_do.damage_stack.size(), 2, "Guard takes collision damage from Boss impact")
	assert_eq(boss_do.damage_stack.size(), 0, "Boss Monster takes 0 default collision damage from Guard impact")
	assert_true(is_equal_approx(boss_do.frenzy_power, frenzy_before_knight),
		"Guard's SPA10001 Protect (Lv 1, X=2 non-Guard teammates -> -10%%) offsets the +10%% baseline on subsequent hit (stays 120%%)")

	# 6. End-to-end Settle Time: when all pucks come to rest in Puck-puck Time!, TimingManager enters Settle Time
	#    and UnitInformationManager settles the Damage Stacks into actual HP reductions!
	assert_eq(warrior_do.current_hp, 2800, "Warrior actual HP is still 2800 before Settle Time")
	mgr.settle_all_damage()
	assert_true(warrior_do.current_hp < 2800, "Warrior HP reduced after Settle Time resolves collision Damage Stack")
	assert_eq(boss_do.current_hp, 1000, "Boss Monster HP remains 1000 when no skill dealt damage to Boss")

	# 7. Pocket Area fall damage & 80% middle respawn:
	#    Give Mage an odd max_hp (1501) -> ceil(1501 / 2.0) = 751 fixed damage, immune to Boss Frenzy (150%) and Hit Level (3)!
	mage_do.max_hp = 1501
	mage_do.current_hp = 1501
	boss_do.frenzy_power = 1.50
	mgr.set_hit_level("adv_mage", 3)
	var pocket_dmg_do: DamageDO = mgr.push_pocket_fall_damage("adv_mage")
	assert_true(pocket_dmg_do != null and pocket_dmg_do.is_fixed, "Pocket fall creates a fixed DamageDO")
	assert_true(is_equal_approx(pocket_dmg_do.value, 751.0), "Pocket fall DamageDO is ceil(1501 / 2.0) = 751")
	assert_eq(mgr.get_preview_damage("adv_mage"), 751, "Fixed pocket fall damage is immune to Hit Level in Ghost HP preview")
	mgr.settle_all_damage()
	assert_eq(mage_do.current_hp, 1501 - 751, "Fixed pocket fall damage is immune to Frenzy Power and Hit Level at Settle Time (1501 - 751 = 750)")
	assert_eq(board.get_cell_info("R32").get("last_settled_hp_change_text"), "-751", "Unit Display shows settled pocket HP change '-751'")

	# 8. Pocketed puck collider disabled in custom collision resolution:
	#    When mage is falling in a Pocket Area, a second puck (warrior) moving into the same Pocket Area must NOT collide with mage!
	mage.begin_pocket_fall(Vector3(-14.0, 1.5, -9.0))
	mage.global_position = Vector3(-14.0, 1.4, -9.0)
	warrior.global_position = Vector3(-14.0, 1.675, -9.0)
	warrior.velocity = Vector3(-4.0, 0.0, -4.0)
	assert_false(pvm.resolve_puck_puck_collision(warrior, mage), "A puck falling in a Pocket Area has its collider disabled and never blocks a second puck entering the same hole")

	# 9. Any non-Boss unit puck hitting a Cushion during Puck-puck Time! increases its Hit Level by +1 in PuckVelocityManager (Boss pucks do not):
	mgr.set_hit_level("adv_warrior", 0)
	warrior.global_position = Vector3(14.8, 1.675, 0.0) # Past right Cushion boundary (15.0 - 0.6 = 14.4)
	warrior.velocity = Vector3(5.0, 0.0, 0.0)
	boss.global_position = Vector3(-14.8, 1.8, 0.0) # Past left Cushion boundary
	boss.velocity = Vector3(-5.0, 0.0, 0.0)
	pvm.step_velocities(0.05, 1.0)
	assert_eq(warrior_do.hit_level, 1, "Non-Boss unit puck hitting a Cushion in PuckVelocityManager increases Hit Level by +1")
	assert_eq(boss_do.hit_level, 0, "Boss Monster puck hitting a Cushion does NOT increase Hit Level")

	tree.root.remove_child(root)
	root.free()


# ----- Ticket 04: Action Tag Turn Countdowns, Defeated & Pocketed Unit Display States, and Skill Popups -----


func test_action_tag_turns_default_3_pocketed_return_countdown_defeated_red_cross_and_skill_popup() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	var board := _new_board()
	if mgr == null or board == null:
		return
	tree.root.add_child(mgr)
	tree.root.add_child(board)

	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_boss("boss_a", "a", {"max_hp": 1000, "current_hp": 1000, "bars_remaining": 15, "max_bars": 15})
	mgr.register_adventurer_team(1, [
		{"unit_id": "adv_knight", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT},
		{"unit_id": "adv_warrior", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR},
	])
	board.bind_manager(mgr)
	board.set_local_role("a")

	# 1. Default next_action_turns variable in UnitInformationDO is 3 and displayed on the lower-right of the Unit Display
	var knight_do = mgr.get_unit("adv_knight")
	assert_eq(knight_do.next_action_turns, 3, "UnitInformationDO next_action_turns defaults to 3")
	var cell_k: Dictionary = board.get_cell_info("R21")
	assert_true(cell_k.get("action_turns_visible", false), "Active Adventurer displays Action Tag turn countdown")
	assert_eq(cell_k.get("action_turns_text"), "3", "Active Adventurer displays default turn countdown '3' on lower-right")
	assert_false(cell_k.get("is_greyed", true), "Active unit is not greyed out")
	assert_false(cell_k.get("red_cross_visible", true), "Active unit does not show red cross")

	# Boss Monster does not show an Action Tag turn countdown
	var cell_boss: Dictionary = board.get_cell_info("L11")
	assert_false(cell_boss.get("action_turns_visible", true), "Boss Monster does not show Action Tag turn countdown")

	# Updating action tag turns (e.g. basic action 2 + active skill 5) updates the Unit Display
	mgr.set_unit_action_turns("adv_knight", [2, 5])
	cell_k = board.get_cell_info("R21")
	assert_eq(cell_k.get("action_turns_text"), "2 / 5", "Unit Display renders basic and skill Action Tag turn integers")

	# 2. Pocketed state: unit turns grey, HP bar remains visible, and pocket return turn countdown (5..1) is shown instead of normal action turns
	mgr.set_unit_pocketed("adv_knight", true, 5)
	cell_k = board.get_cell_info("R21")
	assert_true(cell_k.get("is_greyed", false), "Pocketed unit Unit Display turns grey")
	assert_true(cell_k.get("hp_bar_visible", false), "Pocketed unit keeps its HP bar visible")
	assert_false(cell_k.get("red_cross_visible", true), "Pocketed unit does NOT show red cross mark")
	assert_true(cell_k.get("action_turns_visible", false), "Pocketed unit shows return turn countdown")
	assert_eq(cell_k.get("action_turns_text"), "5", "Pocketed unit shows return countdown '5' in place of normal Action Tag turns")

	# Returning from pocket restores active colour and normal next_action_turns
	mgr.set_unit_pocketed("adv_knight", false, 0)
	mgr.set_unit_action_turns("adv_knight", [3])
	cell_k = board.get_cell_info("R21")
	assert_false(cell_k.get("is_greyed", true), "Returned unit is no longer greyed out")
	assert_eq(cell_k.get("action_turns_text"), "3", "Returned unit shows normal Action Tag turn countdown again")

	# 3. Skill trigger popup on Unit Display
	mgr.trigger_unit_skill_popup("adv_knight", "Shield Wall")
	cell_k = board.get_cell_info("R21")
	assert_eq(cell_k.get("last_skill_popup_text"), "Shield Wall", "Unit Display briefly pops up triggered skill icon/badge")

	# 4. Defeated state (applied at Settle Time):
	#    Unit Display turns grey, displays a red cross mark over the portrait, and hides its HP bar,
	#    Damage Stack count badge, and all Action Tag turn numbers while remaining in its grid cell!
	mgr.push_damage("adv_warrior", 5000.0, "boss_a", "boss_a", "collision")
	assert_true(board.get_cell_info("R22").get("damage_badge_visible", false), "Warrior shows Damage Stack badge before Settle Time")
	mgr.settle_all_damage()

	var warrior_do = mgr.get_unit("adv_warrior")
	assert_true(warrior_do.is_dead, "Warrior is defeated after Settle Time")
	var cell_w: Dictionary = board.get_cell_info("R22")
	assert_true(cell_w.get("occupied", false), "Defeated unit remains in its grid cell R22 until the Wave ends")
	assert_true(cell_w.get("is_greyed", false), "Defeated unit Unit Display turns grey")
	assert_true(cell_w.get("red_cross_visible", false), "Defeated unit displays red cross mark over portrait")
	assert_false(cell_w.get("hp_bar_visible", true), "Defeated unit hides its HP bar")
	assert_false(cell_w.get("damage_badge_visible", true), "Defeated unit hides its Damage Stack count badge")
	assert_false(cell_w.get("action_turns_visible", true), "Defeated unit hides all Action Tag turn numbers")

	tree.root.remove_child(board)
	tree.root.remove_child(mgr)
	board.free()
	mgr.free()


# ----- Ticket 05: Hover Puck Highlighting & Click-to-Inspect Unit Detail Display Popup -----


func test_hover_highlights_zero_to_n_pucks_and_click_opens_localized_unit_detail_display() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mgr := _new_manager()
	var board := _new_board()
	if mgr == null or board == null:
		return
	tree.root.add_child(mgr)
	tree.root.add_child(board)

	var boss_puck := DragonPlayer.new()
	var ranger_puck_1 := EnemyAdventurer.new()
	var ranger_puck_2 := EnemyAdventurer.new()
	tree.root.add_child(boss_puck)
	tree.root.add_child(ranger_puck_1)
	tree.root.add_child(ranger_puck_2)

	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_boss("boss_a", "a", {
		"max_hp": 1000,
		"current_hp": 850,
		"bars_remaining": 14,
		"max_bars": 15,
		"power": 45,
		"frenzy_power": 1.25,
		"puck": boss_puck,
	})
	mgr.register_adventurer_team(1, [
		{
			"unit_id": "adv_ranger",
			"adventurer_class": EnemyAdventurer.AdventurerClass.RANGER,
			"max_hp": 2200,
			"current_hp": 1650,
			"power": 110,
			"skills": ["Rapid Shot", "Evasion"],
			"statuses": ["Haste"],
		},
	])
	mgr.register_puck("adv_ranger", ranger_puck_1)
	mgr.register_puck("adv_ranger", ranger_puck_2)
	mgr.set_hit_level("adv_ranger", 2)

	board.bind_manager(mgr)
	board.set_local_role("a")

	# 1. Hovering a Unit Display highlights all 0..N active pucks linked to that unit; hovering alone does NOT open Unit Detail Display
	assert_false(ranger_puck_1.is_highlighted(), "Ranger puck 1 is not highlighted initially")
	assert_false(ranger_puck_2.is_highlighted(), "Ranger puck 2 is not highlighted initially")
	assert_false(board.is_detail_display_open(), "Unit Detail Display is closed initially")

	board.simulate_cell_hover("R31", true)
	assert_true(ranger_puck_1.is_highlighted(), "Hovering R31 highlights Ranger puck 1")
	assert_true(ranger_puck_2.is_highlighted(), "Hovering R31 highlights Ranger puck 2 (multi-puck unit)")
	assert_true(board.get_cell_info("R31").get("is_hover_highlighted", false), "Hovering R31 highlights the Unit Display box")
	var hovered_scale: Vector2 = board.get_cell_info("R31").get("scale", Vector2.ONE)
	assert_true(hovered_scale.x > 1.05, "Hovering R31 slightly magnifies the Unit Display box")
	assert_false(boss_puck.is_highlighted(), "Boss puck is not highlighted when hovering R31")
	assert_false(board.is_detail_display_open(), "Hovering alone does NOT open Unit Detail Display")

	board.simulate_cell_hover("R31", false)
	assert_false(ranger_puck_1.is_highlighted(), "Moving mouse off R31 clears highlight on Ranger puck 1")
	assert_false(ranger_puck_2.is_highlighted(), "Moving mouse off R31 clears highlight on Ranger puck 2")
	assert_false(board.get_cell_info("R31").get("is_hover_highlighted", true), "Moving mouse off R31 un-highlights the Unit Display box")

	# 2. Clicking a Unit Display opens the Unit Detail Display popup with full localized stats and numeric HP / Max HP
	board.simulate_cell_click("R31")
	assert_true(board.is_detail_display_open(), "Clicking R31 opens Unit Detail Display")
	var detail_r31: Dictionary = board.get_detail_display_info()
	assert_eq(detail_r31.get("unit_id"), "adv_ranger", "Detail Display inspects adv_ranger")
	assert_eq(detail_r31.get("hp_text"), "1650 / 2200", "Detail Display HP bar shows numeric '1650 / 2200'")
	assert_true(detail_r31.get("class_visible", false), "Adventurer Detail Display shows detailed Class name and Class Mark icon")
	assert_eq(detail_r31.get("power_value"), 110, "Detail Display shows Attack Power 110")
	assert_true(absf(float(detail_r31.get("mass_value", 0.0)) - ranger_puck_1.mass) < 0.02, "Detail Display shows Puck Mass")
	assert_true(absf(float(detail_r31.get("radius_value", 0.0)) - ranger_puck_1.radius) < 0.01, "Detail Display shows Puck Radius")
	assert_eq(detail_r31.get("hit_level_value"), 2, "Detail Display shows current Hit Level 2")
	assert_true(str(detail_r31.get("skills_text", "")).contains("Rapid Shot"), "Detail Display lists unit skills")
	assert_true(str(detail_r31.get("statuses_text", "")).contains("Haste"), "Detail Display lists unit statuses")

	# 3. Clicking a different Unit Display (Boss Monster at L11) switches the Unit Detail Display to inspect Boss
	board.simulate_cell_click("L11")
	assert_true(board.is_detail_display_open(), "Unit Detail Display stays open when switching to L11")
	var detail_boss: Dictionary = board.get_detail_display_info()
	assert_eq(detail_boss.get("unit_id"), "boss_a", "Detail Display switched to boss_a")
	assert_true(str(detail_boss.get("hp_text", "")).contains("850 / 1000"), "Boss Detail Display shows numeric HP '850 / 1000'")
	assert_true(str(detail_boss.get("bars_text", "")).contains("14"), "Boss Detail Display shows remaining Health Bar count x14")
	assert_eq(detail_boss.get("frenzy_text"), "125.0%", "Boss Detail Display shows Frenzy Power 125.0%")

	# 4. Clicking the same Unit Display again (or clicking outside) closes the Unit Detail Display
	board.simulate_cell_click("L11")
	assert_false(board.is_detail_display_open(), "Re-clicking the same Unit Display closes Unit Detail Display")

	board.simulate_cell_click("R31")
	assert_true(board.is_detail_display_open(), "Clicking R31 re-opens Unit Detail Display")
	board.close_detail_display()
	assert_false(board.is_detail_display_open(), "Clicking elsewhere closes Unit Detail Display")

	tree.root.remove_child(boss_puck)
	tree.root.remove_child(ranger_puck_1)
	tree.root.remove_child(ranger_puck_2)
	tree.root.remove_child(board)
	tree.root.remove_child(mgr)
	boss_puck.free()
	ranger_puck_1.free()
	ranger_puck_2.free()
	board.free()
	mgr.free()


# ----- Ticket 07 & 08: Multiplayer 2-Player Versus Setup, Snooker Triangles, Player B Aiming, PvP Collision Rules, Unit Sync & Victory Flow -----


func test_multiplayer_pvp_setup_skeleton_boss_snooker_triangles_and_player_b_aiming() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mp_packed := ResourceLoader.load("res://src/multiplayer_scene.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(mp_packed != null, "Multiplayer scene loads")
	if mp_packed == null:
		return

	var host_mgr := mp_packed.instantiate()
	tree.root.add_child(host_mgr)
	var host_fake := FakeTransport.create_host()
	host_mgr.transport = host_fake
	host_mgr.role_selector.host_button.emit_signal("pressed")
	host_mgr.waiting_room.host_name_edit.text = "Alice"
	host_mgr.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	host_mgr.waiting_room.capacity_spin.value = 4
	host_mgr.waiting_room.confirm_button.emit_signal("pressed")

	var bob_mgr := mp_packed.instantiate()
	tree.root.add_child(bob_mgr)
	var bob_fake := FakeTransport.create_peer()
	bob_mgr.transport = bob_fake
	bob_mgr.role_selector.join_button.emit_signal("pressed")
	bob_mgr.role_selector.name_edit.text = "Bob"
	bob_mgr.role_selector.ip_edit.text = "127.0.0.1"
	bob_mgr.role_selector.port_edit.text = "8910"
	bob_mgr.role_selector.join_form_button.emit_signal("pressed")

	host_mgr.waiting_room.start_game_button.emit_signal("pressed")

	var host_bf: Node = host_mgr.battlefield
	var bob_bf: Node = bob_mgr.battlefield
	var uim: UnitInformationManager = host_bf.get_node("UnitInformationManager") as UnitInformationManager
	assert_eq(uim.game_mode, UnitInformationManager.MODE_TWO_PLAYER_VS, "Multiplayer battlefield runs in MODE_TWO_PLAYER_VS")

	# 1. Single-player Enemy1..Enemy10 are removed; Player A Boss at (-6, 3) in L1, Player B Skeleton Boss at (6, -3) in R1
	assert_true(host_bf.get_node_or_null("Enemy1") == null, "Single-player Enemy1 removed in Multiplayer PvP")
	var player_a_puck := host_bf.get_node_or_null("Player") as BasePuck
	var player_b_puck := host_bf.get_node_or_null("PlayerB") as BasePuck
	assert_true(player_a_puck != null and player_b_puck != null, "Both Player A and Player B Boss Monster pucks exist")
	assert_true(Vector2(player_a_puck.global_position.x - (-6.0), player_a_puck.global_position.z - 3.0).length() < 0.05,
		"Player A Boss Monster puck is at original Enemy2 position (-6, 3)")
	assert_true(Vector2(player_b_puck.global_position.x - 6.0, player_b_puck.global_position.z - (-3.0)).length() < 0.05,
		"Player B Boss Monster puck is at original Enemy3 position (6, -3)")

	var boss_a_do := uim.get_unit_at_grid("L11")
	var boss_b_do := uim.get_unit_at_grid("R11")
	assert_true(boss_a_do != null and boss_b_do != null, "L11 holds Player A Boss and R11 holds Player B Boss")
	assert_eq(boss_a_do.reference_mark, "Ω", "Player A Boss mark is Ω")
	assert_eq(boss_b_do.reference_mark, "Ψ", "Player B Boss mark is Ψ")
	assert_true(boss_b_do.avatar_path.ends_with("avatar_boss_skeleton.png"), "Player B Boss uses Skeleton Boss avatar")

	# 2. Verify 6 Adventurers for Player A in L6-L8 (G, B, S, A, F=Brawler, E=Scout) and 6 for Player B in R6-R8 (g, b, s, a, f=Brawler, e=Scout)
	var exp_a_marks := {"L61": "G", "L62": "B", "L71": "S", "L72": "A", "L81": "F", "L82": "E"}
	for gid in exp_a_marks.keys():
		var u := uim.get_unit_at_grid(gid)
		assert_true(u != null, "Player A Adventurer slot %s is occupied" % gid)
		if u != null:
			assert_eq(u.reference_mark, exp_a_marks[gid], "Player A %s has mark %s" % [gid, exp_a_marks[gid]])
			assert_eq(u.owner_seat, "a", "Player A Adventurer owner_seat is 'a'")
	assert_eq(uim.get_unit_at_grid("L81").adventurer_class, EnemyAdventurer.AdventurerClass.BRAWLER, "Player A Free slot (F) is Brawler")
	assert_eq(uim.get_unit_at_grid("L82").adventurer_class, EnemyAdventurer.AdventurerClass.SCOUT, "Player A Extra slot (E) is Scout")

	var exp_b_marks := {"R61": "g", "R62": "b", "R71": "s", "R72": "a", "R81": "f", "R82": "e"}
	for gid in exp_b_marks.keys():
		var u := uim.get_unit_at_grid(gid)
		assert_true(u != null, "Player B Adventurer slot %s is occupied" % gid)
		if u != null:
			assert_eq(u.reference_mark, exp_b_marks[gid], "Player B %s has mark %s" % [gid, exp_b_marks[gid]])
			assert_eq(u.owner_seat, "b", "Player B Adventurer owner_seat is 'b'")
	assert_eq(uim.get_unit_at_grid("R81").adventurer_class, EnemyAdventurer.AdventurerClass.BRAWLER, "Player B Free slot (f) is Brawler")
	assert_eq(uim.get_unit_at_grid("R82").adventurer_class, EnemyAdventurer.AdventurerClass.SCOUT, "Player B Extra slot (e) is Scout")

	# 3. Verify 3D Snooker Triangle geometry:
	#    Player A triangle centered around (-6, -3) facing +X (Vanguard V has largest X; Row 2 Ranger R is on +Z side nearer Player A Boss at (-6, +3))
	var puck_a_v := uim.get_unit_at_grid("L61").pucks[0]
	var puck_a_b := uim.get_unit_at_grid("L62").pucks[0]
	var puck_a_r := uim.get_unit_at_grid("L71").pucks[0]
	var puck_a_s := uim.get_unit_at_grid("L72").pucks[0]
	var puck_a_f := uim.get_unit_at_grid("L81").pucks[0]
	var puck_a_e := uim.get_unit_at_grid("L82").pucks[0]
	assert_true(puck_a_v.global_position.x > puck_a_b.global_position.x and puck_a_b.global_position.x > puck_a_s.global_position.x,
		"Player A triangle faces +X: Row 1 (V) > Row 2 (B, R) > Row 3 (F, S, E)")
	assert_true(puck_a_r.global_position.z > puck_a_b.global_position.z,
		"Player A Row 2 Ranger (R) is on +Z side nearer Player A Boss at (-6, +3)")
	assert_true(puck_a_e.global_position.z > puck_a_s.global_position.z and puck_a_s.global_position.z > puck_a_f.global_position.z,
		"Player A Row 3 has Extra (E, Ranger) on +Z side, Spell (S, Mage) in middle, and Free (F, Warrior) on -Z side")

	#    Player B triangle centered around (6, 3) facing -X (Vanguard v has smallest X; Row 2 Ranger r is on -Z side nearer Player B Boss at (6, -3))
	var puck_b_v := uim.get_unit_at_grid("R61").pucks[0]
	var puck_b_b := uim.get_unit_at_grid("R62").pucks[0]
	var puck_b_r := uim.get_unit_at_grid("R71").pucks[0]
	var puck_b_s := uim.get_unit_at_grid("R72").pucks[0]
	assert_true(puck_b_v.global_position.x < puck_b_b.global_position.x and puck_b_b.global_position.x < puck_b_s.global_position.x,
		"Player B triangle faces -X: Row 1 (v) < Row 2 (b, r) < Row 3 (f, s, e)")
	assert_true(puck_b_r.global_position.z < puck_b_b.global_position.z,
		"Player B Row 2 Ranger (r) is on -Z side nearer Player B Boss at (6, -3)")

	# 4. Player B drag-and-aim controls Player B's Boss puck (PlayerB at (6, 1.8, -3)) and NOT Player A's Boss puck!
	#    Also verify:
	#    - When Player B takes the Playing Right, Player A (Host) sees the "Opponent takes the play!" banner notification!
	#    - When Player B tries to click/drag Player A's Boss puck, Player B's own Boss puck highlights!
	#    - Clicking Pause on Player B syncs pause state across both Host and Player B!
	#    - Returning to Charging Time highlights/alerts the Play button!
	bob_bf.play_button.emit_signal("pressed")
	assert_eq(host_bf.active_player, "b", "Player B claims Playing Right")
	assert_true(host_bf.puck_puck_banner.visible and host_bf.banner_label.text == Loc.t("pvp_opponent_takes_play"),
		"Opponent (Player A) sees 'Opponent takes the play!' banner when Player B claims Playing Right")

	var bob_boss_puck := bob_bf.get_node("PlayerB") as BasePuck
	var bob_boss_pos := bob_boss_puck.global_position
	var alice_boss_pos := (bob_bf.get_node("Player") as Node3D).global_position
	assert_false(bob_boss_puck.is_highlighted(), "Player B Boss puck is not highlighted before wrong click")
	assert_false(bob_bf.cue_shot_manager.begin_drag(alice_boss_pos), "Player B cannot drag from Player A's Boss puck")
	assert_true(bob_boss_puck.is_highlighted(), "Clicking opponent's Boss puck highlights Player B's own Boss puck for 1s")

	# Test multiplayer Pause synchronization: Bob clicks Pause -> both Host and Bob pause & show "Paused" in the middle; Host clicks Pause -> both resume & hide "Paused"!
	assert_false(host_bf.timing_manager.is_paused(), "Host starts unpaused")
	assert_false(bob_bf.timing_manager.is_paused(), "Bob starts unpaused")
	assert_false(host_bf.is_paused_banner_visible(), "Paused center message hidden when unpaused")
	bob_bf.pause_button.emit_signal("pressed")
	assert_true(host_bf.timing_manager.is_paused(), "Bob clicking Pause pauses Host TimingManager")
	assert_true(bob_bf.timing_manager.is_paused(), "Bob clicking Pause pauses Bob TimingManager")
	assert_true(host_bf.is_paused_banner_visible() and bob_bf.is_paused_banner_visible(),
		"Both Host and Bob display 'Paused' message in the middle of the screen while paused")
	host_bf.pause_button.emit_signal("pressed")
	assert_false(host_bf.timing_manager.is_paused(), "Host clicking Resume unpauses Host")
	assert_false(bob_bf.timing_manager.is_paused(), "Host clicking Resume unpauses Bob")
	assert_false(host_bf.is_paused_banner_visible() or bob_bf.is_paused_banner_visible(),
		"'Paused' center message hides on both Host and Bob when resumed")

	# Cancel Play back to Charging Time -> Play button alert triggers on both Host and Bob, then re-enter Play Time to shoot
	var host_alerts_before: int = host_bf.get_play_button_alert_count()
	var bob_alerts_before: int = bob_bf.get_play_button_alert_count()
	bob_bf.play_button.emit_signal("pressed") # Cancel Play
	assert_eq(host_bf.timing_manager.get_current_timing(), TimingManager.TIMING_CHARGING, "Returned to Charging Time on Cancel")
	assert_true(host_bf.get_play_button_alert_count() > host_alerts_before, "Host Play button highlighted on returning to Charging Time")
	assert_true(bob_bf.get_play_button_alert_count() > bob_alerts_before, "Bob Play button highlighted on returning to Charging Time")

	bob_bf.play_button.emit_signal("pressed")
	assert_true(bob_bf.cue_shot_manager.begin_drag(bob_boss_pos), "Player B begins drag from Player B's Boss puck at (6, -3)")
	bob_bf.cue_shot_manager.update_drag(bob_boss_pos + Vector3(2.65, 0.0, 0.0)) # Aiming -X with cost 3.0
	assert_true(bob_bf.cue_shot_manager.release_drag(), "Player B launches Player B's Boss puck")
	assert_true(player_b_puck.velocity.length() > 1.0, "Host launched Player B's Boss puck")
	assert_true(player_a_puck.velocity.is_zero_approx(), "Player A's Boss puck remained stationary")

	tree.root.remove_child(bob_mgr)
	tree.root.remove_child(host_mgr)
	bob_mgr.free()
	host_mgr.free()
	FakeTransport.reset_registry()


func test_multiplayer_pvp_collision_rules_unit_info_sync_and_victory_return_to_waiting_room() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var mp_packed := ResourceLoader.load("res://src/multiplayer_scene.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if mp_packed == null:
		return

	var host_mgr := mp_packed.instantiate()
	tree.root.add_child(host_mgr)
	var host_fake := FakeTransport.create_host()
	host_mgr.transport = host_fake
	host_mgr.role_selector.host_button.emit_signal("pressed")
	host_mgr.waiting_room.host_name_edit.text = "Alice"
	host_mgr.waiting_room.host_name_edit.emit_signal("text_changed", "Alice")
	host_mgr.waiting_room.capacity_spin.value = 4
	host_mgr.waiting_room.confirm_button.emit_signal("pressed")

	var bob_mgr := mp_packed.instantiate()
	tree.root.add_child(bob_mgr)
	var bob_fake := FakeTransport.create_peer()
	bob_mgr.transport = bob_fake
	bob_mgr.role_selector.join_button.emit_signal("pressed")
	bob_mgr.role_selector.name_edit.text = "Bob"
	bob_mgr.role_selector.ip_edit.text = "127.0.0.1"
	bob_mgr.role_selector.port_edit.text = "8910"
	bob_mgr.role_selector.join_form_button.emit_signal("pressed")

	host_mgr.waiting_room.start_game_button.emit_signal("pressed")

	var host_bf: Node = host_mgr.battlefield
	var bob_bf: Node = bob_mgr.battlefield
	var host_uim: UnitInformationManager = host_bf.get_node("UnitInformationManager") as UnitInformationManager
	var bob_uim: UnitInformationManager = bob_bf.get_node("UnitInformationManager") as UnitInformationManager
	var host_pvm: PuckVelocityManager = host_bf.puck_velocity_manager

	var boss_a_do := host_uim.get_unit_at_grid("L11")
	var boss_b_do := host_uim.get_unit_at_grid("R11")
	var boss_a_puck := boss_a_do.pucks[0]
	var boss_b_puck := boss_b_do.pucks[0]

	# Move all adventurer pucks out of the way first so we can test isolated collisions cleanly
	for u in host_uim.get_all_units():
		if u.unit_kind == "enemy_adventurer" and not u.pucks.is_empty():
			u.pucks[0].global_position = Vector3(-13.0, 1.675, -8.5)

	# 1. Friendly fire vs. Opponent collision damage:
	#    Player A Boss (Frenzy = 150%) hits:
	#      (a) Friendly Player A Warrior (L62) at speed 6.0 -> deals 1/4 (0.25x) damage, skips Frenzy change (stays 150%),
	#          and settles with 100% Frenzy (no 1.5x multiplier!).
	#      (b) Opponent Player B Warrior (R62) at the exact same speed 6.0 -> deals full (1.0x) damage,
	#          increases Player A Boss Frenzy by +10% (to 160%), and settles with Player A Boss's Frenzy multiplier!
	host_uim.set_frenzy_power(boss_a_do.unit_id, 1.50)
	var friendly_w_do := host_uim.get_unit_at_grid("L62")
	var opponent_w_do := host_uim.get_unit_at_grid("R62")
	var friendly_w_puck := friendly_w_do.pucks[0]
	var opponent_w_puck := opponent_w_do.pucks[0]

	boss_a_puck.global_position = Vector3(0.0, 1.8, 0.0)
	friendly_w_puck.global_position = Vector3(1.35, 1.675, 0.0)
	boss_a_puck.velocity = Vector3(6.0, 0.0, 0.0)
	friendly_w_puck.velocity = Vector3.ZERO
	assert_true(host_pvm.resolve_puck_puck_collision(boss_a_puck, friendly_w_puck), "Boss A hits friendly Warrior")
	assert_true(is_equal_approx(boss_a_do.frenzy_power, 1.50), "Friendly hit skips Frenzy Power change (stays 150%)")
	var friendly_dmg_val: float = friendly_w_do.damage_stack[0].value
	assert_eq(friendly_w_do.damage_stack[0].owner_boss_unit_id, "", "Friendly DamageDO uses 100% baseline Frenzy (empty owner_boss_unit_id)")

	friendly_w_puck.global_position = Vector3(-13.0, 1.675, -8.5)
	friendly_w_puck.velocity = Vector3.ZERO
	boss_a_puck.global_position = Vector3(0.0, 1.8, 0.0)
	opponent_w_puck.global_position = Vector3(1.35, 1.675, 0.0)
	boss_a_puck.velocity = Vector3(6.0, 0.0, 0.0)
	opponent_w_puck.velocity = Vector3.ZERO
	assert_true(host_pvm.resolve_puck_puck_collision(boss_a_puck, opponent_w_puck), "Boss A hits opponent Warrior")
	assert_true(is_equal_approx(boss_a_do.frenzy_power, 1.60), "Opponent non-Knight hit increases Boss A Frenzy Power by +10% to 160%")
	var opponent_dmg_val: float = opponent_w_do.damage_stack[0].value
	assert_true(absf(friendly_dmg_val - opponent_dmg_val * 0.25) < 0.05,
		"Friendly collision damage is exactly 1/4 of opponent collision damage (%.2f vs %.2f)" % [friendly_dmg_val, opponent_dmg_val])

	# 2. Player B's Boss puck deals full damage to Player A's Adventurer even during a Puck-puck Time! triggered by Player A!
	opponent_w_puck.global_position = Vector3(-13.0, 1.675, -8.5)
	opponent_w_puck.velocity = Vector3.ZERO
	host_bf.active_player = "a"
	boss_b_puck.global_position = Vector3(0.0, 1.8, 4.0)
	friendly_w_puck.global_position = Vector3(1.35, 1.675, 4.0)
	boss_b_puck.velocity = Vector3(6.0, 0.0, 0.0)
	friendly_w_puck.velocity = Vector3.ZERO
	assert_true(host_pvm.resolve_puck_puck_collision(boss_b_puck, friendly_w_puck), "Boss B hits Player A's Warrior during Player A's turn")
	assert_eq(friendly_w_do.damage_stack.size(), 2, "Player A's Warrior receives a 2nd DamageDO from Boss B")
	assert_true(absf(friendly_w_do.damage_stack[1].value - opponent_dmg_val) < 0.05,
		"Boss B deals full 1.0x damage to Player A's Warrior even on Player A's turn")

	# 3. Boss Monster vs. Opponent Boss Monster collision:
	#    - 0 damage to both Boss Monsters
	#    - Both Boss pucks' post-collision velocities are multiplied by 20% (0.2x)
	#    - Opponent gains +3 Energy at most ONCE per Puck-puck Time!
	friendly_w_puck.global_position = Vector3(-13.0, 1.675, -8.5)
	friendly_w_puck.velocity = Vector3.ZERO
	host_bf.set_player_energy("a", 10.0)
	host_bf.set_player_energy("b", 10.0)
	host_bf.active_player = "a"
	host_pvm.reset_puck_puck_turn_state()

	boss_a_puck.global_position = Vector3(0.0, 1.8, 0.0)
	boss_b_puck.global_position = Vector3(1.55, 1.8, 0.0) # combined radius = 0.8 + 0.8 = 1.6
	boss_a_puck.velocity = Vector3(10.0, 0.0, 0.0)
	boss_b_puck.velocity = Vector3.ZERO
	assert_true(host_pvm.resolve_puck_puck_collision(boss_a_puck, boss_b_puck), "Boss A collides with Boss B")
	assert_eq(boss_a_do.damage_stack.size(), 0, "Boss A takes 0 damage from Boss-vs-Boss collision")
	assert_eq(boss_b_do.damage_stack.size(), 0, "Boss B takes 0 damage from Boss-vs-Boss collision")
	# Without 20% damping, equal-mass collision at v1=10, e=0.85 would give v2f = 9.25; with * 0.20 damping, both speeds are < 2.0!
	assert_true(boss_a_puck.velocity.length() < 2.0 and boss_b_puck.velocity.length() < 2.0,
		"Both Boss pucks lose 80% velocity (multiplied by 20%) immediately after Boss-vs-Boss collision")
	assert_true(is_equal_approx(host_bf.get_player_energy("b"), 13.0),
		"Opponent (Player B) gained +3 Energy (10.0 -> 13.0) from Boss-vs-Boss collision")

	# Colliding a second time in the SAME Puck-puck Time! does NOT grant +3 Energy a second time
	boss_a_puck.global_position = Vector3(0.0, 1.8, 0.0)
	boss_b_puck.global_position = Vector3(1.55, 1.8, 0.0)
	boss_a_puck.velocity = Vector3(8.0, 0.0, 0.0)
	boss_b_puck.velocity = Vector3.ZERO
	assert_true(host_pvm.resolve_puck_puck_collision(boss_a_puck, boss_b_puck), "2nd Boss-vs-Boss collision in same Puck-puck Time!")
	assert_true(is_equal_approx(host_bf.get_player_energy("b"), 13.0),
		"Opponent Energy bonus (+3) triggers at most once per Puck-puck Time! (stays 13.0)")

	# 4. Unit Information synchronization from Host to Peer (Bob):
	#    Verify Bob's UnitInformationManager and UnitInformationBoard reflect the staged Damage Stack and settled HP!
	host_bf.sync_units()
	host_bf.sync_boss_stats()
	assert_eq(bob_uim.get_unit_at_grid("R62").get_damage_stack_count(), 1, "Peer (Bob) synced Damage Stack count 1 on R62")
	assert_true(is_equal_approx(bob_uim.get_unit_at_grid("L11").frenzy_power, 1.60), "Peer (Bob) synced Boss A Frenzy Power 160.0%")

	host_uim.settle_all_damage()
	host_bf.sync_units()
	host_bf.sync_boss_stats()
	assert_eq(bob_uim.get_unit_at_grid("R62").current_hp, opponent_w_do.current_hp,
		"Peer (Bob) synced settled HP on R62 (%d)" % opponent_w_do.current_hp)

	# 5. Multiplayer Victory Flow:
	#    Knock out all 6 of Player B's Adventurers (R61..R82) on the Host and settle ->
	#    "Player A win" message is shown on both Host and Bob, and after 5 seconds everyone returns to the Waiting Room!
	for gid in ["R61", "R62", "R71", "R72", "R81", "R82"]:
		var u_b := host_uim.get_unit_at_grid(gid)
		host_uim.push_damage(u_b.unit_id, 9999.0, boss_a_do.unit_id, boss_a_do.unit_id, "collision")
	host_bf.resolve_settle_and_check_pvp_winner()

	assert_eq(host_bf.pvp_winner_seat, "a", "Host declares Player A the winner when all 6 of Player B's Adventurers are defeated")
	assert_eq(bob_bf.pvp_winner_seat, "a", "Peer (Bob) receives synced winner seat 'a'")
	assert_true(host_bf.get_win_banner_text().contains("Player A"), "Host displays 'Player A win' message")
	assert_true(host_bf.get_win_banner_text().contains("5"), "Host win banner displays 'return in 5 second' countdown")
	assert_true(bob_bf.get_win_banner_text().contains("Player A"), "Peer (Bob) displays 'Player A win' message")
	assert_true(bob_bf.get_win_banner_text().contains("5"), "Peer (Bob) win banner displays 'return in 5 second' countdown")
	assert_true(host_mgr.battlefield != null, "Battlefield stays open during the 5-second victory display")

	# Advance 2.0 seconds -> countdown updates to 3 seconds remaining
	host_bf._process(2.0)
	bob_bf._process(2.0)
	assert_true(host_bf.get_win_banner_text().contains("3"), "Countdown updates to 'return in 3 second' after 2.0s")

	# Advance remaining 3.1 seconds on Host -> automatically finishes battle and returns all Peers to the Waiting Room!
	host_bf._process(3.1)
	assert_true(host_mgr.battlefield == null and host_mgr.waiting_room.visible,
		"Host returns to the Waiting Room after 5 seconds")
	assert_true(bob_mgr.battlefield == null and bob_mgr.waiting_room.visible,
		"Peer (Bob) returns to the Waiting Room after 5 seconds")

	tree.root.remove_child(bob_mgr)
	tree.root.remove_child(host_mgr)
	bob_mgr.free()
	host_mgr.free()
	FakeTransport.reset_registry()
