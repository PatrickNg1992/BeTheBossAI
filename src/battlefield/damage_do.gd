class_name DamageDO
extends RefCounted

## One staged damage record in a unit's Damage Stack, accumulated during
## "Puck-puck Time!" or "Action Time" in time order before resolving in Settle Time.
## `value` is stored as a decimal float during calculation and rounded to the
## nearest integer at Settle Time. When `is_fixed` is true (e.g. Pocket Area fall
## damage = ceil(max_hp / 2.0)), it is immune to Frenzy Power and Hit Level.

var source_unit_id: String = ""
var owner_boss_unit_id: String = ""
var value: float = 0.0
var damage_type: String = "collision"
var is_fixed: bool = false


func _init(
	p_value: float = 0.0,
	p_source_unit_id: String = "",
	p_owner_boss_unit_id: String = "",
	p_damage_type: String = "collision",
	p_is_fixed: bool = false
) -> void:
	value = p_value
	source_unit_id = p_source_unit_id
	owner_boss_unit_id = p_owner_boss_unit_id
	damage_type = p_damage_type
	is_fixed = p_is_fixed

