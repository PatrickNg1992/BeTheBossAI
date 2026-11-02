class_name BaseEnemy
extends BasePuck

enum State { WANDER, CHASE, ATTACK }

@export var detection_range: float = 10.0
@export var wander_radius: float = 5.0
@export var wander_interval: float = 3.0

var _state: State = State.WANDER
var _wander_target: Vector3
var _wander_timer: float = 0.0
var _target: BasePuck


func _ready() -> void:
	super()
	add_to_group("enemies")
	_wander_target = global_position
	_find_target()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_wander_timer -= delta
	if not _target or _target.is_dead:
		_find_target()
	if _target and not _target.is_dead:
		var dist: float = global_position.distance_to(_target.global_position)
		if dist <= attack_range:
			_state = State.ATTACK
		elif dist <= detection_range:
			_state = State.CHASE
		else:
			_state = State.WANDER
	else:
		_state = State.WANDER
	match _state:
		State.WANDER:
			_wander_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior()
	apply_table_physics(delta)
	move_and_slide()


func _find_target() -> void:
	var player := get_tree().get_first_node_in_group("player") as BasePuck
	if player and not player.is_dead:
		_target = player
	else:
		_target = null


func _wander_behavior(_delta: float) -> void:
	if _wander_timer <= 0.0:
		_wander_timer = wander_interval
		_wander_target = global_position + Vector3(
			randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius)
		)
	var dir := (_wander_target - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed


func _chase_behavior(_delta: float) -> void:
	if not _target:
		return
	var dir := (_target.global_position - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed


func _attack_behavior() -> void:
	velocity = Vector3.ZERO
	if _target and can_attack():
		perform_attack(_target)
