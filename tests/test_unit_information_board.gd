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

	# Register Team 1 (full 6 members: Knight, Warrior, Ranger, Mage + 2 distinct duplicate classes at ?5 and ?6)
	var team1_units: Array = mgr.register_adventurer_team(1, [
		{"unit_id": "t1_k", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT},
		{"unit_id": "t1_w", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR},
		{"unit_id": "t1_r", "adventurer_class": EnemyAdventurer.AdventurerClass.RANGER},
		{"unit_id": "t1_m", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE},
		{"unit_id": "t1_dup1", "adventurer_class": EnemyAdventurer.AdventurerClass.WARRIOR},
		{"unit_id": "t1_dup2", "adventurer_class": EnemyAdventurer.AdventurerClass.RANGER},
	])
	assert_eq(team1_units.size(), 6, "Team 1 registered 6 adventurers")
	assert_eq(mgr.get_unit_at_grid("R21").reference_mark, "A1", "Knight maps to ?1 -> A1 at R21")
	assert_eq(mgr.get_unit_at_grid("R21").slot_color, mgr.COLOR_SLOT_1_BLUE, "?1 colour is Blue")
	assert_eq(mgr.get_unit_at_grid("R22").reference_mark, "A2", "Warrior maps to ?2 -> A2 at R22")
	assert_eq(mgr.get_unit_at_grid("R22").slot_color, mgr.COLOR_SLOT_2_RED, "?2 colour is Red")
	assert_eq(mgr.get_unit_at_grid("R31").reference_mark, "A3", "Ranger maps to ?3 -> A3 at R31")
	assert_eq(mgr.get_unit_at_grid("R31").slot_color, mgr.COLOR_SLOT_3_YELLOW, "?3 colour is Yellow")
	assert_eq(mgr.get_unit_at_grid("R32").reference_mark, "A4", "Mage maps to ?4 -> A4 at R32")
	assert_eq(mgr.get_unit_at_grid("R32").slot_color, mgr.COLOR_SLOT_4_PURPLE, "?4 colour is Purple")
	assert_eq(mgr.get_unit_at_grid("R41").reference_mark, "A5", "1st duplicate maps to ?5 -> A5 at R41")
	assert_eq(mgr.get_unit_at_grid("R41").slot_color, mgr.COLOR_SLOT_5_GREEN, "?5 colour is Green")
	assert_eq(mgr.get_unit_at_grid("R42").reference_mark, "A6", "2nd duplicate maps to ?6 -> A6 at R42")
	assert_eq(mgr.get_unit_at_grid("R42").slot_color, mgr.COLOR_SLOT_6_ORANGE, "?6 colour is Orange")
	assert_eq(mgr.get_unit_at_grid("R21").reference_mark_color, mgr.COLOR_MARK_TEAM1_GREY, "Team 1 Reference Mark colour is Deep Grey")
	assert_true(mgr.get_unit_at_grid("R22").avatar_path != mgr.get_unit_at_grid("R41").avatar_path, "Duplicate Warrior gets a distinct avatar image from the first Warrior")

	# Register Team 2 with a missing Warrior (?2) and missing Ranger (?3): only Knight, Mage, and a duplicate Mage!
	# Missing class slots R62 (B2) and R71 (B3) must stay empty rather than compacting!
	mgr.register_adventurer_team(2, [
		{"unit_id": "t2_k", "adventurer_class": EnemyAdventurer.AdventurerClass.KNIGHT},
		{"unit_id": "t2_m", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE},
		{"unit_id": "t2_m2", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE},
	])
	assert_true(mgr.get_unit_at_grid("R61") != null, "Team 2 Knight is at R61 (B1)")
	assert_eq(mgr.get_unit_at_grid("R61").reference_mark, "B1", "Team 2 Knight Reference Mark is B1")
	assert_eq(mgr.get_unit_at_grid("R61").reference_mark_color, mgr.COLOR_MARK_TEAM2_BROWN, "Team 2 Reference Mark colour is Deep Brown")
	assert_true(mgr.get_unit_at_grid("R62") == null, "Missing Warrior leaves R62 (B2) empty (not compacted)")
	assert_true(mgr.get_unit_at_grid("R71") == null, "Missing Ranger leaves R71 (B3) empty (not compacted)")
	assert_true(mgr.get_unit_at_grid("R72") != null, "Team 2 Mage is at R72 (B4)")
	assert_eq(mgr.get_unit_at_grid("R72").reference_mark, "B4", "Team 2 Mage Reference Mark is B4")
	assert_true(mgr.get_unit_at_grid("R81") != null, "Duplicate Mage takes first free position R81 (B5)")
	assert_eq(mgr.get_unit_at_grid("R81").reference_mark, "B5", "Duplicate Mage Reference Mark is B5")
	assert_true(mgr.get_unit_at_grid("R82") == null, "Unused 6th slot R82 (B6) stays empty")

	tree.root.remove_child(mgr)
	mgr.free()


func test_custom_stage_override_and_2p_coop_and_2p_versus_layouts() -> void:
	var mgr := _new_manager()
	if mgr == null:
		return

	# 1. Custom stage override: explicitly place a Mage in slot 1 (A1 / R21)
	mgr.configure_mode(mgr.MODE_SINGLE_PLAYER)
	mgr.register_adventurer_team(1, [
		{"unit_id": "custom_mage_slot1", "adventurer_class": EnemyAdventurer.AdventurerClass.MAGE, "slot_override": 1},
	])
	var custom_u = mgr.get_unit_at_grid("R21")
	assert_true(custom_u != null, "Custom stage override places Mage in slot 1 (R21)")
	assert_eq(custom_u.reference_mark, "A1", "Custom slot 1 unit gets A1 Reference Mark")
	assert_eq(custom_u.adventurer_class, EnemyAdventurer.AdventurerClass.MAGE, "Custom slot 1 unit keeps Mage class")
	assert_eq(custom_u.slot_color, mgr.COLOR_SLOT_1_BLUE, "Custom slot 1 unit gets slot 1 Blue border/puck colour")

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
		{"unit_id": "ranger_a3", "adventurer_class": EnemyAdventurer.AdventurerClass.RANGER},
	])
	var unit_do = mgr.get_unit("ranger_a3")
	assert_eq(unit_do.pucks.size(), 0, "Unit starts with 0 pucks before pucks are linked")

	var puck1 := EnemyAdventurer.new()
	var puck2 := EnemyAdventurer.new()
	mgr.register_puck("ranger_a3", puck1)
	mgr.register_puck("ranger_a3", puck2)
	assert_eq(unit_do.pucks.size(), 2, "Unit holds 2 active pucks simultaneously")
	assert_eq(puck1.get_reference_mark(), "A3", "Puck 1 carries unit Reference Mark A3")
	assert_eq(puck2.get_reference_mark(), "A3", "Puck 2 carries unit Reference Mark A3")
	assert_eq(puck1.get_slot_color(), mgr.COLOR_SLOT_3_YELLOW, "Puck 1 receives slot 3 Yellow colour")
	assert_eq(puck2.get_slot_color(), mgr.COLOR_SLOT_3_YELLOW, "Puck 2 receives slot 3 Yellow colour")

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
	assert_eq(cell_l1.get("frenzy_text"), "130%", "L11 shows Player A Boss Frenzy Power on right side")
	assert_false(cell_l1.get("hp_bar_visible", true), "Local Player A's own Boss Unit Display omits HP bar")

	assert_true(cell_l5.get("occupied", false), "L51 is occupied by Player B Boss")
	assert_eq(cell_l5.get("reference_mark"), "Ψ", "L51 shows Reference Mark Ψ")
	assert_eq(cell_l5.get("frenzy_text"), "110%", "L51 shows Player B Boss Frenzy Power on right side")
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

	# 3. Verify Team 1 Header at R11 and Adventurer cells at R21 (A1) & R22 (A2), and empty R31
	var cell_r1: Dictionary = board.get_cell_info("R11")
	assert_true(cell_r1.get("is_team_header", false), "R11 is Adventurer Team 1 header span")
	var cell_r21: Dictionary = board.get_cell_info("R21")
	assert_true(cell_r21.get("occupied", false), "R21 is occupied by A1 Knight")
	assert_eq(cell_r21.get("reference_mark"), "A1", "R21 shows A1")
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
