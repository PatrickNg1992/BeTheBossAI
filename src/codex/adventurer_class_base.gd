class_name AdventurerClassBase
extends RefCounted

## Explicit base class for all Adventurer Classes in `src/codex/classes/Class_<ID>.gd`.
## Rank 1 classes extend `AdventurerClassBase`; Rank 2 and Rank 3 classes extend
## their direct prerequisite (`From`) class script so stats, puck mass/radius,
## Action Countdown, and Base Skills are inherited directly via GDScript inheritance.

var class_id: String = ""
var name_key: String = ""
var class_tree: String = "brawler" # "guard" | "brawler" | "scout" | "acolyte" | "others"
var rank: int = 1
var from_class_id: String = ""
var trait_text: String = ""
var description_key: String = ""
var action_countdown: int = 4
var mass: float = 1.50
var radius: float = 0.60
var base_hp: int = 1800
var base_pow: int = 180
var base_spd: int = 135
var hp_per_lv: int = 200
var pow_per_lv: int = 20
var spd_per_lv: int = 5
var base_skill_ids: Array[String] = []
var prerequisite_chain: Array[String] = []


func _record_prerequisite(prereq_id: String) -> void:
	from_class_id = prereq_id
	if not prereq_id.is_empty() and not prerequisite_chain.has(prereq_id):
		prerequisite_chain.append(prereq_id)


func calculate_stats(unit_lv: int = 5) -> Dictionary:
	var lv := maxi(1, unit_lv)
	return {
		"class_id": class_id,
		"class_tree": class_tree,
		"rank": rank,
		"unit_lv": lv,
		"max_hp": base_hp + lv * hp_per_lv,
		"power": base_pow + lv * pow_per_lv,
		"spd": base_spd + lv * spd_per_lv,
		"mass": mass,
		"radius": radius,
		"action_countdown": action_countdown,
		"base_skill_ids": base_skill_ids.duplicate(),
	}


func to_dict() -> Dictionary:
	return {
		"class_id": class_id,
		"name_key": name_key,
		"class_tree": class_tree,
		"rank": rank,
		"from_class_id": from_class_id,
		"trait": trait_text,
		"action_countdown": action_countdown,
		"mass": mass,
		"radius": radius,
		"base_hp": base_hp,
		"base_pow": base_pow,
		"base_spd": base_spd,
		"hp_per_lv": hp_per_lv,
		"pow_per_lv": pow_per_lv,
		"spd_per_lv": spd_per_lv,
		"base_skill_ids": base_skill_ids.duplicate(),
		"prerequisite_chain": prerequisite_chain.duplicate(),
	}
