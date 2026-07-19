class_name EnemyHero
extends CharacterBase

enum HeroClass { WARRIOR, KNIGHT, MAGE, RANGER }

enum State { WANDER, CHASE, ATTACK }

@export var hero_class: HeroClass = HeroClass.WARRIOR
@export var detection_range: float = 10.0
@export var wander_radius: float = 5.0
@export var wander_interval: float = 3.0

var _state: State = State.WANDER
var _wander_target: Vector3
var _wander_timer: float = 0.0
var _target: CharacterBase

const CLASS_CONFIG := {
	HeroClass.WARRIOR: {"hp": 80, "damage": 12, "speed": 2.5, "color": Color(0.8, 0.2, 0.2)},
	HeroClass.KNIGHT: {"hp": 100, "damage": 8, "speed": 2.0, "color": Color(0.2, 0.2, 0.8)},
	HeroClass.MAGE: {"hp": 50, "damage": 15, "speed": 2.0, "color": Color(0.6, 0.2, 0.8)},
	HeroClass.RANGER: {"hp": 60, "damage": 10, "speed": 3.0, "color": Color(0.2, 0.7, 0.3)},
}

func _ready() -> void:
	super()
	add_to_group("enemies")
	var config: Dictionary = CLASS_CONFIG[hero_class]
	max_hp = config["hp"]
	current_hp = max_hp
	attack_damage = config["damage"]
	move_speed = config["speed"]
	_wander_target = global_position
	_find_target()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_wander_timer -= delta

	# Re-acquire target if dead or gone
	if not _target or _target.is_dead:
		_find_target()

	if _target and not _target.is_dead:
		var dist := global_position.distance_to(_target.global_position)
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

	move_and_slide()

func _find_target() -> void:
	# Find nearest living enemy (player or other hero)
	var candidates: Array[CharacterBase] = []
	var player := get_tree().get_first_node_in_group("player") as CharacterBase
	if player and not player.is_dead:
		candidates.append(player)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is CharacterBase and e != self and not e.is_dead:
			candidates.append(e)

	var best: CharacterBase = null
	var best_dist := INF
	for c in candidates:
		var d := global_position.distance_to(c.global_position)
		if d < best_dist:
			best = c
			best_dist = d
	_target = best

func _wander_behavior(delta: float) -> void:
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

func take_damage(amount: int) -> void:
	super(amount)
	# Flash white on hit
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			var original := mat.albedo_color
			mat.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mat):
				mat.albedo_color = original
