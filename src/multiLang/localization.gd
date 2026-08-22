class_name Localization
extends Node

## Set to "en" or "zh" before starting the game
@export var language: String = "en":
	set(v):
		language = v
		if _loaded:
			_emit_changed()

signal language_changed()

var _loaded := false
var _translations: Dictionary = {}

const EN := {
	hp_format = "HP: {hp}/{max}",
	bar_count = "x{count}",
	deck_btn = "■ Deck:   {count}",
	discard_btn = "□ Discard:   {count}",
	defeated = "DEFEATED",
	discard_pile = "Discard Pile",
	deck_debug = "Deck (Debug)",
	close = "X",
	casting = "CASTING",
	icon = "ICON",
	card_type_environment = "Environment",
	card_type_monster_skill = "Monster Skill",
	card_type_summoner = "Summoner",
	card_type_minion = "Minion",
	card_desc_environment = "Environment card effect.",
	card_desc_monster_skill = "Monster Skill card effect.",
	card_desc_summoner = "Summoner card effect.",
	card_desc_minion = "Minion card effect.",
}

const ZH := {
	hp_format = "HP: {hp}/{max}",
	bar_count = "x{count}",
	deck_btn = "■ 牌堆:   {count}",
	discard_btn = "□ 弃牌:   {count}",
	defeated = "已战败",
	discard_pile = "弃牌堆",
	deck_debug = "牌堆 (调试)",
	close = "X",
	casting = "施法中",
	icon = "图标",
	card_type_environment = "场地",
	card_type_monster_skill = "魔王技能",
	card_type_summoner = "召唤者",
	card_type_minion = "仆从",
	card_desc_environment = "场地卡牌效果。",
	card_desc_monster_skill = "魔王技能卡牌效果。",
	card_desc_summoner = "召唤者卡牌效果。",
	card_desc_minion = "仆从卡牌效果。",
}


func _ready() -> void:
	_loaded = true
	_translations = _get_table()


func _get_table() -> Dictionary:
	match language:
		"zh":
			return ZH
		_:
			return EN


func t(key: String, args: Dictionary = {}) -> String:
	var table := _translations if _loaded else _get_table()
	var text: String = table.get(key, key)
	for arg in args:
		text = text.replace("{%s}" % arg, str(args[arg]))
	return text


func t_card_type(type_val: int) -> String:
	var key := "card_type_environment"
	match type_val:
		0: key = "card_type_environment"
		1: key = "card_type_monster_skill"
		2: key = "card_type_summoner"
		3: key = "card_type_minion"
	return t(key)


func t_card_desc(type_val: int) -> String:
	var key := "card_desc_environment"
	match type_val:
		0: key = "card_desc_environment"
		1: key = "card_desc_monster_skill"
		2: key = "card_desc_summoner"
		3: key = "card_desc_minion"
	return t(key)


func _emit_changed() -> void:
	_translations = _get_table()
	language_changed.emit()
