class_name CardManager
extends Node

signal hand_updated(cards: Array)
signal casting_card_updated(card: BaseCardInfo)
signal deck_count_changed(count: int)
signal discard_count_changed(count: int)
signal card_played(card_data: BaseCardInfo)

const HAND_SIZE_MAX := 10
const HAND_SIZE_INITIAL := 5

var _deck: Array[BaseCardInfo] = []
var _hand: Array[BaseCardInfo] = []
var _discard: Array[BaseCardInfo] = []
var _casting_card: BaseCardInfo = null

var _test_deck := TestDeck.new()


func _ready() -> void:
	_deck = _test_deck.cards.duplicate()
	shuffle_all()
	draw_cards(HAND_SIZE_INITIAL)


func draw_cards(count: int) -> int:
	var drawn := 0
	for _i in range(count):
		if _hand.size() >= HAND_SIZE_MAX:
			break
		if _deck.is_empty():
			_reshuffle_discard()
			if _deck.is_empty():
				break
		var card: BaseCardInfo = _deck.pop_back()
		_hand.append(card)
		drawn += 1
	if drawn > 0:
		_emit_all_area_updates()
	return drawn

# when a card is played, move it to casting area immediately
func play_card(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= _hand.size():
		return
	var card: BaseCardInfo = _hand[hand_index]
	_hand.remove_at(hand_index)
	_casting_card = card
	# _discard.append(card)
	card_played.emit(card)
	_emit_all_area_updates()


func discard_casting_card() -> void:
	if _casting_card:
		_discard.append(_casting_card)
		_casting_card = null
		_emit_all_area_updates()

func discard_hand() -> void:
	_discard.append_array(_hand)
	_hand.clear()
	_emit_all_area_updates()


func shuffle_all() -> void:
	_deck.append_array(_hand)
	_deck.append_array(_discard)
	_hand.clear()
	_discard.clear()
	_deck.shuffle()
	_emit_all_area_updates()


func _reshuffle_discard() -> void:
	if _discard.is_empty():
		return
	_deck = _discard.duplicate()
	_deck.shuffle()
	_discard.clear()


func _emit_all_area_updates() -> void:
	hand_updated.emit(_hand)
	casting_card_updated.emit(_casting_card)
	deck_count_changed.emit(_deck.size())
	discard_count_changed.emit(_discard.size())


func get_hand() -> Array[BaseCardInfo]:
	return _hand

func get_casting_card() -> BaseCardInfo:
	return _casting_card


func get_deck_count() -> int:
	return _deck.size()


func get_deck() -> Array[BaseCardInfo]:
	return _deck


func get_discard_count() -> int:
	return _discard.size()


func get_discard() -> Array[BaseCardInfo]:
	return _discard
