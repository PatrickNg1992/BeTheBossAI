extends MoveSkill

## SMA10003 — Patrol (Scout Base Move Skill):
## Distance check (centre-to-centre) against the opponent's Boss Monster:
## - If distance < 4.5: glide away within 60 degrees (+-30 deg).
## - If distance > 6.0: glide closer within 60 degrees (+-30 deg).
## - Otherwise (4.5..6.0): glide in a random 360-degree direction.

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10003", p_skill_lv)
	name_key = "skill_name_SMA10003"
	description_key = "skill_desc_SMA10003"
	target_classes = ["ACS10001"]
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
	var boss_puck := find_opponent_boss_puck(actor_do, uim)
	var dist := roll_distance(rng)
	var dir_xz := Vector2(1.0, 0.0)

	if boss_puck != null:
		var to_boss := Vector2(boss_puck.global_position.x - start_pos.x, boss_puck.global_position.z - start_pos.z)
		var d := to_boss.length()
		var half_cone := deg_to_rad(30.0)
		if d < 4.5:
			var ang := randf_range(-half_cone, half_cone) if rng == null else rng.randf_range(-half_cone, half_cone)
			dir_xz = rotate_xz_direction(-to_boss, ang)
		elif d > 6.0:
			var ang := randf_range(-half_cone, half_cone) if rng == null else rng.randf_range(-half_cone, half_cone)
			dir_xz = rotate_xz_direction(to_boss, ang)
		else:
			var ang := randf_range(0.0, TAU) if rng == null else rng.randf_range(0.0, TAU)
			dir_xz = Vector2(cos(ang), sin(ang))
	else:
		var ang := randf_range(0.0, TAU) if rng == null else rng.randf_range(0.0, TAU)
		dir_xz = Vector2(cos(ang), sin(ang))

	return {
		"should_move": true,
		"target_position": Vector3(start_pos.x + dir_xz.x * dist, start_pos.y, start_pos.z + dir_xz.y * dist),
	}
