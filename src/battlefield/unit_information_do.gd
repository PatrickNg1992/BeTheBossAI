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

var adventurer_class: int = EnemyAdventurer.AdventurerClass.KNIGHT
var current_hp: int = 100
var max_hp: int = 100
var bars_remaining: int = 1
var max_bars: int = 1
var power: int = 10
var mass: float = 1.0
var radius: float = 0.5

var damage_stack: Array = []
var hit_level: int = 0
var frenzy_power: float = 1.0
var is_focusing: bool = false
var is_pocketed: bool = false
var pocket_return_turns: int = 0
var is_dead: bool = false
var action_tag_turns: Array[int] = []
var skills: Array = []
var statuses: Array = []

var pucks: Array[BasePuck] = []
