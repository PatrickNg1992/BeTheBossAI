extends MoveSkill

## SMA10004 — Move Away (Acolyte Base Move Skill):
## Check whether the opponent's Boss Monster is on the left (X < 0) or right (X >= 0)
## of the Cue Table. Then check whether this puck is in the farthest area on the other
## side, within a width of 2 (X in [13, 15] or [-15, -13]).
## If not, glide towards that area in a direction within a 60-degree angle (+-30 deg)
## at a random distance. If yes, stay still.

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10004", p_skill_lv)
	name_key = "skill_name_SMA10004"
	description_key = "skill_desc_SMA10004"
	target_classes = ["ACA10001"]
	base_dist_min = 3.75
	base_dist_max = 5.0
	lv_dist_min = 0.0
	lv_dist_max = 0.5


func compute_raw_target_position(
	actor_do: UnitInformationDO,
	actor_puck: BasePuck,
	uim: UnitInformationManager,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var start_pos := actor_puck.global_position if actor_puck != null else Vector3.ZERO
	var boss_puck := find_opponent_boss_puck(actor_do, uim)
	var boss_on_left := true
	if boss_puck != null:
		boss_on_left = boss_puck.global_position.x < 0.0

	var strip_min_x := (Battlefield.TABLE_HALF_X - 2.0) if boss_on_left else -Battlefield.TABLE_HALF_X
	var strip_max_x := Battlefield.TABLE_HALF_X if boss_on_left else -(Battlefield.TABLE_HALF_X - 2.0)
	if start_pos.x >= strip_min_x - 0.01 and start_pos.x <= strip_max_x + 0.01:
		return {
			"should_move": false,
			"target_position": start_pos,
		}

	var base_dir := Vector2(1.0, 0.0) if boss_on_left else Vector2(-1.0, 0.0)
	var half_cone := deg_to_rad(30.0)
	var offset_ang := randf_range(-half_cone, half_cone) if rng == null else rng.randf_range(-half_cone, half_cone)
	var dir_xz := rotate_xz_direction(base_dir, offset_ang)
	var dist := roll_distance(rng)
	return {
		"should_move": true,
		"target_position": Vector3(start_pos.x + dir_xz.x * dist, start_pos.y, start_pos.z + dir_xz.y * dist),
	}
