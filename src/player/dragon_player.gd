class_name DragonPlayer
extends BaseBossMonster

@export var speed: float = 5.0
@export var keyboard_movement_enabled: bool = false


func _ready() -> void:
	mass = 2.5
	radius = 0.8
	super()


func _physics_process(delta: float) -> void:
	if is_dead or not keyboard_movement_enabled:
		return

	var input_vector := Vector3.ZERO

	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_vector.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_vector.z += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_vector.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_vector.x += 1

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

	velocity.x = input_vector.x * speed
	velocity.z = input_vector.z * speed
	apply_table_physics(delta)
	move_and_slide()

	# _auto_attack()


func _auto_attack() -> void:
	if not can_attack():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: BasePuck = null
	var nearest_dist := INF
	for e in enemies:
		if e is BasePuck and not e.is_dead:
			var d := global_position.distance_to(e.global_position)
			if d < nearest_dist and d <= attack_range:
				nearest = e
				nearest_dist = d
	if nearest:
		perform_attack(nearest)
