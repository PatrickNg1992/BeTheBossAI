class_name CardManager
extends Node

signal hand_updated(cards: Array)
signal deck_count_changed(count: int)
signal discard_count_changed(count: int)
signal card_played(card_data: Dictionary)

const HAND_SIZE_MAX := 10
const HAND_SIZE_INITIAL := 5

enum CardType { ENVIRONMENT, MONSTER_SKILL, SUMMONER, MINION }

var _deck: Array[Dictionary] = []
var _hand: Array[Dictionary] = []
var _discard: Array[Dictionary] = []

const TYPE_NAMES := {
	CardType.ENVIRONMENT: "Environment",
	CardType.MONSTER_SKILL: "Monster Skill",
	CardType.SUMMONER: "Summoner",
	CardType.MINION: "Minion",
}

const TYPE_COLORS := {
	CardType.ENVIRONMENT: Color(0.6, 0.2, 0.8),
	CardType.MONSTER_SKILL: Color(0.9, 0.2, 0.1),
	CardType.SUMMONER: Color(0.2, 0.4, 0.9),
	CardType.MINION: Color(0.1, 0.8, 0.2),
}

func _ready() -> void:
	_build_deck()
	shuffle_all()
	draw_cards(HAND_SIZE_INITIAL)

func _build_deck() -> void:
	_deck.clear()
	var id := 0
	for card_type in CardType.values():
		for i in range(1, 14):
			id += 1
			_deck.append({
				"id": id,
				"type": card_type,
				"name": "%s %d" % [TYPE_NAMES[card_type], i],
				"description": "%s card effect." % TYPE_NAMES[card_type],
				"color": TYPE_COLORS[card_type],
			})

func draw_cards(count: int) -> int:
	var drawn := 0
	for _i in range(count):
		if _hand.size() >= HAND_SIZE_MAX:
			break
		if _deck.is_empty():
			_reshuffle_discard()
			if _deck.is_empty():
				break
		var card: Dictionary = _deck.pop_back()
		_hand.append(card)
		drawn += 1
	if drawn > 0:
		_emit_updates()
	return drawn

func play_card(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= _hand.size():
		return
	var card: Dictionary = _hand[hand_index]
	_hand.remove_at(hand_index)
	_discard.append(card)
	card_played.emit(card)
	_emit_updates()

func discard_hand() -> void:
	_discard.append_array(_hand)
	_hand.clear()
	_emit_updates()

func shuffle_all() -> void:
	_deck.append_array(_hand)
	_deck.append_array(_discard)
	_hand.clear()
	_discard.clear()
	_deck.shuffle()
	_emit_updates()

func _reshuffle_discard() -> void:
	if _discard.is_empty():
		return
	_deck = _discard.duplicate()
	_deck.shuffle()
	_discard.clear()

func _emit_updates() -> void:
	hand_updated.emit(_hand)
	deck_count_changed.emit(_deck.size())
	discard_count_changed.emit(_discard.size())

func get_hand() -> Array:
	return _hand

func get_deck_count() -> int:
	return _deck.size()

func get_discard_count() -> int:
	return _discard.size()
