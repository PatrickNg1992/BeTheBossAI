class_name PresentationManager
extends Node

## Battle-scoped manager node (in group "presentation_manager") that controls
## visual/sound effects and animations across Action Time and Settle Time:
## - Attack / Active skill projectile & swipe 3D animations (`~0.30s` stagger, `~0.70s` duration)
## - Constant-speed Move Skill puck glides (disabling the puck's collider during movement)
## - UnitDisplay skill trigger popups
## Respects TimingManager Fast Play time scale and supports `instant_mode` for headless tests.

@export var instant_mode: bool = false
@export var attack_stagger_sec: float = 0.30
@export var attack_anim_duration_sec: float = 0.70
@export var glide_speed_units_per_sec: float = PhysicsConstant.GLIDE_SPEED_UNITS_PER_SEC

var timing_manager: TimingManager = null
var unit_information_manager: UnitInformationManager = null
var event_log: Array[Dictionary] = []
var _active_tweens: Array[Tween] = []


func _ready() -> void:
	add_to_group("presentation_manager")


func bind(p_tm: TimingManager, p_uim: UnitInformationManager) -> void:
	timing_manager = p_tm
	unit_information_manager = p_uim


func clear_log() -> void:
	event_log.clear()


func get_time_scale() -> float:
	if timing_manager != null:
		return maxf(0.1, timing_manager.get_effective_time_scale())
	return 1.0


static func set_puck_collider_disabled(puck: BasePuck, disabled: bool) -> void:
	if puck == null or not is_instance_valid(puck):
		return
	var col := puck.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null:
		col.disabled = disabled


## Plays an Attack or Active skill animation from `actor_puck` toward `target_puck`
## and pops up the skill name on the acting unit's UnitDisplay.
func play_skill_attack_animation(
	actor_do: UnitInformationDO,
	target_do: UnitInformationDO,
	skill: UnitSkill,
	actor_puck: BasePuck = null,
	target_puck: BasePuck = null,
	force_instant: bool = false
) -> void:
	var sk_name := skill.get_localized_name() if skill != null else ""
	var sk_id := skill.skill_id if skill != null else ""
	event_log.append({
		"kind": "attack_anim",
		"actor_unit_id": actor_do.unit_id if actor_do != null else "",
		"target_unit_id": target_do.unit_id if target_do != null else "",
		"skill_id": sk_id,
	})
	if unit_information_manager != null and actor_do != null and not sk_name.is_empty():
		unit_information_manager.trigger_unit_skill_popup(actor_do.unit_id, sk_name)

	if instant_mode or force_instant or not is_inside_tree():
		return
	if actor_puck == null or target_puck == null or not is_instance_valid(actor_puck) or not is_instance_valid(target_puck):
		return

	var parent_3d := actor_puck.get_parent()
	if parent_3d == null:
		return

	var proj := MeshInstance3D.new()
	proj.name = "SkillAttackVFX_%s" % sk_id
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	proj.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = actor_do.slot_color if actor_do != null else Color(1.0, 0.85, 0.3, 1.0)
	proj.material_override = mat
	parent_3d.add_child(proj)

	var start_pos := actor_puck.global_position + Vector3(0.0, 0.25, 0.0)
	var end_pos := target_puck.global_position + Vector3(0.0, 0.25, 0.0)
	proj.global_position = start_pos

	var dur := maxf(0.05, attack_anim_duration_sec / get_time_scale())
	var tw := create_tween()
	_active_tweens.append(tw)
	tw.tween_property(proj, "global_position", end_pos, dur)
	tw.tween_callback(func() -> void:
		if is_instance_valid(proj):
			proj.queue_free()
	)


## Moves `puck` from `from_pos` to `to_pos` at constant speed with its collider
## disabled during the movement (`unitSkills.md` -> `### Move Glide Logic`).
func play_glide_movement(
	actor_do: UnitInformationDO,
	puck: BasePuck,
	from_pos: Vector3,
	to_pos: Vector3,
	force_instant: bool = false
) -> float:
	if puck == null or not is_instance_valid(puck):
		return 0.0
	event_log.append({
		"kind": "move_glide",
		"actor_unit_id": actor_do.unit_id if actor_do != null else "",
		"from": from_pos,
		"to": to_pos,
	})
	set_puck_collider_disabled(puck, true)
	if instant_mode or force_instant or not is_inside_tree():
		puck.global_position = to_pos
		puck.velocity = Vector3.ZERO
		set_puck_collider_disabled(puck, false)
		return 0.0

	var dist := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
	var dur := maxf(0.10, dist / maxf(0.5, glide_speed_units_per_sec * get_time_scale()))
	puck.global_position = from_pos
	puck.velocity = Vector3.ZERO
	var tw := create_tween()
	_active_tweens.append(tw)
	tw.tween_property(puck, "global_position", to_pos, dur)
	tw.tween_callback(func() -> void:
		if is_instance_valid(puck):
			puck.global_position = to_pos
			puck.velocity = Vector3.ZERO
			set_puck_collider_disabled(puck, false)
	)
	return dur
