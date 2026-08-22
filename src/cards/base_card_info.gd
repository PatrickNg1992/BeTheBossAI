class_name BaseCardInfo
extends Resource

enum CardType { ENVIRONMENT, MONSTER_SKILL, SUMMONER, MINION }

const TYPE_NAMES := {
	CardType.ENVIRONMENT: "Environment",
	CardType.MONSTER_SKILL: "Monster Skill",
	CardType.SUMMONER: "Summoner",
	CardType.MINION: "Minion",
}

const TYPE_COLORS := {
	CardType.ENVIRONMENT: Color(0.1, 0.8, 0.2),
	CardType.MONSTER_SKILL: Color(0.9, 0.2, 0.1),
	CardType.SUMMONER: Color(0.2, 0.4, 0.9),
	CardType.MINION: Color(0.6, 0.2, 0.8),
}

@export var card_type: CardType
@export var card_name: String
@export_multiline var description: String
@export var color: Color
@export var cd: float = 0.0
