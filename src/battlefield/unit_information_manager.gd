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
signal unit_damage_pushed(unit_do: UnitInformationDO, damage_do: DamageDO)
signal unit_collision_impulse_received(unit_do: UnitInformationDO, impulse_magnitude: float)
signal frenzy_power_spread_started(settled_records: Dictionary)
signal damage_settled(settled_records: Dictionary)

const MODE_SINGLE_PLAYER := "single_player"
const MODE_TWO_PLAYER_COOP := "two_player_coop"
const MODE_TWO_PLAYER_VS := "two_player_vs"

const DEFAULT_FRENZY_BASELINE := 1.0
const DEFAULT_FRENZY_FLOOR := 0.50
const DEFAULT_FRENZY_GAIN_NON_KNIGHT := 0.10
const DEFAULT_FRENZY_LOSS_KNIGHT := 0.20
const COLLISION_DAMAGE_PER_IMPULSE := 7.5

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
	u.max_hp = int(config.get("max_hp", 1000))
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

	u.reference_mark = get_adventurer_reference_mark(team_index, slot_num)
	u.reference_mark_color = COLOR_MARK_TEAM1_GREY if team_index == 1 else COLOR_MARK_TEAM2_BROWN
	u.slot_color = get_class_color(adv_class)
	u.adventurer_class = adv_class
	u.name_key = str(d.get("name_key", get_class_name_key(adv_class)))
	var variant_idx: int = int(_class_avatar_Usage_counts.get(adv_class, 0))
	_class_avatar_Usage_counts[adv_class] = variant_idx + 1
	u.avatar_path = str(d.get("avatar_path", get_class_avatar_path(adv_class, variant_idx)))
	u.class_mark_path = str(d.get("class_mark_path", get_class_mark_path(adv_class)))

	var cls_cfg: Dictionary = EnemyAdventurer.CLASS_CONFIG.get(adv_class, {})
	u.max_hp = int(d.get("max_hp", cls_cfg.get("hp", get_class_default_max_hp(adv_class))))
	u.current_hp = int(d.get("current_hp", u.max_hp))
	u.power = int(d.get("power", cls_cfg.get("damage", 100)))
	u.mass = float(d.get("mass", cls_cfg.get("mass", 1.5)))
	u.radius = float(d.get("radius", cls_cfg.get("radius", 0.6)))

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
## and binds death signals so the board updates when pucks are removed.
func register_puck(unit_id: String, puck: BasePuck) -> bool:
	var u := get_unit(unit_id)
	if u == null or puck == null:
		return false
	if not u.pucks.has(puck):
		u.pucks.append(puck)
	puck.set_unit_id(unit_id)
	puck.set_reference_mark(u.reference_mark, u.reference_mark_color)
	puck.set_slot_color(u.slot_color)
	if puck.has_method("configure_puck_stripes"):
		var has_team2_stripe := (u.unit_kind == "enemy_adventurer" and u.team_index == 2)
		var free_slot_x_mode := 0
		if u.unit_kind == "enemy_adventurer":
			if u.slot_index == 5:
				free_slot_x_mode = 5
			elif u.slot_index == 6:
				free_slot_x_mode = 6
		puck.call("configure_puck_stripes", has_team2_stripe, free_slot_x_mode)
	u.mass = puck.mass
	u.radius = puck.radius
	if not puck.died.is_connected(_on_puck_died.bind(unit_id, puck)):
		puck.died.connect(_on_puck_died.bind(unit_id, puck))
	if puck is BaseBossMonster:
		var bp := puck as BaseBossMonster
		bp.health_changed.emit(u.current_hp, u.max_hp)
		bp.bars_changed.emit(u.bars_remaining, u.current_hp, u.max_hp)
	else:
		puck.health_changed.emit(u.current_hp, u.max_hp)
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


func _on_puck_died(unit_id: String, puck: BasePuck) -> void:
	var u := get_unit(unit_id)
	if u == null:
		return
	unregister_puck(unit_id, puck)
	if u.pucks.is_empty():
		u.is_dead = true
		u.current_hp = 0
		unit_updated.emit(u)


# ----- Ticket 02: Damage Stack, Hit Level, Frenzy Power & Ghost HP Trailing Pipeline -----


func _resolve_owner_boss_unit_id(source_unit_id: String, explicit_boss_unit_id: String = "") -> String:
	if not explicit_boss_unit_id.is_empty():
		var b := get_unit(explicit_boss_unit_id)
		if b != null and b.unit_kind == "boss":
			return b.unit_id
	if not source_unit_id.is_empty():
		var src := get_unit(source_unit_id)
		if src != null:
			if src.unit_kind == "boss":
				return src.unit_id
			if src.owner_seat == "a" or src.owner_seat == "b":
				for u in _units_by_id.values():
					var cand := u as UnitInformationDO
					if cand != null and cand.unit_kind == "boss" and cand.owner_seat == src.owner_seat:
						return cand.unit_id
	return ""


## Appends a DamageDO in time order to `target_unit_id`'s Damage Stack during
## Puck-puck Time! or Action Time without mutating actual `current_hp` yet.
## `amount` is kept as a decimal float during calculation and rounded to nearest integer at Settle Time.
func push_damage(
	target_unit_id: String,
	amount: float,
	source_unit_id: String = "",
	owner_boss_unit_id: String = "",
	damage_type: String = "collision",
	is_fixed: bool = false
) -> DamageDO:
	if amount <= 0.0:
		return null
	var target := get_unit(target_unit_id)
	if target == null or target.is_dead:
		return null
	var resolved_boss_id := "" if is_fixed else _resolve_owner_boss_unit_id(source_unit_id, owner_boss_unit_id)
	var dmg_do := DamageDO.new(amount, source_unit_id, resolved_boss_id, damage_type, is_fixed)
	target.damage_stack.append(dmg_do)
	unit_damage_pushed.emit(target, dmg_do)
	unit_updated.emit(target)
	return dmg_do


## Routes damage taken by a specific 3D Puck directly into its owning unit's Damage Stack.
func push_damage_to_puck(
	target_puck: BasePuck,
	amount: float,
	source_puck: BasePuck = null,
	damage_type: String = "collision",
	is_fixed: bool = false
) -> DamageDO:
	if target_puck == null:
		return null
	var target_id := target_puck.get_unit_id()
	if target_id.is_empty():
		return null
	var source_id := source_puck.get_unit_id() if source_puck != null else ""
	return push_damage(target_id, amount, source_id, "", damage_type, is_fixed)


## When a puck falls into a Pocket Area, pushes a fixed DamageDO equal to half
## of the unit's max_hp (rounded UP to integer: `ceili(float(max_hp) / 2.0)`).
## This DamageDO is fixed (`is_fixed = true`) and immune to Frenzy Power and Hit Level.
func push_pocket_fall_damage(unit_id: String) -> DamageDO:
	var u := get_unit(unit_id)
	if u == null or u.is_dead:
		return null
	var half_up := int(ceil(float(u.max_hp) / 2.0))
	return push_damage(unit_id, float(half_up), "", "", "pocket", true)


func push_pocket_fall_damage_for_puck(puck: BasePuck) -> DamageDO:
	if puck == null:
		return null
	var uid := puck.get_unit_id()
	if uid.is_empty():
		return null
	return push_pocket_fall_damage(uid)


func set_hit_level(unit_id: String, new_hit_level: int) -> void:
	var u := get_unit(unit_id)
	if u == null:
		return
	u.hit_level = new_hit_level
	unit_updated.emit(u)


func modify_hit_level(unit_id: String, delta: int) -> int:
	var u := get_unit(unit_id)
	if u == null:
		return 0
	u.hit_level += delta
	unit_updated.emit(u)
	return u.hit_level


func set_frenzy_power(boss_unit_id: String, new_frenzy: float) -> float:
	var u := get_unit(boss_unit_id)
	if u == null or u.unit_kind != "boss":
		return DEFAULT_FRENZY_BASELINE
	u.frenzy_power = maxf(DEFAULT_FRENZY_FLOOR, new_frenzy)
	unit_updated.emit(u)
	return u.frenzy_power


func modify_frenzy_power(boss_unit_id: String, delta: float) -> float:
	var u := get_unit(boss_unit_id)
	if u == null or u.unit_kind != "boss":
		return DEFAULT_FRENZY_BASELINE
	return set_frenzy_power(boss_unit_id, u.frenzy_power + delta)


## Adjusts a Boss Monster's Frenzy Power when colliding with an Enemy Adventurer puck:
##   - Non-Knight Adventurer: +10% (DEFAULT_FRENZY_GAIN_NON_KNIGHT)
##   - Knight Adventurer: -20% (DEFAULT_FRENZY_LOSS_KNIGHT), clamped to >= 50% floor
func record_boss_collision_frenzy(boss_unit_id: String, struck_unit_id: String) -> float:
	var boss := get_unit(boss_unit_id)
	var struck := get_unit(struck_unit_id)
	if boss == null or boss.unit_kind != "boss" or struck == null:
		return DEFAULT_FRENZY_BASELINE
	if struck.unit_kind != "enemy_adventurer":
		return boss.frenzy_power
	if struck.adventurer_class == EnemyAdventurer.AdventurerClass.KNIGHT:
		return modify_frenzy_power(boss_unit_id, -DEFAULT_FRENZY_LOSS_KNIGHT)
	return modify_frenzy_power(boss_unit_id, DEFAULT_FRENZY_GAIN_NON_KNIGHT)


func notify_unit_collision_impulse(unit_id: String, impulse_magnitude: float) -> void:
	if impulse_magnitude <= 0.0:
		return
	var u := get_unit(unit_id)
	if u == null:
		return
	unit_collision_impulse_received.emit(u, impulse_magnitude)


func get_preview_damage(unit_id: String) -> int:
	var u := get_unit(unit_id)
	if u == null:
		return 0
	return u.get_preview_damage()


func get_preview_ghost_hp(unit_id: String) -> int:
	var u := get_unit(unit_id)
	if u == null:
		return 0
	return u.get_preview_ghost_hp()


func get_boss_frenzy_power(boss_unit_id: String) -> float:
	if boss_unit_id.is_empty():
		return DEFAULT_FRENZY_BASELINE
	var u := get_unit(boss_unit_id)
	if u == null or u.unit_kind != "boss":
		return DEFAULT_FRENZY_BASELINE
	return u.frenzy_power


## Computes the final settled damage for `u` at Settle Time using decimal
## arithmetic and rounding to the nearest integer at settlement:
## - Fixed DamageDO entries (`is_fixed = true`, e.g. Pocket Area fall) are immune to Frenzy Power and Hit Level.
## - Enemy Adventurer scalable entries:
##     (Sum_i (Damage_i * Frenzy(SourceBoss_i))) * 1.1^(Hit Level)
## - Boss Monster / Minion / Target Puck scalable entries:
##     (Sum of scalable Damage Stack) * 1.1^(Hit Level)
func calculate_settled_damage(u: UnitInformationDO) -> int:
	if u == null or u.damage_stack.is_empty():
		return 0
	var hit_mult := pow(1.1, float(u.hit_level))
	var fixed_sum := 0.0
	var scalable_weighted := 0.0
	for d in u.damage_stack:
		if d == null or d.value <= 0.0:
			continue
		if d.is_fixed:
			fixed_sum += d.value
		elif u.unit_kind == "enemy_adventurer":
			var frz := get_boss_frenzy_power(d.owner_boss_unit_id)
			scalable_weighted += d.value * frz
		else:
			scalable_weighted += d.value
	return int(round(fixed_sum + scalable_weighted * hit_mult))


## Resolves the Damage Stack for all units at Settle Time:
## 1. Emits `frenzy_power_spread_started` when any Enemy Adventurer has pending damage.
## 2. Applies settled damage to each unit:
##    - Every Boss Monster is strictly capped at losing at most 1 Health Bar per Settle Phase.
## 3. Clears every unit's Damage Stack and resets every unit's Hit Level to 0.
## 4. Decays every Boss Monster's Frenzy Power via `new_frenzy = (current_frenzy / 2.0) + 0.50`.
func settle_all_damage() -> Dictionary:
	var settled_records: Dictionary = {}
	var any_adventurer_damaged := false

	for u in _units_by_id.values():
		var unit_do := u as UnitInformationDO
		if unit_do == null or unit_do.damage_stack.is_empty():
			continue
		var settled_dmg := calculate_settled_damage(unit_do)
		if settled_dmg > 0:
			settled_records[unit_do.unit_id] = settled_dmg
			if unit_do.unit_kind == "enemy_adventurer":
				any_adventurer_damaged = true

	var frenzy_spread_triggered := any_adventurer_damaged or not settled_records.is_empty()
	if frenzy_spread_triggered:
		frenzy_power_spread_started.emit(settled_records)

	for u in _units_by_id.values():
		var unit_do := u as UnitInformationDO
		if unit_do == null:
			continue
		var dmg: int = int(settled_records.get(unit_do.unit_id, 0))
		if dmg > 0 and not unit_do.is_dead:
			_apply_settled_damage_to_unit(unit_do, dmg)
		unit_do.damage_stack.clear()
		unit_do.hit_level = 0
		if unit_do.unit_kind == "boss":
			unit_do.frenzy_power = maxf(DEFAULT_FRENZY_FLOOR, (unit_do.frenzy_power * 0.5) + 0.5)
		unit_updated.emit(unit_do)

	damage_settled.emit(settled_records)
	return {
		"settled_damage": settled_records,
		"frenzy_spread_triggered": frenzy_spread_triggered,
	}


func _apply_settled_damage_to_unit(u: UnitInformationDO, dmg: int) -> void:
	if u.unit_kind == "boss":
		var broke_bar := false
		# Strict 1-Health-Bar-per-Settle cap on every Boss Monster:
		if dmg >= u.current_hp:
			broke_bar = true
			u.bars_remaining = maxi(0, u.bars_remaining - 1)
			if u.bars_remaining <= 0:
				u.current_hp = 0
				u.is_dead = true
			else:
				u.current_hp = u.max_hp
		else:
			u.current_hp -= dmg
		for p in u.pucks:
			if is_instance_valid(p) and p is BaseBossMonster:
				var bp := p as BaseBossMonster
				bp.health_changed.emit(u.current_hp, u.max_hp)
				bp.bars_changed.emit(u.bars_remaining, u.current_hp, u.max_hp)
				if broke_bar:
					bp.notify_bar_broken_from_manager(u.bars_remaining)
				if u.is_dead and not bp.is_dead:
					bp.die()
		return

	u.current_hp = maxi(0, u.current_hp - dmg)
	if u.current_hp <= 0:
		u.is_dead = true
	for p in u.pucks:
		if is_instance_valid(p):
			p.health_changed.emit(u.current_hp, u.max_hp)
			if u.is_dead and not p.is_dead:
				p.die()


func apply_direct_damage(unit_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var u := get_unit(unit_id)
	if u == null or u.is_dead:
		return
	_apply_settled_damage_to_unit(u, amount)
	unit_updated.emit(u)


func heal_unit(unit_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var u := get_unit(unit_id)
	if u == null or u.is_dead:
		return
	u.current_hp = mini(u.current_hp + amount, u.max_hp)
	for p in u.pucks:
		if is_instance_valid(p):
			p.health_changed.emit(u.current_hp, u.max_hp)
			if p is BaseBossMonster:
				(p as BaseBossMonster).bars_changed.emit(u.bars_remaining, u.current_hp, u.max_hp)
	unit_updated.emit(u)


static func calculate_linear_collision_damage(impulse_scalar: float) -> float:
	if impulse_scalar <= 0.0:
		return 0.0
	return maxf(1.0, impulse_scalar * COLLISION_DAMAGE_PER_IMPULSE)


## Handles a physical Puck–Puck collision resolved in `PuckVelocityManager`:
## 1. Notifies both units of the collision Impulse scalar `j_mag` so their Unit Displays shake.
## 2. Calculates decimal linear collision damage `j_mag * COLLISION_DAMAGE_PER_IMPULSE` (~50..200 range).
## 3. Enforces the collision matrix:
##    - Enemy Adventurers suffer collision damage from any impact, EXCEPT impacts with an allied Knight.
##    - Boss Monsters only suffer collision damage when colliding with a Knight.
## 4. Updates Boss Monster Frenzy Power (+10% vs non-Knight Adventurer, -20% vs Knight, floor 50%).
func handle_puck_collision(p1: BasePuck, p2: BasePuck, j_mag: float) -> void:
	if p1 == null or p2 == null or j_mag <= 0.0001:
		return
	var uid1 := p1.get_unit_id()
	var uid2 := p2.get_unit_id()
	var u1 := get_unit(uid1) if not uid1.is_empty() else null
	var u2 := get_unit(uid2) if not uid2.is_empty() else null
	if u1 == null and u2 == null:
		return

	if u1 != null:
		notify_unit_collision_impulse(u1.unit_id, j_mag)
	if u2 != null:
		notify_unit_collision_impulse(u2.unit_id, j_mag)

	if u1 == null or u2 == null:
		return

	# Frenzy Power adjustment when a Boss Monster collides with an Enemy Adventurer
	if u1.unit_kind == "boss" and u2.unit_kind == "enemy_adventurer":
		record_boss_collision_frenzy(u1.unit_id, u2.unit_id)
	elif u2.unit_kind == "boss" and u1.unit_kind == "enemy_adventurer":
		record_boss_collision_frenzy(u2.unit_id, u1.unit_id)

	var dmg := calculate_linear_collision_damage(j_mag)
	if dmg <= 0.0:
		return

	# Check whether u1 takes collision damage from u2, and whether u2 takes collision damage from u1
	if _does_unit_take_collision_damage_from(u1, u2):
		var boss_owner_for_u1 := _resolve_collision_boss_owner(u2, u1)
		push_damage(u1.unit_id, dmg, u2.unit_id, boss_owner_for_u1, "collision")
	if _does_unit_take_collision_damage_from(u2, u1):
		var boss_owner_for_u2 := _resolve_collision_boss_owner(u1, u2)
		push_damage(u2.unit_id, dmg, u1.unit_id, boss_owner_for_u2, "collision")


func _does_unit_take_collision_damage_from(victim: UnitInformationDO, hitter: UnitInformationDO) -> bool:
	if victim == null or hitter == null or victim.is_dead:
		return false
	if victim.unit_kind == "boss":
		# Only a Knight's impacts damage a Boss Monster, whoever initiated the collision
		return hitter.unit_kind == "enemy_adventurer" and hitter.adventurer_class == EnemyAdventurer.AdventurerClass.KNIGHT
	if victim.unit_kind == "enemy_adventurer":
		# Knight protects its allies: no collision damage when an Adventurer collides with an allied Knight
		if hitter.unit_kind == "enemy_adventurer":
			if victim.adventurer_class == EnemyAdventurer.AdventurerClass.KNIGHT or hitter.adventurer_class == EnemyAdventurer.AdventurerClass.KNIGHT:
				return false
		return true
	# Minions / Target Pucks suffer collision damage from any impact
	return true


func _resolve_collision_boss_owner(hitter: UnitInformationDO, _victim: UnitInformationDO) -> String:
	if hitter == null:
		return ""
	if hitter.unit_kind == "boss":
		return hitter.unit_id
	if hitter.owner_seat == "a" or hitter.owner_seat == "b":
		return _resolve_owner_boss_unit_id(hitter.unit_id)
	# If an Enemy Adventurer was knocked into another Enemy Adventurer during a shot, attribute to Player A Boss if present
	for u in _units_by_id.values():
		var cand := u as UnitInformationDO
		if cand != null and cand.unit_kind == "boss" and cand.owner_seat == "a":
			return cand.unit_id
	return ""


static func get_class_default_max_hp(adv_class: int) -> int:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return 3000
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return 2200
		EnemyAdventurer.AdventurerClass.RANGER:
			return 2200
		EnemyAdventurer.AdventurerClass.MAGE:
			return 1500
		_:
			return 2200


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


static func get_adventurer_reference_mark(team_index: int, slot_num: int) -> String:
	var upper_marks: Array[String] = ["V", "B", "R", "S", "F", "E"]
	var lower_marks: Array[String] = ["v", "b", "r", "s", "f", "e"]
	var idx := clampi(slot_num, 1, 6) - 1
	return lower_marks[idx] if team_index == 2 else upper_marks[idx]


static func get_class_color(adv_class: int) -> Color:
	match adv_class:
		EnemyAdventurer.AdventurerClass.KNIGHT:
			return COLOR_SLOT_1_BLUE
		EnemyAdventurer.AdventurerClass.WARRIOR:
			return COLOR_SLOT_2_RED
		EnemyAdventurer.AdventurerClass.RANGER:
			return COLOR_SLOT_5_GREEN
		EnemyAdventurer.AdventurerClass.MAGE:
			return COLOR_SLOT_4_PURPLE
		_:
			return COLOR_SLOT_2_RED


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
