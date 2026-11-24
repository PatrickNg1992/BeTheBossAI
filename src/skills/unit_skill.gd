class_name UnitSkill
extends RefCounted

## Base Unit Skill class for all unit skills (Boss Monsters, Adventurers, Minions).
## Subclasses: MoveSkill, AttackSkill, ActiveSkill, PassiveSkill.

const CATEGORY_MOVE := "move"
const CATEGORY_ATTACK := "attack"
const CATEGORY_ACTIVE := "active"
const CATEGORY_PASSIVE := "passive"

const COLOR_VALUE_HEX := "#ffd95a"
const COLOR_KEYWORD_HEX := "#5ee2ff"

const KEYWORD_MEANING_KEYS := {
	"Skill Countdown": "kw_desc_skill_countdown",
	"Hit Level": "kw_desc_hit_level",
	"Skip Movement": "kw_desc_skip_movement",
	"Frenzy Power": "kw_desc_frenzy_power",
	"Collision Damage": "kw_desc_collision_damage",
	"On the cue table": "kw_desc_on_the_cue_table",
	"Pocket Area Damage": "kw_desc_pocket_area_damage",
	"Pocket Area": "kw_desc_pocket_area",
	"Boss Monster": "kw_desc_boss_monster",
	"Action Time": "kw_desc_action_time",
}

var skill_id: String = ""
var name_key: String = ""
var type_key: String = "skill_type_passive"
var description_key: String = ""
var icon_path: String = "res://src/resource/battlefield/sword.png"
var skill_category: String = CATEGORY_PASSIVE
var target_classes: Array[String] = []
var is_base_skill: bool = true
var skill_lv: int = 1
var max_lv: int = 3
var max_countdown: int = 0
var current_countdown: int = 0
var counter: int = 0
var skip_movement: bool = false
var hit_level_add: int = 0
var trigger_times: Array[String] = []


func _init(p_skill_id: String = "", p_skill_lv: int = 1) -> void:
	skill_id = p_skill_id
	skill_lv = maxi(1, p_skill_lv)


func reset_countdown_to_initial() -> void:
	current_countdown = maxi(0, max_countdown)


func tick_countdown(turns: int = 1) -> int:
	if current_countdown > 0:
		current_countdown = maxi(0, current_countdown - maxi(1, turns))
	return current_countdown


func is_countdown_ready() -> bool:
	return current_countdown <= 0


func mark_activated() -> void:
	if max_countdown > 0:
		current_countdown = max_countdown


func get_localized_name() -> String:
	if name_key.is_empty():
		return skill_id
	return Loc.t(name_key) if Loc != null else name_key


func get_localized_type() -> String:
	return Loc.t(type_key) if Loc != null else type_key


func _to_string() -> String:
	return get_localized_name()


## Resolves dynamic placeholders (`?X`, `?Y`, `?N`, `?DIST`) for this skill
## at its current `skill_lv`, `counter`, and team state.
func resolve_variables(_owner_unit: UnitInformationDO = null, _manager: UnitInformationManager = null) -> Dictionary:
	return {}


## Formats `Description` for the hover `Skill Display` window:
## - Injects resolved `?X` / `?Y` / `?N` / `?DIST` values (highlighted in `COLOR_VALUE_HEX`)
## - Highlights `*keyword*` spans in `COLOR_KEYWORD_HEX`
## - Collects the localized glossary meanings of all `*keyword*` spans present
func format_display_description(owner_unit: UnitInformationDO = null, manager: UnitInformationManager = null) -> Dictionary:
	var raw_desc := Loc.t(description_key) if (Loc != null and not description_key.is_empty()) else description_key
	var vars := resolve_variables(owner_unit, manager)

	var plain := raw_desc
	var bbcode := raw_desc

	# Sort variable tokens longest-first (so ?DIST replaces before ?D)
	var var_keys: Array[String] = []
	for k in vars.keys():
		var_keys.append(str(k))
	var_keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())

	for k in var_keys:
		var token := "?" + k
		var val_str := str(vars[k])
		plain = plain.replace(token, val_str)
		bbcode = bbcode.replace(token, "[color=%s]%s[/color]" % [COLOR_VALUE_HEX, val_str])

	# Extract and style *keyword* spans
	var found_keywords: Array[Dictionary] = []
	var seen_kw := {}
	var regex := RegEx.new()
	regex.compile("\\*([^*]+)\\*")
	var matches := regex.search_all(raw_desc)
	for m in matches:
		var kw := m.get_string(1).strip_edges()
		if kw.is_empty():
			continue
		var full_match := "*" + m.get_string(1) + "*"
		plain = plain.replace(full_match, kw)
		bbcode = bbcode.replace(full_match, "[color=%s]%s[/color]" % [COLOR_KEYWORD_HEX, kw])
		if not seen_kw.has(kw):
			seen_kw[kw] = true
			var meaning_key: String = str(KEYWORD_MEANING_KEYS.get(kw, ""))
			var meaning_text: String = Loc.t(meaning_key) if (Loc != null and not meaning_key.is_empty()) else meaning_key
			found_keywords.append({
				"keyword": kw,
				"meaning": meaning_text,
			})

	var kw_lines: Array[String] = []
	for item in found_keywords:
		kw_lines.append("• %s: %s" % [item["keyword"], item["meaning"]])

	return {
		"plain_text": plain,
		"bbcode_text": bbcode,
		"keywords": found_keywords,
		"keywords_text": "\n".join(kw_lines),
		"resolved_vars": vars,
	}
