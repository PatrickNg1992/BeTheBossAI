class_name ActiveSkill
extends UnitSkill

## Abstract Active Skill subclass.
## Defines additional unit actions beyond basic attacks and movement.


func _init(p_skill_id: String = "", p_skill_lv: int = 1) -> void:
	super(p_skill_id, p_skill_lv)
	skill_category = CATEGORY_ACTIVE
	type_key = "skill_type_active"
	max_lv = 5
	icon_path = "res://src/resource/battlefield/goal_flag.png"
