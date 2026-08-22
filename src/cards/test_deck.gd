class_name TestDeck
extends Resource

var cards: Array[BaseCardInfo] = []

func _init() -> void:
	var _id := 0
	for type_val in BaseCardInfo.CardType.values():
		for i in range(1, 14):
			_id += 1
			var card := BaseCardInfo.new()
			card.card_type = type_val
			card.card_name = "%s %d" % [BaseCardInfo.TYPE_NAMES[type_val], i]
			card.description = "%s card effect." % BaseCardInfo.TYPE_NAMES[type_val]
			card.color = BaseCardInfo.TYPE_COLORS[type_val]
			card.cd = randf_range(0.0, 8.0)
			cards.append(card)
