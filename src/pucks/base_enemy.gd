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
var _ai_active: bool = false
var _in_action_time: bool = false
var _clock_paused: bool = false


func _ready() -> void:
	super()
	add_to_group("enemies")
	_wander_target = global_position
	_find_target()
	_bind_timing_signals()


func _bind_timing_signals() -> void:
	var tm := _find_timing_manager()
	if tm == null:
		_ai_active = true
		return
	if not tm.timing_changed.is_connected(_on_timing_changed):
		tm.timing_changed.connect(_on_timing_changed)
	if not tm.pause_changed.is_connected(_on_pause_changed):
		tm.pause_changed.connect(_on_pause_changed)
	_in_action_time = tm.get_current_timing() == TimingManager.TIMING_ACTION
	_clock_paused = tm.is_paused()
	_update_ai_active()


func _find_timing_manager() -> TimingManager:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("TimingManager") as TimingManager
		if sibling != null:
			return sibling
	if is_inside_tree():
		return get_tree().get_first_node_in_group("timing_manager") as TimingManager
	return null


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	var was_action := _in_action_time
	_in_action_time = new_timing == TimingManager.TIMING_ACTION
	_update_ai_active(was_action and not _in_action_time)


func _on_pause_changed(paused: bool) -> void:
	_clock_paused = paused
	_update_ai_active(false)


func _update_ai_active(stop_ai_motion: bool = false) -> void:
	_ai_active = _in_action_time and not _clock_paused
	if stop_ai_motion:
		velocity.x = 0.0
		velocity.z = 0.0


func is_ai_active() -> bool:
	return _ai_active


func _process(delta: float) -> void:
	if not _ai_active:
		return
	super(delta)


func _physics_process(delta: float) -> void:
	if is_dead or not _ai_active:
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
