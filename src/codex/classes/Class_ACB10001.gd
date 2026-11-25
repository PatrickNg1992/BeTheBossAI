extends AdventurerClassBase

## ACB10001 — Brawler (Rank 1 Base Class)

func _init() -> void:
	class_id = "ACB10001"
	name_key = "uib_class_brawler"
	class_tree = "brawler"
	rank = 1
	from_class_id = ""
	trait_text = "melee-focused"
	action_countdown = 4
	mass = 1.50
	radius = 0.60
	base_hp = 1710
	base_pow = 180
	base_spd = 135
	hp_per_lv = 190
	pow_per_lv = 20
	spd_per_lv = 5
	base_skill_ids = ["SMA10002", "SAA10002", "SPA10002"]
