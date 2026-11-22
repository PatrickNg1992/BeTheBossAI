class_name UnitInformationDO
extends RefCounted

## Authoritative data object representing one unit on the battlefield (and one
## Unit Display cell on the Unit Information Board).
## Holds identity, grid coordinate, Reference Mark, colours, combat stats,
## Damage Stack / Hit Level / Frenzy Power state, and 0..N active Puck references.

var unit_id: String = ""
var unit_kind: String = "enemy_adventurer" # "boss" | "minion" | "enemy_adventurer" | "target_puck"
var owner_seat: String = "enemy" # "a" | "b" | "enemy"
var team_index: int = 1
var slot_index: int = 1 # 1..6 for Adventurers / Minions / Target Pucks; 0 for Boss
var side: String = "R" # "L" | "R"
var row: int = 1 # 1..8
var col: int = 1 # 1..2
var span_cols: int = 1 # 1 for normal cell, 2 for Boss Monster span
var grid_id: String = "R21" # "{L|R}{Row 1..8}{Col 1..2}"

var reference_mark: String = ""
var reference_mark_color: Color = Color.WHITE
var slot_color: Color = Color.WHITE
var name_key: String = ""
var avatar_path: String = ""
var class_mark_path: String = ""

var adventurer_class: int = EnemyAdventurer.AdventurerClass.GUARD
var current_hp: int = 100
var max_hp: int = 100
var bars_remaining: int = 1
var max_bars: int = 1
var power: int = 10
var mass: float = 1.0
var radius: float = 0.5

var damage_stack: Array[DamageDO] = []
var hit_level: int = 0
var frenzy_power: float = 1.0
var is_focusing: bool = false
var is_pocketed: bool = false
var pocket_return_turns: int = 0
var is_dead: bool = false
var next_action_turns: int = 3
var action_tag_turns: Array[int] = [3]
var skills: Array = []
var statuses: Array = []

var pucks: Array[BasePuck] = []


func get_damage_stack_count() -> int:
	return damage_stack.size()


func get_damage_stack_sum() -> float:
	var total := 0.0
	for d in damage_stack:
		if d != null:
			total += d.value
	return total


## Pre-Settle Ghost HP damage considers Damage Stack and Hit Level (excluding Frenzy Power):
## - Normal DamageDO entries scale by 1.1^(Hit Level)
## - Fixed DamageDO entries (`is_fixed = true`, e.g. Pocket Area fall) are immune to Frenzy Power and Hit Level
## Uses decimal numbers during calculation and rounds to nearest integer.
func get_preview_damage() -> int:
	if damage_stack.is_empty():
		return 0
	var scalable_sum := 0.0
	var fixed_sum := 0.0
	for d in damage_stack:
		if d == null or d.value <= 0.0:
			continue
		if d.is_fixed:
			fixed_sum += d.value
		else:
			scalable_sum += d.value
	var total := fixed_sum + scalable_sum * pow(1.1, float(hit_level))
	return int(round(total))


func get_preview_ghost_hp() -> int:
	if is_dead:
		return 0
	return maxi(0, current_hp - get_preview_damage())


func get_display_action_turns_text() -> String:
	if is_dead or unit_kind == "boss":
		return ""
	if is_pocketed:
		return str(maxi(1, pocket_return_turns))
	if not action_tag_turns.is_empty():
		var parts: Array[String] = []
		for t in action_tag_turns:
			if int(t) > 0:
				parts.append(str(int(t)))
		if not parts.is_empty():
			return " / ".join(parts)
	if next_action_turns > 0:
		return str(next_action_turns)
	return ""
