class_name ClassCodex
extends RefCounted

## Authoritative Adventurer Class Codex Manager (`src/codex/class_codex.gd`).
## Instantiates the 28 individual class scripts under `res://src/codex/classes/Class_<ID>.gd`
## (each extending `AdventurerClassBase` or its direct prerequisite `From` class script).

const TREE_GUARD := "guard"
const TREE_BRAWLER := "brawler"
const TREE_SCOUT := "scout"
const TREE_ACOLYTE := "acolyte"
const TREE_OTHERS := "others"

const DEFAULT_DEMO_UNIT_LV := 5
const DEFAULT_DEMO_SKILL_LV := 1

const ALL_CLASS_IDS: Array[String] = [
	# Guard Tree
	"ACG10001", "ACG20001", "ACG20002", "ACG30001", "ACG30002", "ACG30003", "ACG30004",
	# Brawler Tree
	"ACB10001", "ACB20001", "ACB20002", "ACB30001", "ACB30002", "ACB30003", "ACB30004",
	# Scout Tree
	"ACS10001", "ACS20001", "ACS20002", "ACS30001", "ACS30002", "ACS30003", "ACS30004",
	# Acolyte Tree
	"ACA10001", "ACA20001", "ACA20002", "ACA30001", "ACA30002", "ACA30003", "ACA30004",
]

static var _instances: Dictionary = {} # class_id -> AdventurerClassBase


static func get_all_class_ids() -> Array[String]:
	return ALL_CLASS_IDS.duplicate()


static func get_class_script_path(class_id: String) -> String:
	return "res://src/codex/classes/Class_%s.gd" % class_id


static func has_class(class_id: String) -> bool:
	return ALL_CLASS_IDS.has(class_id) or ResourceLoader.exists(get_class_script_path(class_id))


static func get_class_instance(class_id: String) -> AdventurerClassBase:
	var target_id := class_id if has_class(class_id) else "ACB10001"
	if _instances.has(target_id) and _instances[target_id] != null:
		return _instances[target_id] as AdventurerClassBase
	var script_path := get_class_script_path(target_id)
	if ResourceLoader.exists(script_path):
		var scr := load(script_path)
		if scr != null and scr.can_instantiate():
			var inst := scr.new() as AdventurerClassBase
			if inst != null:
				_instances[target_id] = inst
				return inst
	var fallback := AdventurerClassBase.new()
	fallback.class_id = target_id
	_instances[target_id] = fallback
	return fallback


static func class_id_for_enum(adv_class: int) -> String:
	match adv_class:
		EnemyAdventurer.AdventurerClass.GUARD:
			return "ACG10001"
		EnemyAdventurer.AdventurerClass.BRAWLER:
			return "ACB10001"
		EnemyAdventurer.AdventurerClass.SCOUT:
			return "ACS10001"
		EnemyAdventurer.AdventurerClass.ACOLYTE:
			return "ACA10001"
		_:
			return "ACB10001"


static func enum_for_class_id(class_id: String) -> int:
	var inst := get_class_instance(class_id)
	match inst.class_tree:
		TREE_GUARD:
			return EnemyAdventurer.AdventurerClass.GUARD
		TREE_BRAWLER:
			return EnemyAdventurer.AdventurerClass.BRAWLER
		TREE_SCOUT:
			return EnemyAdventurer.AdventurerClass.SCOUT
		TREE_ACOLYTE:
			return EnemyAdventurer.AdventurerClass.ACOLYTE
		_:
			return EnemyAdventurer.AdventurerClass.BRAWLER


static func get_class_entry(class_id: String) -> Dictionary:
	var inst := get_class_instance(class_id)
	return inst.to_dict()


static func calculate_stats(class_id: String, unit_lv: int = DEFAULT_DEMO_UNIT_LV) -> Dictionary:
	var inst := get_class_instance(class_id)
	return inst.calculate_stats(unit_lv)


static func is_in_class_tree(class_id_or_enum: Variant, tree_name: String) -> bool:
	var cid := ""
	if class_id_or_enum is int:
		cid = class_id_for_enum(int(class_id_or_enum))
	else:
		cid = str(class_id_or_enum)
	var inst := get_class_instance(cid)
	return inst.class_tree == tree_name
