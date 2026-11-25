extends MoveSkill

## SMA10001 — Block (Guard Base Move Skill):
## If there are friendly units with Scout or Acolyte (or their Advanced classes),
## calculate lines between the opponent's Boss Monster and them. Glide towards a
## random position on the lines that are within a 180-degree angle from the boss
## monster (avoid moving past the boss) that is close to the Guard.
## If there are no such units, try to move around the boss within a distance of 1 to 3 randomly.

func _init(p_skill_lv: int = 1) -> void:
	super("SMA10001", p_skill_lv)
	name_key = "skill_name_SMA10001"
	description_key = "skill_desc_SMA10001"
	target_classes = ["ACG10001"]
	base_dist_min = 0.0
	base_dist_max = 3.25
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
	var boss_pos := boss_puck.global_position if boss_puck != null else Vector3.ZERO
	var boss_xz := Vector2(boss_pos.x, boss_pos.z)
	var guard_xz := Vector2(start_pos.x, start_pos.z)
	var dist := roll_distance(rng)

	# Collect friendly on-table Scout-tree or Acolyte-tree pucks
	var ally_pucks: Array[BasePuck] = []
	if actor_do != null and uim != null:
		for u in uim.get_all_units():
			if u == null or u.is_dead or u.unit_id == actor_do.unit_id:
				continue
			if AttackSkill.is_opponent_unit(actor_do, u):
				continue
			if not UnitSkillManager.is_unit_on_cue_table(u):
				continue
			var cid := u.class_id if not u.class_id.is_empty() else ClassCodex.class_id_for_enum(u.adventurer_class)
			if ClassCodex.is_in_class_tree(cid, ClassCodex.TREE_SCOUT) or ClassCodex.is_in_class_tree(cid, ClassCodex.TREE_ACOLYTE):
				for p in u.pucks:
					if is_instance_valid(p) and not p.is_dead and not p.is_falling_in_pocket:
						ally_pucks.append(p)

	var aim_point_xz := boss_xz
	if not ally_pucks.is_empty():
		var best_point := boss_xz
		var best_d := INF
		for ap in ally_pucks:
			var ally_xz := Vector2(ap.global_position.x, ap.global_position.z)
			var seg := ally_xz - boss_xz
			var seg_len_sq := seg.length_squared()
			if seg_len_sq < 0.001:
				continue
			# Project Guard onto the segment [0.15, 0.85] (staying in front of the Boss within 180 deg)
			var t_proj := clampf((guard_xz - boss_xz).dot(seg) / seg_len_sq, 0.15, 0.85)
			var jitter := (randf_range(-0.15, 0.15) if rng == null else rng.randf_range(-0.15, 0.15))
			var t_rand := clampf(t_proj + jitter, 0.15, 0.90)
			var pt := boss_xz + seg * t_rand
			var d_to_guard := guard_xz.distance_to(pt)
			if d_to_guard < best_d:
				best_d = d_to_guard
				best_point = pt
		aim_point_xz = best_point
	else:
		# Move around the Boss within a distance of 1.0 to 3.0 randomly
		var ang := randf_range(0.0, TAU) if rng == null else rng.randf_range(0.0, TAU)
		var rad := randf_range(1.0, 3.0) if rng == null else rng.randf_range(1.0, 3.0)
		aim_point_xz = boss_xz + Vector2(cos(ang), sin(ang)) * rad

	var move_vec := aim_point_xz - guard_xz
	var step_xz := guard_xz + (move_vec.normalized() * minf(dist, maxf(dist, move_vec.length())) if move_vec.length_squared() > 0.0001 else Vector2(dist, 0.0))
	return {
		"should_move": true,
		"target_position": Vector3(step_xz.x, start_pos.y, step_xz.y),
	}
