extends McpTestSuite

## Ticket 01 tests:
## - Class Codex Registry (all 28 Rank 1-3 classes ACG10001..ACA30004, prerequisite inheritance, base + Lv * per_lv stats)
## - UnitSkillManager (trigger-time-to-skills map, Statistic Buff/Debuff recalculation: summed % before flat +, HP clamp)
## - UnitSkill hierarchy (MoveSkill, AttackSkill, ActiveSkill, PassiveSkill; SMA/SAA/SPA10001..10004 loadouts at Unit Lv=5, Skill Lv=1)
## - UnitDetailDisplay 2-row skill icon layout (Row 1: Move | Attack | Active with empty 3rd slot; Row 2: Passives) & hover Skill Display tooltip (resolved variables, *keyword* highlights, keyword glossary at bottom, no raw Effects text)

const CLASS_CODEX_PATH := "res://src/enemies/class_codex.gd"
const UNIT_SKILL_PATH := "res://src/skills/unit_skill.gd"
const UNIT_SKILL_MANAGER_PATH := "res://src/battlefield/unit_skill_manager.gd"
const UNIT_INFO_MANAGER_PATH := "res://src/battlefield/unit_information_manager.gd"
const UNIT_INFO_BOARD_PATH := "res://src/canvas/unit_information_board.gd"


func suite_name() -> String:
	return "enemy-adventurers-codex-and-skills"


func test_class_codex_registers_28_classes_with_prerequisite_inheritance_and_linear_stat_formula() -> void:
	assert_true(ResourceLoader.exists(CLASS_CODEX_PATH), "ClassCodex script exists")
	if not ResourceLoader.exists(CLASS_CODEX_PATH):
		return
	var codex_script := load(CLASS_CODEX_PATH)

	# 1. All 28 Rank 1-3 common classes are registered (4 Rank-1 + 8 Rank-2 + 16 Rank-3)
	var all_ids: Array = codex_script.get_all_class_ids()
	assert_eq(all_ids.size(), 28, "ClassCodex registers all 28 Rank 1-3 classes")
	for expected_id in [
		"ACG10001", "ACG20001", "ACG20002", "ACG30001", "ACG30002", "ACG30003", "ACG30004",
		"ACB10001", "ACB20001", "ACB20002", "ACB30001", "ACB30002", "ACB30003", "ACB30004",
		"ACS10001", "ACS20001", "ACS20002", "ACS30001", "ACS30002", "ACS30003", "ACS30004",
		"ACA10001", "ACA20001", "ACA20002", "ACA30001", "ACA30002", "ACA30003", "ACA30004",
	]:
		assert_true(all_ids.has(expected_id), "ClassCodex contains %s" % expected_id)

	# 2. Verify linear stat calculation at Lv 5 (stat = base + Lv * per_lv):
	#    - Guard (ACG10001): 2250/180/100 + 250/20/5 -> Lv 5: 3500 HP, 280 POW, 125 SPD, mass 1.75, radius 0.65, cd 4
	#    - Brawler (ACB10001): 1800/180/135 + 200/20/5 -> Lv 5: 2800 HP, 280 POW, 160 SPD, mass 1.50, radius 0.60, cd 4
	#    - Scout (ACS10001): 1800/180/120 + 200/20/5 -> Lv 5: 2800 HP, 280 POW, 145 SPD, mass 1.35, radius 0.57, cd 3
	#    - Acolyte (ACA10001): 1350/180/115 + 150/20/5 -> Lv 5: 2100 HP, 280 POW, 140 SPD, mass 1.25, radius 0.55, cd 6
	var g_lv5: Dictionary = codex_script.calculate_stats("ACG10001", 5)
	assert_eq(g_lv5.get("max_hp"), 3500, "Guard Lv 5 max_hp is 2250 + 5*250 = 3500")
	assert_eq(g_lv5.get("power"), 280, "Guard Lv 5 power is 180 + 5*20 = 280")
	assert_eq(g_lv5.get("spd"), 125, "Guard Lv 5 spd is 100 + 5*5 = 125")
	assert_true(is_equal_approx(float(g_lv5.get("mass", 0.0)), 1.75), "Guard mass is 1.75")
	assert_true(is_equal_approx(float(g_lv5.get("radius", 0.0)), 0.65), "Guard radius is 0.65")
	assert_eq(g_lv5.get("action_countdown"), 4, "Guard action_countdown is 4")

	var b_lv5: Dictionary = codex_script.calculate_stats("ACB10001", 5)
	assert_eq(b_lv5.get("max_hp"), 2800, "Brawler Lv 5 max_hp is 1800 + 5*200 = 2800")
	assert_eq(b_lv5.get("power"), 280, "Brawler Lv 5 power is 180 + 5*20 = 280")
	assert_eq(b_lv5.get("spd"), 160, "Brawler Lv 5 spd is 135 + 5*5 = 160 (faster than Scout/Acolyte/Guard)")
	assert_eq(b_lv5.get("action_countdown"), 4, "Brawler action_countdown is 4")

	var s_lv5: Dictionary = codex_script.calculate_stats("ACS10001", 5)
	assert_eq(s_lv5.get("max_hp"), 2800, "Scout Lv 5 max_hp is 1800 + 5*200 = 2800")
	assert_eq(s_lv5.get("power"), 280, "Scout Lv 5 power is 180 + 5*20 = 280")
	assert_eq(s_lv5.get("spd"), 145, "Scout Lv 5 spd is 120 + 5*5 = 145")
	assert_eq(s_lv5.get("action_countdown"), 3, "Scout action_countdown is 3")

	var a_lv5: Dictionary = codex_script.calculate_stats("ACA10001", 5)
	assert_eq(a_lv5.get("max_hp"), 2100, "Acolyte Lv 5 max_hp is 1350 + 5*150 = 2100")
	assert_eq(a_lv5.get("power"), 280, "Acolyte Lv 5 power is 180 + 5*20 = 280")
	assert_eq(a_lv5.get("spd"), 140, "Acolyte Lv 5 spd is 115 + 5*5 = 140")
	assert_eq(a_lv5.get("action_countdown"), 6, "Acolyte action_countdown is 6")

	# Also verify the Codex example at Lv 2 for Acolyte (1350/180/115 + 150/20/5 -> 1650/220/125)
	var a_lv2: Dictionary = codex_script.calculate_stats("ACA10001", 2)
	assert_eq(a_lv2.get("max_hp"), 1650, "Acolyte Lv 2 max_hp is 1650")
	assert_eq(a_lv2.get("power"), 220, "Acolyte Lv 2 power is 220")
	assert_eq(a_lv2.get("spd"), 125, "Acolyte Lv 2 spd is 125")

	# 3. Verify Rank 2 and Rank 3 prerequisite inheritance (Paladin ACG30003 -> Knight ACG20002 -> Guard ACG10001):
	var paladin_entry: Dictionary = codex_script.get_class_entry("ACG30003")
	assert_eq(paladin_entry.get("rank"), 3, "Paladin is Rank 3")
	assert_eq(paladin_entry.get("from_class_id"), "ACG20002", "Paladin direct prerequisite is Knight (ACG20002)")
	assert_eq(paladin_entry.get("class_tree"), "guard", "Paladin belongs to Guard tree")
	assert_true(is_equal_approx(float(paladin_entry.get("mass", 0.0)), 1.75), "Paladin inherits Guard mass 1.75")
	assert_true(is_equal_approx(float(paladin_entry.get("radius", 0.0)), 0.65), "Paladin inherits Guard radius 0.65")
	var paladin_skills: Array = paladin_entry.get("base_skill_ids", [])
	assert_true(paladin_skills.has("SPA10001"), "Paladin inherits Base Passive Skill SPA10001 Protect from Guard")
	var paladin_lv5: Dictionary = codex_script.calculate_stats("ACG30003", 5)
	assert_eq(paladin_lv5.get("max_hp"), 3500, "Paladin inherits Guard stat formula (3500 HP at Lv 5)")


func test_unit_skill_manager_trigger_map_and_statistic_buff_debuff_pipeline() -> void:
	assert_true(ResourceLoader.exists(UNIT_SKILL_MANAGER_PATH), "UnitSkillManager script exists")
	if not ResourceLoader.exists(UNIT_SKILL_MANAGER_PATH):
		return
	var tree := Engine.get_main_loop() as SceneTree
	var uim_script := load(UNIT_INFO_MANAGER_PATH)
	var usm_script := load(UNIT_SKILL_MANAGER_PATH)
	var uim: UnitInformationManager = uim_script.new()
	var usm = usm_script.new()
	tree.root.add_child(uim)
	tree.root.add_child(usm)
	usm.bind_unit_information_manager(uim)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	var team := uim.register_adventurer_team(1, [
		{"unit_id": "u_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD},
		{"unit_id": "u_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER},
		{"unit_id": "u_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
		{"unit_id": "u_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
	])
	assert_eq(team.size(), 4, "4 Adventurers registered")

	var g_do := uim.get_unit("u_guard")
	var b_do := uim.get_unit("u_brawler")
	var s_do := uim.get_unit("u_scout")
	var a_do := uim.get_unit("u_acolyte")

	# 1. Verify default Unit Lv = 5, Skill Lv = 1, and Lv-scaled base stats on UnitInformationDO
	assert_eq(g_do.unit_lv, 5, "Default demo Adventurer unit_lv is 5")
	assert_eq(g_do.base_max_hp, 3500, "Guard base_max_hp at Lv 5 is 3500")
	assert_eq(g_do.max_hp, 3500, "Guard effective max_hp starts at 3500")
	assert_eq(g_do.base_power, 280, "Guard base_power at Lv 5 is 280")
	assert_eq(g_do.power, 280, "Guard effective power starts at 280")
	assert_eq(g_do.base_spd, 125, "Guard base_spd at Lv 5 is 125")
	assert_eq(g_do.spd, 125, "Guard effective spd starts at 125")
	assert_eq(b_do.spd, 160, "Brawler effective spd at Lv 5 is 160")
	assert_eq(s_do.spd, 145, "Scout effective spd at Lv 5 is 145")
	assert_eq(a_do.spd, 140, "Acolyte effective spd at Lv 5 is 140")

	# 2. Verify Skill Countdown initialization (starts at full value, not 0):
	#    Guard's SAA10001 Lance starts at 9; Acolyte's SAA10004 Spell Attack starts at 12
	var g_attack = usm.get_unit_attack_skill("u_guard")
	var a_attack = usm.get_unit_attack_skill("u_acolyte")
	assert_true(g_attack != null, "Guard has AttackSkill equipped")
	assert_true(a_attack != null, "Acolyte has AttackSkill equipped")
	if g_attack != null and a_attack != null:
		assert_eq(g_attack.skill_id, "SAA10001", "Guard AttackSkill is SAA10001 Lance")
		assert_eq(g_attack.max_countdown, 9, "Lance max_countdown is 9")
		assert_eq(g_attack.current_countdown, 9, "Lance current_countdown starts at 9 (not 0)")
		assert_eq(a_attack.skill_id, "SAA10004", "Acolyte AttackSkill is SAA10004 Spell Attack")
		assert_eq(a_attack.max_countdown, 12, "Spell Attack max_countdown is 12")
		assert_eq(a_attack.current_countdown, 12, "Spell Attack current_countdown starts at 12 (not 0)")

	# 3. Verify trigger-time-to-skills map in UnitSkillManager:
	#    - ON_PUCK_COLLISION maps to Guard's SPA10001 Protect
	#    - ON_POCKET_FALL maps to Scout's SPA10003 Safety Rope and Acolyte's SPA10004 Chanting
	#    - ON_ACTION_TIME_START maps to Acolyte's SPA10004 Chanting
	var col_entries: Array = usm.get_skills_for_trigger(usm_script.TRIGGER_ON_PUCK_COLLISION)
	var col_skill_ids: Array[String] = []
	for entry in col_entries:
		col_skill_ids.append(str(entry["skill"].skill_id))
	assert_true(col_skill_ids.has("SPA10001"), "TRIGGER_ON_PUCK_COLLISION maps to SPA10001 Protect without looping all skills")
	assert_false(col_skill_ids.has("SPA10003"), "SPA10003 Safety Rope is not in TRIGGER_ON_PUCK_COLLISION")

	var pocket_entries: Array = usm.get_skills_for_trigger(usm_script.TRIGGER_ON_POCKET_FALL)
	var pocket_skill_ids: Array[String] = []
	for entry in pocket_entries:
		pocket_skill_ids.append(str(entry["skill"].skill_id))
	assert_true(pocket_skill_ids.has("SPA10003"), "TRIGGER_ON_POCKET_FALL maps to SPA10003 Safety Rope")
	assert_true(pocket_skill_ids.has("SPA10004"), "TRIGGER_ON_POCKET_FALL maps to SPA10004 Chanting (for pocket reset)")

	var act_start_entries: Array = usm.get_skills_for_trigger(usm_script.TRIGGER_ON_ACTION_TIME_START)
	var act_start_ids: Array[String] = []
	for entry in act_start_entries:
		act_start_ids.append(str(entry["skill"].skill_id))
	assert_true(act_start_ids.has("SPA10004"), "TRIGGER_ON_ACTION_TIME_START maps to SPA10004 Chanting")

	# 4. Verify Statistic Buff/Debuff formula from commonSkillEffects.md:
	#    "a unit at Lv5 with 280 POW, with two +20% buff and one +100, the final value will be 280 * 140% + 100 = 492"
	usm.apply_stat_modifier(a_do, "buff_pct_1", "power", 0.20, 0)
	usm.apply_stat_modifier(a_do, "buff_pct_2", "power", 0.20, 0)
	usm.apply_stat_modifier(a_do, "buff_flat_1", "power", 0.0, 100)
	assert_eq(a_do.power, 492, "280 base POW with two +20% buffs and one +100 flat buff recalculates to 280 * 1.40 + 100 = 492")

	# Removing one +20% buff recalculates to 280 * 1.20 + 100 = 436
	usm.remove_stat_modifier(a_do, "buff_pct_2")
	assert_eq(a_do.power, 436, "Removing one +20% buff recalculates POW to 280 * 1.20 + 100 = 436")
	usm.remove_stat_modifier(a_do, "buff_pct_1")
	usm.remove_stat_modifier(a_do, "buff_flat_1")
	assert_eq(a_do.power, 280, "Removing all POW modifiers restores base_power 280")

	# 5. Verify max_hp buff/debuff clamping rule:
	#    Increasing max_hp does NOT increase current_hp; decreasing max_hp below current_hp clamps current_hp = max_hp!
	g_do.current_hp = 3000
	usm.apply_stat_modifier(g_do, "hp_up", "max_hp", 0.20, 0) # 3500 * 1.20 = 4200
	assert_eq(g_do.max_hp, 4200, "Guard max_hp increased by +20% to 4200")
	assert_eq(g_do.current_hp, 3000, "Increasing max_hp does not change current_hp (stays 3000)")
	usm.remove_stat_modifier(g_do, "hp_up")
	usm.apply_stat_modifier(g_do, "hp_down", "max_hp", -0.20, 0) # 3500 * 0.80 = 2800
	assert_eq(g_do.max_hp, 2800, "Guard max_hp decreased by -20% to 2800")
	assert_eq(g_do.current_hp, 2800, "current_hp (was 3000) is clamped down to new max_hp 2800")

	tree.root.remove_child(usm)
	tree.root.remove_child(uim)
	usm.free()
	uim.free()


func test_unit_detail_display_two_row_skill_icons_and_hover_skill_display_tooltip() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var uim_script := load(UNIT_INFO_MANAGER_PATH)
	var board_script := load(UNIT_INFO_BOARD_PATH)
	var uim: UnitInformationManager = uim_script.new()
	var board: UnitInformationBoard = board_script.new()
	tree.root.add_child(uim)
	tree.root.add_child(board)

	uim.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)
	uim.register_adventurer_team(1, [
		{"unit_id": "u_guard", "adventurer_class": EnemyAdventurer.AdventurerClass.GUARD},
		{"unit_id": "u_brawler", "adventurer_class": EnemyAdventurer.AdventurerClass.BRAWLER},
		{"unit_id": "u_scout", "adventurer_class": EnemyAdventurer.AdventurerClass.SCOUT},
		{"unit_id": "u_acolyte", "adventurer_class": EnemyAdventurer.AdventurerClass.ACOLYTE},
	])
	board.bind_manager(uim)

	# 1. Click Guard (R21) to open Unit Detail Display
	board.simulate_cell_click("R21")
	assert_true(board.is_detail_display_open(), "Unit Detail Display opens on clicking R21")
	var detail_info: Dictionary = board.get_detail_display_info()
	assert_eq(detail_info.get("unit_lv_value"), 5, "Unit Detail Display shows Unit Lv = 5")
	assert_eq(detail_info.get("spd_value"), 125, "Unit Detail Display shows Guard SPD = 125")
	assert_eq(detail_info.get("power_value"), 280, "Unit Detail Display shows Guard POW = 280")

	# 2. Verify two-row skill icon layout in Unit Detail Display:
	#    Row 1 has 3 slots: [Move: SMA10001, Attack: SAA10001, Active: empty slot]
	#    Row 2 has Passive skills: [Passive: SPA10001]
	var row1_slots: Array = detail_info.get("skill_row1_slots", [])
	var row2_slots: Array = detail_info.get("skill_row2_slots", [])
	assert_eq(row1_slots.size(), 3, "First skill row always has 3 slots (Move, Attack, Active)")
	assert_eq(row2_slots.size(), 1, "Second skill row shows Guard's 1 Passive Skill")
	if row1_slots.size() < 3 or row2_slots.size() < 1:
		tree.root.remove_child(board)
		tree.root.remove_child(uim)
		board.free()
		uim.free()
		return
	assert_eq(row1_slots[0].get("skill_id"), "SMA10001", "Row 1 Slot 0 is Move Skill SMA10001 Block")
	assert_eq(row1_slots[1].get("skill_id"), "SAA10001", "Row 1 Slot 1 is Attack Skill SAA10001 Lance")
	assert_true(bool(row1_slots[2].get("is_empty_slot", false)), "Row 1 Slot 2 is an empty Active Skill slot frame when unit has no Active Skill")
	assert_eq(row2_slots[0].get("skill_id"), "SPA10001", "Row 2 Slot 0 is Passive Skill SPA10001 Protect")

	# Verify square icon sizes, passive 3x10 grid capacity (30 max, ~40% of Row-1 size), and Skill Lv on icons:
	var r1_sz: Vector2 = detail_info.get("row1_icon_size", Vector2.ZERO)
	var p_sz: Vector2 = detail_info.get("passive_icon_size", Vector2.ZERO)
	assert_true(is_equal_approx(r1_sz.x, r1_sz.y) and r1_sz.x > 0.0, "Row-1 skill icons are square (%s)" % str(r1_sz))
	assert_true(is_equal_approx(p_sz.x, p_sz.y) and p_sz.x > 0.0, "Passive skill icons are square (%s)" % str(p_sz))
	assert_true(p_sz.x <= r1_sz.x * 0.50, "Passive skill icon size is ~40% of Row-1 icon size (%.1f vs %.1f)" % [p_sz.x, r1_sz.x])
	assert_eq(int(detail_info.get("passive_grid_capacity", 0)), 30, "Passive skill grid supports up to 30 passive skills")
	assert_eq(int(detail_info.get("passive_grid_columns", 0)), 10, "Passive skill grid has 10 columns per row")
	assert_eq(int(detail_info.get("passive_grid_rows", 0)), 3, "Passive skill grid reserves 3 rows")
	assert_true(str(row1_slots[1].get("lv_text", "")).contains("1"), "Row-1 skill icon shows Skill Lv")
	assert_true(str(row2_slots[0].get("lv_text", "")).contains("1"), "Passive skill icon shows Skill Lv")

	# 3. Hover over Guard's Attack Skill icon (Row 1, Slot 1 -> SAA10001 Lance, Lv 1):
	#    Skill Display window opens showing:
	#    - Name ("Lance"), Type ("Attack Skill"), Skill Lv ("Lv 1")
	#    - Description injected with resolved ?X = 100% (90 + 1*10) and highlighted keywords (*Skill Countdown*, *Hit Level*, *Skip Movement*)
	#    - Does NOT show raw internal Effects text ("Do a distance check against all opponent's pucks...")
	#    - Bottom section shows meanings of the keywords present in that skill
	var detail_node: UnitDetailDisplay = board._detail_display
	detail_node.simulate_skill_hover(1, 1, true)
	var sd_info: Dictionary = detail_node.get_skill_display_info()
	assert_true(bool(sd_info.get("visible", false)), "Hovering a skill icon opens the Skill Display window")
	assert_true(str(sd_info.get("name_text", "")).contains("Lance"), "Skill Display shows skill name 'Lance'")
	assert_eq(int(sd_info.get("skill_lv", 0)), 1, "Skill Display shows skill Lv 1")
	var desc_plain := str(sd_info.get("description_plain", ""))
	var desc_bbcode := str(sd_info.get("description_bbcode", ""))
	assert_true(desc_plain.contains("100%"), "Skill Display description injects resolved variable ?X = '100%' at Lv 1 (got: %s)" % desc_plain)
	assert_false(desc_plain.contains("?X"), "Unresolved placeholder ?X does not appear in displayed description")
	assert_false(desc_plain.contains("edge to edge"), "Internal Effects implementation text ('edge to edge') is NOT shown in Skill Display")
	assert_true(desc_bbcode.contains("[color="), "Skill Display description uses BBCode colour tags to highlight keywords and variable values")
	var kw_text := str(sd_info.get("keywords_text", ""))
	assert_true(kw_text.contains("Skill Countdown") and kw_text.contains("Hit Level") and kw_text.contains("Skip Movement"),
		"Bottom of Skill Display explains the meanings of highlighted keywords")

	# 4. Hover over Guard's Passive Skill icon (Row 2, Slot 0 -> SPA10001 Protect, Lv 1, with 3 non-Guard teammates Brawler, Scout, Acolyte):
	#    ?X = 3 non-Guard teammates, ?Y = 3 * (4 + 1*1) = 15%
	detail_node.simulate_skill_hover(2, 0, true)
	sd_info = detail_node.get_skill_display_info()
	var sd_min_sz: Vector2 = sd_info.get("min_size", Vector2.ZERO)
	assert_true(sd_min_sz.x >= 390.0 and sd_min_sz.y >= 200.0, "Skill Display window is 20% larger (%s)" % str(sd_min_sz))
	assert_true(bool(sd_info.get("icon_visible", false)), "Skill Display shows the skill icon in the upper-right corner")
	assert_eq(sd_info.get("icon_size", Vector2.ZERO), r1_sz, "Skill Display upper-right icon size matches Move Skill icon size (68x68)")
	desc_plain = str(sd_info.get("description_plain", ""))
	assert_true(desc_plain.contains("15%"), "Protect Skill Display resolves ?Y = 15% with 3 non-Guard teammates at Lv 1 (got: %s)" % desc_plain)

	# 5. Simulate a Time Board Action Tag Turn tick (`uim.set_unit_action_turns`) while Skill Display is hovered:
	#    Skill Display must remain open and never close or flash!
	uim.set_unit_action_turns("u_guard", [3])
	assert_true(bool(detail_node.get_skill_display_info().get("visible", false)),
		"Skill Display stays open without closing or flashing when Time Board Action Tags tick")

	# Moving mouse off the skill icon closes Skill Display
	detail_node.simulate_skill_hover(2, 0, false)
	assert_false(bool(detail_node.get_skill_display_info().get("visible", true)), "Unhovering skill icon hides Skill Display")

	tree.root.remove_child(board)
	tree.root.remove_child(uim)
	board.free()
	uim.free()
