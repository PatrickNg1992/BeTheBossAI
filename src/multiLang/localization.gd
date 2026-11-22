class_name Localization
extends Node

const LANG_EN_SCRIPT := preload("res://src/multiLang/lang_en.gd")
const LANG_ZH_SCRIPT := preload("res://src/multiLang/lang_zh.gd")
const LANG_ZH_TW_SCRIPT := preload("res://src/multiLang/lang_zh_tw.gd")
const LANG_JA_SCRIPT := preload("res://src/multiLang/lang_ja.gd")

const EN: Dictionary = LANG_EN_SCRIPT.TRANSLATIONS
const ZH: Dictionary = LANG_ZH_SCRIPT.TRANSLATIONS
const ZH_TW: Dictionary = LANG_ZH_TW_SCRIPT.TRANSLATIONS
const JA: Dictionary = LANG_JA_SCRIPT.TRANSLATIONS

## Set to "en", "zh" (Simplified Chinese), "zh_tw" (Traditional Chinese), or "ja" (Japanese)
@export var language: String = "en":
	set(v):
		language = v
		if _loaded:
			_emit_changed()

signal language_changed()

var _loaded := false
var _translations: Dictionary = {}


func _ready() -> void:
	_loaded = true
	_translations = _get_table()


func _get_table() -> Dictionary:
	match language.to_lower():
		"zh", "zh_cn", "zh_hans":
			return ZH
		"zh_tw", "zh_hk", "zh_hant", "tc":
			return ZH_TW
		"ja", "jp":
			return JA
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
