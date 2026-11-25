extends MoveSkill

## SMA10002 — Approach (Brawler Base Move Skill):
## Glide towards the nearest opponent's unit at an angle within 90 degrees (+-45 deg).

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10002", p_skill_lv)
	name_key = "skill_name_SMA10002"
	description_key = "skill_desc_SMA10002"
	target_classes = ["ACB10001"]
	base_dist_min = 2.0
	base_dist_max = 2.5
	lv_dist_min = 0.0
	lv_dist_max = 0.5


func compute_raw_target_position(
	actor_do: UnitInformationDO,
	actor_puck: BasePuck,
	uim: UnitInformationManager,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var start_pos := actor_puck.global_position if actor_puck != null else Vector3.ZERO
	var nearest := find_nearest_opponent_puck(actor_do, start_pos, uim)
	var base_dir := Vector2(1.0, 0.0)
	if nearest != null:
		base_dir = Vector2(nearest.global_position.x - start_pos.x, nearest.global_position.z - start_pos.z)
	var half_cone := deg_to_rad(45.0)
	var offset_ang := randf_range(-half_cone, half_cone) if rng == null else rng.randf_range(-half_cone, half_cone)
	var dir_xz := rotate_xz_direction(base_dir, offset_ang)
	var dist := roll_distance(rng)
	return {
		"should_move": true,
		"target_position": Vector3(start_pos.x + dir_xz.x * dist, start_pos.y, start_pos.z + dir_xz.y * dist),
	}
