extends AdventurerClassBase

## ACS10001 — Scout (Rank 1 Base Class)

func _init() -> void:
	class_id = "ACS10001"
	name_key = "uib_class_scout"
	class_tree = "scout"
	rank = 1
	from_class_id = ""
	trait_text = "ranged-based"
	action_countdown = 3
	mass = 1.35
	radius = 0.57
	base_hp = 1800
	base_pow = 180
	base_spd = 120
	hp_per_lv = 200
	pow_per_lv = 20
	spd_per_lv = 5
	base_skill_ids = ["SMA10003", "SAA10003", "SPA10003"]
