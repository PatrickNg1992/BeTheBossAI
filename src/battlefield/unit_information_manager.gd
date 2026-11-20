class_name UnitInformationManager
extends Node

## Battle-scoped manager node (in group "unit_information_manager", never a
## global Autoload) that manages UnitInformationDO instances for all units on
## the battlefield (alive, pocketed, or defeated), maps units to their fixed
## {L|R}{Row 1..8}{Col 1..2} grid coordinates, assigns Reference Marks and
## slot/mark colours, and tracks 0..N active Puck objects per unit.

signal unit_registered(unit_do: UnitInformationDO)
signal unit_updated(unit_do: UnitInformationDO)
signal units_cleared()
signal mode_changed(new_mode: String)

const MODE_SINGLE_PLAYER := "single_player"
const MODE_TWO_PLAYER_COOP := "two_player_coop"
const MODE_TWO_PLAYER_VS := "two_player_vs"

## Slot / Puck / Grid Border colours by position index 1..6 and Boss Black:
## ?1 Blue (Knight), ?2 Red (Warrior), ?3 Yellow (Ranger), ?4 Purple (Mage),
## ?5 Green (free), ?6 Orange (free), Boss Monster Black.
const COLOR_SLOT_1_BLUE := Color(0.22, 0.48, 0.92, 1.0)
const COLOR_SLOT_2_RED := Color(0.86, 0.22, 0.20, 1.0)
const COLOR_SLOT_3_YELLOW := Color(0.92, 0.78, 0.18, 1.0)
const COLOR_SLOT_4_PURPLE := Color(0.64, 0.26, 0.86, 1.0)
const COLOR_SLOT_5_GREEN := Color(0.22, 0.76, 0.34, 1.0)
const COLOR_SLOT_6_ORANGE := Color(0.96, 0.50, 0.12, 1.0)
const COLOR_SLOT_6_CYAN := COLOR_SLOT_6_ORANGE
const COLOR_SLOT_BOSS_BLACK := Color(0.11, 0.10, 0.12, 1.0)

## Minion deeper shades of 1..6:
const COLOR_MINION_1_BLUE := Color(0.14, 0.30, 0.62, 1.0)
const COLOR_MINION_2_RED := Color(0.56, 0.14, 0.14, 1.0)
const COLOR_MINION_3_YELLOW := Color(0.62, 0.50, 0.12, 1.0)
const COLOR_MINION_4_PURPLE := Color(0.42, 0.16, 0.58, 1.0)
const COLOR_MINION_5_GREEN := Color(0.14, 0.48, 0.22, 1.0)
const COLOR_MINION_6_ORANGE := Color(0.64, 0.32, 0.08, 1.0)
const COLOR_MINION_6_CYAN := COLOR_MINION_6_ORANGE

## Reference Mark colours:
## Player A (Ω / ω1..6) = Gold; Player B (Ψ / ψ1..6) = Silver;
## Adventurer Team 1 (A1..A6) = Deep Grey; Adventurer Team 2 (B1..B6) = Deep Brown.
const COLOR_MARK_GOLD := Color(0.98, 0.82, 0.26, 1.0)
const COLOR_MARK_SILVER := Color(0.84, 0.88, 0.96, 1.0)
const COLOR_MARK_TEAM1_GREY := Color(0.24, 0.25, 0.28, 1.0)
const COLOR_MARK_TEAM2_BROWN := Color(0.38, 0.22, 0.11, 1.0)

const AVATAR_BOSS_DRAGON := "res://src/resource/battlefield/avatar_boss_dragon.png"
const AVATAR_KNIGHT := "res://src/resource/battlefield/avatar_knight.png"
const AVATAR_KNIGHT_2 := "res://src/resource/battlefield/avatar_knight_2.png"
const AVATAR_KNIGHT_3 := "res://src/resource/battlefield/avatar_knight_3.png"
const AVATAR_WARRIOR := "res://src/resource/battlefield/avatar_warrior.png"
const AVATAR_WARRIOR_2 := "res://src/resource/battlefield/avatar_warrior_2.png"
const AVATAR_WARRIOR_3 := "res://src/resource/battlefield/avatar_warrior_3.png"
const AVATAR_RANGER := "res://src/resource/battlefield/avatar_ranger.png"
const AVATAR_RANGER_2 := "res://src/resource/battlefield/avatar_ranger_2.png"
const AVATAR_RANGER_3 := "res://src/resource/battlefield/avatar_ranger_3.png"
const AVATAR_MAGE := "res://src/resource/battlefield/avatar_mage.png"
const AVATAR_MAGE_2 := "res://src/resource/battlefield/avatar_mage_2.png"
const AVATAR_MAGE_3 := "res://src/resource/battlefield/avatar_mage_3.png"
const AVATAR_MINION := "res://src/resource/battlefield/avatar_minion.png"

const CLASS_ICON_KNIGHT := "res://src/resource/battlefield/class_knight.png"
const CLASS_ICON_WARRIOR := "res://src/resource/battlefield/class_warrior.png"
const CLASS_ICON_RANGER := "res://src/resource/battlefield/class_ranger.png"
const CLASS_ICON_MAGE := "res://src/resource/battlefield/class_mage.png"

var game_mode: String = MODE_SINGLE_PLAYER
var _units_by_id: Dictionary = {} # unit_id -> UnitInformationDO
var _units_by_grid: Dictionary = {} # grid_id ("L11", "R21", ...) -> UnitInformationDO
var _class_avatar_Usage_counts: Dictionary = {} # adv_class -> int count of assigned avatars
var _team_headers: Dictionary = {
	1: "uib_team_1",
	2: "uib_team_2",
}


func _ready() -> void:
	add_to_group("unit_information_manager")


func configure_mode(p_mode: String) -> void:
	game_mode = p_mode
	mode_changed.emit(game_mode)


func clear_all() -> void:
	_units_by_id.clear()
	_units_by_grid.clear()
	_class_avatar_Usage_counts.clear()
	units_cleared.emit()


func get_unit(unit_id: String) -> UnitInformationDO:
	return _units_by_id.get(unit_id, null)


func get_unit_at_grid(grid_id: String) -> UnitInformationDO:
	return _units_by_grid.get(grid_id, null)


func get_all_units() -> Array[UnitInformationDO]:
	var result: Array[UnitInformationDO] = []
	for u in _units_by_id.values():
		result.append(u)
	return result


func get_team_header_key(team_index: int) -> String:
	return _team_headers.get(team_index, "uib_team_1" if team_index == 1 else "uib_team_2")


func set_team_header_key(team_index: int, loc_key: String) -> void:
	_team_headers[team_index] = loc_key


## Registers a Boss Monster for Player A ("a") or Player B ("b").
## - Single-Player / 2P Co-op: Player A -> L1 (L11..L12); Player B -> L5 (L51..L52)
## - 2P Versus: Player A -> L1 (L11..L12); Player B -> R1 (R11..R12)
func register_boss(unit_id: String, seat: String, config: Dictionary = {}) -> UnitInformationDO:
	var u := UnitInformationDO.new()
	u.unit_id = unit_id
	u.unit_kind = "boss"
	u.owner_seat = seat
	u.slot_index = 0
	u.span_cols = 2
	if seat == "b":
		if game_mode == MODE_TWO_PLAYER_VS:
			u.side = "R"
			u.row = 1
		else:
			u.side = "L"
			u.row = 5
		u.reference_mark = "Ψ"
		u.reference_mark_color = COLOR_MARK_SILVER
	else:
		u.side = "L"
		u.row = 1
		u.reference_mark = "Ω"
		u.reference_mark_color = COLOR_MARK_GOLD
	u.col = 1
	u.grid_id = "%s%d%d" % [u.side, u.row, u.col]
	u.slot_color = COLOR_SLOT_BOSS_BLACK
	u.name_key = str(config.get("name_key", "uib_boss_dragon"))
	u.avatar_path = str(config.get("avatar_path", AVATAR_BOSS_DRAGON))
	u.max_hp = int(config.get("max_hp", 100))
	u.current_hp = int(config.get("current_hp", u.max_hp))
	u.max_bars = int(config.get("max_bars", 15))
	u.bars_remaining = int(config.get("bars_remaining", u.max_bars))
	u.power = int(config.get("power", 25))
	u.mass = float(config.get("mass", 3.2))
	u.radius = float(config.get("radius", 0.8))
	u.frenzy_power = float(config.get("frenzy_power", 1.0))

	_store_unit(u)
	if config.has("puck") and config["puck"] is BasePuck:
		register_puck(unit_id, config["puck"] as BasePuck)
	return u


## Registers a Minion at slot_index (1..6) for Player A ("a") or Player B ("b").
func register_minion(unit_id: String, seat: String, slot_index: int, config: Dictionary = {}) -> UnitInformationDO:
	var clamped_slot := clampi(slot_index, 1, 6)
	var u := UnitInformationDO.new()
	u.unit_id = unit_id
	u.unit_kind = "minion"
	u.owner_seat = seat
	u.slot_index = clamped_slot
	u.span_cols = 1
	var base_row := 2
	if seat == "b":
		if game_mode == MODE_TWO_PLAYER_VS:
			u.side = "R"
			base_row = 2
		else:
			u.side = "L"
			base_row = 6
		u.reference_mark = "ψ%d" % clamped_slot
		u.reference_mark_color = COLOR_MARK_SILVER
	else:
		u.side = "L"
		base_row = 2
		u.reference_mark = "ω%d" % clamped_slot
		u.reference_mark_color = COLOR_MARK_GOLD
	@warning_ignore("integer_division")
	u.row = base_row + (clamped_slot - 1) / 2
	u.col = 1 + ((clamped_slot - 1) % 2)
	u.grid_id = "%s%d%d" % [u.side, u.row, u.col]
	u.slot_color = get_minion_slot_color(clamped_slot)
	u.name_key = str(config.get("name_key", "uib_minion"))
	u.avatar_path = str(config.get("avatar_path", AVATAR_MINION))
	u.max_hp = int(config.get("max_hp", 80))
	u.current_hp = int(config.get("current_hp", u.max_hp))
	u.power = int(config.get("power", 10))
	u.mass = float(config.get("mass", 1.0))
	u.radius = float(config.get("radius", 0.45))

	_store_unit(u)
	if config.has("puck") and config["puck"] is BasePuck:
		register_puck(unit_id, config["puck"] as BasePuck)
	return u


## Registers a Target Puck in 2-Player Versus mode (Rows L6-L8 for Player A, Rows R6-R8 for Player B).
func register_target_puck(unit_id: String, seat: String, slot_index: int, config: Dictionary = {}) -> UnitInformationDO:
	var clamped_slot := clampi(slot_index, 1, 6)
	var u := UnitInformationDO.new()
	u.unit_id = unit_id
	u.unit_kind = "target_puck"
	u.owner_seat = seat
	u.slot_index = clamped_slot
	u.span_cols = 1
	u.side = "R" if seat == "b" else "L"
	@warning_ignore("integer_division")
	u.row = 6 + (clamped_slot - 1) / 2
	u.col = 1 + ((clamped_slot - 1) % 2)
	u.grid_id = "%s%d%d" % [u.side, u.row, u.col]
	u.reference_mark = ("B%d" if seat == "b" else "A%d") % clamped_slot
	u.reference_mark_color = COLOR_MARK_SILVER if seat == "b" else COLOR_MARK_GOLD
	u.slot_color = get_slot_color(clamped_slot)
	u.name_key = str(config.get("name_key", "uib_target_puck"))
	u.avatar_path = str(config.get("avatar_path", AVATAR_KNIGHT))
	u.max_hp = int(config.get("max_hp", 100))
	u.current_hp = int(config.get("current_hp", u.max_hp))

	_store_unit(u)
	if config.has("puck") and config["puck"] is BasePuck:
		register_puck(unit_id, config["puck"] as BasePuck)
	return u


## Registers an Enemy Adventurer Team (team_index 1 -> R2..R4 with A1..A6;
## team_index 2 -> R6..R8 with B1..B6).
## In normal random Adventurer Team generation:
##   ?1 = Knight, ?2 = Warrior, ?3 = Ranger, ?4 = Mage, ?5..6 = free positions for duplicate classes.
##   Missing classes leave their numbers and grid cells empty (never compacted).
## Customized stage compositions can pass `"slot_override": 1..6` on any member dictionary.
func register_adventurer_team(team_index: int, members: Array) -> Array[UnitInformationDO]:
	var registered: Array[UnitInformationDO] = []
	var occupied_slots: Dictionary = {}

	# Pass 1: honour explicit `slot_override` entries first (for customized stage compositions)
	for entry in members:
		if not entry is Dictionary:
			continue
		var d := entry as Dictionary
		if d.has("slot_override"):
			var slot_num := clampi(int(d["slot_override"]), 1, 6)
			occupied_slots[slot_num] = true
			var u := _create_adventurer_do(team_index, slot_num, d)
			registered.append(u)

	# Pass 2: normal class-to-slot rule (?1 Knight, ?2 Warrior, ?3 Ranger, ?4 Mage, ?5..6 duplicates)
	for entry in members:
		if not entry is Dictionary:
			continue
		var d := entry as Dictionary
		if d.has("slot_override"):
			continue
		var adv_class := int(d.get("adventurer_class", EnemyAdventurer.AdventurerClass.WARRIOR))
		var preferred_slot := default_slot_for_class(adv_class)
		var chosen_slot := 0
		if not occupied_slots.has(preferred_slot):
			chosen_slot = preferred_slot
		else:
			# Duplicate class -> only fills free positions ?5 and ?6
			if not occupied_slots.has(5):
				chosen_slot = 5
			elif not occupied_slots.has(6):
				chosen_slot = 6
			else:
				# Fallback if more than 6 or custom overflow
				for s in range(1, 7):
					if not occupied_slots.has(s):
						chosen_slot = s
						break
		if chosen_slot >= 1 and chosen_slot <= 6:
			occupied_slots[chosen_slot] = true
			var u := _create_adventurer_do(team_index, chosen_slot, d)
			registered.append(u)

	return registered


func _create_adventurer_do(team_index: int, slot_num: int, d: Dictionary) -> UnitInformationDO:
	var adv_class := int(d.get("adventurer_class", EnemyAdventurer.AdventurerClass.WARRIOR))
	var u := UnitInformationDO.new()
	u.unit_id = str(d.get("unit_id", "team%d_slot%d" % [team_index, slot_num]))
	u.unit_kind = "enemy_adventurer"
	u.owner_seat = "enemy"
	u.team_index = team_index
	u.slot_index = slot_num
	u.span_cols = 1
	u.side = "R"
	var base_row := 2 if team_index == 1 else 6
	@warning_ignore("integer_division")
	u.row = base_row + (slot_num - 1) / 2
	u.col = 1 + ((slot_num - 1) % 2)
	u.grid_id = "%s%d%d" % [u.side, u.row, u.col]

	var prefix := "A" if team_index == 1 else "B"
	u.reference_mark = "%s%d" % [prefix, slot_num]
	u.reference_mark_color = COLOR_MARK_TEAM1_GREY if team_index == 1 else COLOR_MARK_TEAM2_BROWN
	u.slot_color = get_slot_color(slot_num)
	u.adventurer_class = adv_class
	u.name_key = str(d.get("name_key", get_class_name_key(adv_class)))
	var variant_idx: int = int(_class_avatar_Usage_counts.get(adv_class, 0))
	_class_avatar_Usage_counts[adv_class] = variant_idx + 1
	u.avatar_path = str(d.get("avatar_path", get_class_avatar_path(adv_class, variant_idx)))
	u.class_mark_path = str(d.get("class_mark_path", get_class_mark_path(adv_class)))

	var cls_cfg: Dictionary = EnemyAdventurer.CLASS_CONFIG.get(adv_class, {})
	u.max_hp = int(d.get("max_hp", cls_cfg.get("hp", 100)))
	u.current_hp = int(d.get("current_hp", u.max_hp))
	u.power = int(d.get("power", cls_cfg.get("damage", 10)))
	u.mass = float(d.get("mass", cls_cfg.get("mass", 1.2)))
	u.radius = float(d.get("radius", cls_cfg.get("radius", 0.5)))

	_store_unit(u)
	if d.has("puck") and d["puck"] is BasePuck:
		register_puck(u.unit_id, d["puck"] as BasePuck)
	return u


func _store_unit(u: UnitInformationDO) -> void:
	_units_by_id[u.unit_id] = u
	_units_by_grid[u.grid_id] = u
	unit_registered.emit(u)


## Links an active Puck on the Cue Table to a unit (a unit can hold 0..N pucks).
## Applies the unit's Reference Mark, Reference Mark colour, and slot colour to the puck,
## and binds health/bar signals so the board updates when HP changes.
func register_puck(unit_id: String, puck: BasePuck) -> bool:
	var u := get_unit(unit_id)
	if u == null or puck == null:
		return false
	if not u.pucks.has(puck):
		u.pucks.append(puck)
	puck.set_unit_id(unit_id)
	puck.set_reference_mark(u.reference_mark, u.reference_mark_color)
	puck.set_slot_color(u.slot_color)
	u.mass = puck.mass
	u.radius = puck.radius
	if not puck.health_changed.is_connected(_on_puck_health_changed.bind(unit_id)):
		puck.health_changed.connect(_on_puck_health_changed.bind(unit_id))
	if puck is BaseBossMonster:
		var boss_puck := puck as BaseBossMonster
		if not boss_puck.bars_changed.is_connected(_on_boss_puck_bars_changed.bind(unit_id)):
			boss_puck.bars_changed.connect(_on_boss_puck_bars_changed.bind(unit_id))
	if not puck.died.is_connected(_on_puck_died.bind(unit_id, puck)):
		puck.died.connect(_on_puck_died.bind(unit_id, puck))
	unit_updated.emit(u)
	return true


func unregister_puck(unit_id: String, puck: BasePuck) -> bool:
	var u := get_unit(unit_id)
	if u == null or puck == null:
		return false
	var idx := u.pucks.find(puck)
	if idx < 0:
		return false
	u.pucks.remove_at(idx)
	unit_updated.emit(u)
	return true


func _on_puck_health_changed(current: int, maximum: int, unit_id: String) -> void:
	var u := get_unit(unit_id)
	if u == null:
		return
	u.current_hp = current
	u.max_hp = maximum
	unit_updated.emit(u)


func _on_boss_puck_bars_changed(bars: int, current: int, maximum: int, unit_id: String) -> void:
	var u := get_unit(unit_id)
	if u == null:
		return
	u.bars_remaining = bars
	u.current_hp = current
	u.max_hp = maximum
	unit_updated.emit(u)


func _on_puck_died(unit_id: String, puck: BasePuck) -> void:
	var u := get_unit(unit_id)
	if u == null:
		return
	unregister_puck(unit_id, puck)
	if u.pucks.is_empty():
		u.is_dead = true
		u.current_hp = 0
		unit_updated.emit(u)


static func default_slot_for_class(adv_class: int) -> int:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return 1
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return 2
		EnemyAdventurer.AdventurerClass.RANGER:
			return 3
		EnemyAdventurer.AdventurerClass.MAGE:
			return 4
		_:
			return 5


static func get_slot_color(slot_num: int) -> Color:
	match slot_num:
		1:
			return COLOR_SLOT_1_BLUE
		2:
			return COLOR_SLOT_2_RED
		3:
			return COLOR_SLOT_3_YELLOW
		4:
			return COLOR_SLOT_4_PURPLE
		5:
			return COLOR_SLOT_5_GREEN
		6:
			return COLOR_SLOT_6_CYAN
		_:
			return COLOR_SLOT_BOSS_BLACK


static func get_minion_slot_color(slot_num: int) -> Color:
	match slot_num:
		1:
			return COLOR_MINION_1_BLUE
		2:
			return COLOR_MINION_2_RED
		3:
			return COLOR_MINION_3_YELLOW
		4:
			return COLOR_MINION_4_PURPLE
		5:
			return COLOR_MINION_5_GREEN
		6:
			return COLOR_MINION_6_CYAN
		_:
			return COLOR_MINION_1_BLUE


static func get_class_name_key(adv_class: int) -> String:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return "uib_class_knight"
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return "uib_class_warrior"
		EnemyAdventurer.AdventurerClass.RANGER:
			return "uib_class_ranger"
		EnemyAdventurer.AdventurerClass.MAGE:
			return "uib_class_mage"
		_:
			return "uib_class_warrior"


static func get_class_avatar_path(adv_class: int, variant_index: int = 0) -> String:
	var v := posmod(variant_index, 3)
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			if v == 1: return AVATAR_KNIGHT_2
			if v == 2: return AVATAR_KNIGHT_3
			return AVATAR_KNIGHT
		EnemyAdventurer.AdventurerClass.WARRIOR:
			if v == 1: return AVATAR_WARRIOR_2
			if v == 2: return AVATAR_WARRIOR_3
			return AVATAR_WARRIOR
		EnemyAdventurer.AdventurerClass.RANGER:
			if v == 1: return AVATAR_RANGER_2
			if v == 2: return AVATAR_RANGER_3
			return AVATAR_RANGER
		EnemyAdventurer.AdventurerClass.MAGE:
			if v == 1: return AVATAR_MAGE_2
			if v == 2: return AVATAR_MAGE_3
			return AVATAR_MAGE
		_:
			return AVATAR_WARRIOR


static func get_class_mark_path(adv_class: int) -> String:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return CLASS_ICON_KNIGHT
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return CLASS_ICON_WARRIOR
		EnemyAdventurer.AdventurerClass.RANGER:
			return CLASS_ICON_RANGER
		EnemyAdventurer.AdventurerClass.MAGE:
			return CLASS_ICON_MAGE
		_:
			return CLASS_ICON_WARRIOR
