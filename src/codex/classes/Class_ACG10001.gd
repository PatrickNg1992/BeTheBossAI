extends AdventurerClassBase

## ACG10001 — Guard (Rank 1 Base Class)

func _init() -> void:
	class_id = "ACG10001"
	name_key = "uib_class_guard"
	class_tree = "guard"
	rank = 1
	from_class_id = ""
	trait_text = "defence-focused"
	action_countdown = 4
	mass = 1.75
	radius = 0.65
	base_hp = 2250
	base_pow = 180
	base_spd = 100
	hp_per_lv = 250
	pow_per_lv = 20
	spd_per_lv = 5
	base_skill_ids = ["SMA10001", "SAA10001", "SPA10001"]
