extends AdventurerClassBase

## ACA10001 — Acolyte (Rank 1 Base Class)

func _init() -> void:
	class_id = "ACA10001"
	name_key = "uib_class_acolyte"
	class_tree = "acolyte"
	rank = 1
	from_class_id = ""
	trait_text = "magic-based"
	action_countdown = 6
	mass = 1.25
	radius = 0.55
	base_hp = 1350
	base_pow = 180
	base_spd = 115
	hp_per_lv = 150
	pow_per_lv = 20
	spd_per_lv = 5
	base_skill_ids = ["SMA10004", "SAA10004", "SPA10004"]
