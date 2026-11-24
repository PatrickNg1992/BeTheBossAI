class_name ClassCodex
extends RefCounted

## Authoritative Adventurer Class Codex Registry for all 28 Rank 1-3 Common Classes
## (Guard, Brawler, Scout, Acolyte Class Trees) plus hook for Exceptional Classes.
## Resolves prerequisite class inheritance (`From`) and calculates linear stats:
##   stat = base + Lv * per_lv

const TREE_GUARD := "guard"
const TREE_BRAWLER := "brawler"
const TREE_SCOUT := "scout"
const TREE_ACOLYTE := "acolyte"
const TREE_OTHERS := "others"

const DEFAULT_DEMO_UNIT_LV := 5
const DEFAULT_DEMO_SKILL_LV := 1

## Raw Codex definitions per `.docmanual/codexList/classes/{guard,brawler,scout,acolyte}.md`.
## Fields omitted or < 0 on Rank 2 / Rank 3 classes are inherited from `from_class_id`.
const RAW_CLASSES := {
	# ==================== GUARD TREE ====================
	"ACG10001": {
		"class_id": "ACG10001",
		"name_key": "uib_class_guard",
		"class_tree": TREE_GUARD,
		"rank": 1,
		"from_class_id": "",
		"trait": "defence-focused",
		"action_countdown": 4,
		"mass": 1.75,
		"radius": 0.65,
		"base_hp": 2250,
		"base_pow": 180,
		"base_spd": 100,
		"hp_per_lv": 250,
		"pow_per_lv": 20,
		"spd_per_lv": 5,
		"base_skill_ids": ["SMA10001", "SAA10001", "SPA10001"],
	},
	"ACG20001": {
		"class_id": "ACG20001",
		"name_key": "uib_class_sentinel",
		"class_tree": TREE_GUARD,
		"rank": 2,
		"from_class_id": "ACG10001",
		"trait": "self-focused",
	},
	"ACG20002": {
		"class_id": "ACG20002",
		"name_key": "uib_class_knight",
		"class_tree": TREE_GUARD,
		"rank": 2,
		"from_class_id": "ACG10001",
		"trait": "protection-focused",
	},
	"ACG30001": {
		"class_id": "ACG30001",
		"name_key": "uib_class_bastion",
		"class_tree": TREE_GUARD,
		"rank": 3,
		"from_class_id": "ACG20001",
		"trait": "tanky",
	},
	"ACG30002": {
		"class_id": "ACG30002",
		"name_key": "uib_class_vanguard",
		"class_tree": TREE_GUARD,
		"rank": 3,
		"from_class_id": "ACG20001",
		"trait": "taunt and block",
	},
	"ACG30003": {
		"class_id": "ACG30003",
		"name_key": "uib_class_paladin",
		"class_tree": TREE_GUARD,
		"rank": 3,
		"from_class_id": "ACG20002",
		"trait": "support and heal effects",
	},
	"ACG30004": {
		"class_id": "ACG30004",
		"name_key": "uib_class_banneret",
		"class_tree": TREE_GUARD,
		"rank": 3,
		"from_class_id": "ACG20002",
		"trait": "aura-focused",
	},

	# ==================== BRAWLER TREE ====================
	"ACB10001": {
		"class_id": "ACB10001",
		"name_key": "uib_class_brawler",
		"class_tree": TREE_BRAWLER,
		"rank": 1,
		"from_class_id": "",
		"trait": "melee-focused",
		"action_countdown": 4,
		"mass": 1.50,
		"radius": 0.60,
		"base_hp": 1800,
		"base_pow": 180,
		"base_spd": 135,
		"hp_per_lv": 200,
		"pow_per_lv": 20,
		"spd_per_lv": 5,
		"base_skill_ids": ["SMA10002", "SAA10002", "SPA10002"],
	},
	"ACB20001": {
		"class_id": "ACB20001",
		"name_key": "uib_class_warrior",
		"class_tree": TREE_BRAWLER,
		"rank": 2,
		"from_class_id": "ACB10001",
		"trait": "attack-focused",
	},
	"ACB20002": {
		"class_id": "ACB20002",
		"name_key": "uib_class_duelist",
		"class_tree": TREE_BRAWLER,
		"rank": 2,
		"from_class_id": "ACB10001",
		"trait": "effect-focused",
	},
	"ACB30001": {
		"class_id": "ACB30001",
		"name_key": "uib_class_champion",
		"class_tree": TREE_BRAWLER,
		"rank": 3,
		"from_class_id": "ACB20001",
		"trait": "balanced-attacker",
	},
	"ACB30002": {
		"class_id": "ACB30002",
		"name_key": "uib_class_berserker",
		"class_tree": TREE_BRAWLER,
		"rank": 3,
		"from_class_id": "ACB20001",
		"trait": "strong attack with negative effects",
	},
	"ACB30003": {
		"class_id": "ACB30003",
		"name_key": "uib_class_virtuoso",
		"class_tree": TREE_BRAWLER,
		"rank": 3,
		"from_class_id": "ACB20002",
		"trait": "effect-buffed attack",
	},
	"ACB30004": {
		"class_id": "ACB30004",
		"name_key": "uib_class_spellblade",
		"class_tree": TREE_BRAWLER,
		"rank": 3,
		"from_class_id": "ACB20002",
		"trait": "effect damage",
	},

	# ==================== SCOUT TREE ====================
	"ACS10001": {
		"class_id": "ACS10001",
		"name_key": "uib_class_scout",
		"class_tree": TREE_SCOUT,
		"rank": 1,
		"from_class_id": "",
		"trait": "ranged-based",
		"action_countdown": 3,
		"mass": 1.35,
		"radius": 0.57,
		"base_hp": 1800,
		"base_pow": 180,
		"base_spd": 120,
		"hp_per_lv": 200,
		"pow_per_lv": 20,
		"spd_per_lv": 5,
		"base_skill_ids": ["SMA10003", "SAA10003", "SPA10003"],
	},
	"ACS20001": {
		"class_id": "ACS20001",
		"name_key": "uib_class_shooter",
		"class_tree": TREE_SCOUT,
		"rank": 2,
		"from_class_id": "ACS10001",
		"trait": "attack-based",
	},
	"ACS20002": {
		"class_id": "ACS20002",
		"name_key": "uib_class_ranger",
		"class_tree": TREE_SCOUT,
		"rank": 2,
		"from_class_id": "ACS10001",
		"trait": "effect-based",
	},
	"ACS30001": {
		"class_id": "ACS30001",
		"name_key": "uib_class_marksman",
		"class_tree": TREE_SCOUT,
		"rank": 3,
		"from_class_id": "ACS20001",
		"trait": "single-target focused",
	},
	"ACS30002": {
		"class_id": "ACS30002",
		"name_key": "uib_class_barrager",
		"class_tree": TREE_SCOUT,
		"rank": 3,
		"from_class_id": "ACS20001",
		"trait": "heavy-power focused",
	},
	"ACS30003": {
		"class_id": "ACS30003",
		"name_key": "uib_class_trapper",
		"class_tree": TREE_SCOUT,
		"rank": 3,
		"from_class_id": "ACS20002",
		"trait": "hinder effects",
	},
	"ACS30004": {
		"class_id": "ACS30004",
		"name_key": "uib_class_assassin",
		"class_tree": TREE_SCOUT,
		"rank": 3,
		"from_class_id": "ACS20002",
		"trait": "effect damage and damage prevention",
	},

	# ==================== ACOLYTE TREE ====================
	"ACA10001": {
		"class_id": "ACA10001",
		"name_key": "uib_class_acolyte",
		"class_tree": TREE_ACOLYTE,
		"rank": 1,
		"from_class_id": "",
		"trait": "magic-based",
		"action_countdown": 6,
		"mass": 1.25,
		"radius": 0.55,
		"base_hp": 1350,
		"base_pow": 180,
		"base_spd": 115,
		"hp_per_lv": 150,
		"pow_per_lv": 20,
		"spd_per_lv": 5,
		"base_skill_ids": ["SMA10004", "SAA10004", "SPA10004"],
	},
	"ACA20001": {
		"class_id": "ACA20001",
		"name_key": "uib_class_mage",
		"class_tree": TREE_ACOLYTE,
		"rank": 2,
		"from_class_id": "ACA10001",
		"trait": "damage-based",
	},
	"ACA20002": {
		"class_id": "ACA20002",
		"name_key": "uib_class_priest",
		"class_tree": TREE_ACOLYTE,
		"rank": 2,
		"from_class_id": "ACA10001",
		"trait": "support-based",
	},
	"ACA30001": {
		"class_id": "ACA30001",
		"name_key": "uib_class_sorcerer",
		"class_tree": TREE_ACOLYTE,
		"rank": 3,
		"from_class_id": "ACA20001",
		"trait": "attack focused",
	},
	"ACA30002": {
		"class_id": "ACA30002",
		"name_key": "uib_class_warlock",
		"class_tree": TREE_ACOLYTE,
		"rank": 3,
		"from_class_id": "ACA20001",
		"trait": "effect-damage focused",
	},
	"ACA30003": {
		"class_id": "ACA30003",
		"name_key": "uib_class_bishop",
		"class_tree": TREE_ACOLYTE,
		"rank": 3,
		"from_class_id": "ACA20002",
		"trait": "healing and protection",
	},
	"ACA30004": {
		"class_id": "ACA30004",
		"name_key": "uib_class_enchanter",
		"class_tree": TREE_ACOLYTE,
		"rank": 3,
		"from_class_id": "ACA20002",
		"trait": "buffs",
	},
}


static func get_all_class_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in RAW_CLASSES.keys():
		ids.append(str(k))
	return ids


static func has_class(class_id: String) -> bool:
	return RAW_CLASSES.has(class_id)


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
	var entry := get_class_entry(class_id)
	var tree := str(entry.get("class_tree", TREE_BRAWLER))
	match tree:
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


## Returns the fully-resolved class dictionary for `class_id`, walking its
## `from_class_id` prerequisite chain to inherit `mass`, `radius`,
## `action_countdown`, `base_hp/pow/spd`, `hp/pow/spd_per_lv`, and `base_skill_ids`.
static func get_class_entry(class_id: String) -> Dictionary:
	var target_id := class_id if RAW_CLASSES.has(class_id) else "ACB10001"
	var chain: Array[Dictionary] = []
	var cur_id := target_id
	var visited := {}
	while not cur_id.is_empty() and RAW_CLASSES.has(cur_id) and not visited.has(cur_id):
		visited[cur_id] = true
		chain.push_front(RAW_CLASSES[cur_id])
		cur_id = str(RAW_CLASSES[cur_id].get("from_class_id", ""))

	var resolved := {
		"class_id": target_id,
		"name_key": "uib_class_brawler",
		"class_tree": TREE_BRAWLER,
		"rank": 1,
		"from_class_id": "",
		"trait": "",
		"action_countdown": 4,
		"mass": 1.50,
		"radius": 0.60,
		"base_hp": 1800,
		"base_pow": 180,
		"base_spd": 135,
		"hp_per_lv": 200,
		"pow_per_lv": 20,
		"spd_per_lv": 5,
		"base_skill_ids": [],
		"prerequisite_chain": [],
	}

	var prereq_ids: Array[String] = []
	var inherited_skills: Array[String] = []
	for item in chain:
		var cid := str(item.get("class_id", ""))
		if cid != target_id and not cid.is_empty():
			prereq_ids.append(cid)
		for key in [
			"class_id", "name_key", "class_tree", "rank", "from_class_id", "trait",
			"action_countdown", "mass", "radius",
			"base_hp", "base_pow", "base_spd",
			"hp_per_lv", "pow_per_lv", "spd_per_lv",
		]:
			if item.has(key):
				resolved[key] = item[key]
		if item.has("base_skill_ids") and item["base_skill_ids"] is Array:
			for sid in item["base_skill_ids"]:
				var s_str := str(sid)
				if not inherited_skills.has(s_str):
					inherited_skills.append(s_str)

	resolved["base_skill_ids"] = inherited_skills
	resolved["prerequisite_chain"] = prereq_ids
	return resolved


## Computes the unit's Lv-scaled stats `{max_hp, power, spd, mass, radius, action_countdown}`
## using the Codex formula: `stat = base + Lv * per_lv`.
static func calculate_stats(class_id: String, unit_lv: int = DEFAULT_DEMO_UNIT_LV) -> Dictionary:
	var lv := maxi(1, unit_lv)
	var entry := get_class_entry(class_id)
	var hp := int(entry["base_hp"]) + lv * int(entry["hp_per_lv"])
	var pow_val := int(entry["base_pow"]) + lv * int(entry["pow_per_lv"])
	var spd_val := int(entry["base_spd"]) + lv * int(entry["spd_per_lv"])
	return {
		"class_id": str(entry["class_id"]),
		"class_tree": str(entry["class_tree"]),
		"rank": int(entry["rank"]),
		"unit_lv": lv,
		"max_hp": hp,
		"power": pow_val,
		"spd": spd_val,
		"mass": float(entry["mass"]),
		"radius": float(entry["radius"]),
		"action_countdown": int(entry["action_countdown"]),
		"base_skill_ids": (entry["base_skill_ids"] as Array).duplicate(),
	}


static func is_in_class_tree(class_id_or_enum: Variant, tree_name: String) -> bool:
	var cid := ""
	if class_id_or_enum is int:
		cid = class_id_for_enum(int(class_id_or_enum))
	else:
		cid = str(class_id_or_enum)
	var entry := get_class_entry(cid)
	return str(entry.get("class_tree", "")) == tree_name
