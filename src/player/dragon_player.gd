class_name DragonPlayer
extends CharacterBase

@export var speed: float = 5.0

func _ready() -> void:
	super()
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	if is_dead:
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
	move_and_slide()

	# Auto-attack nearest enemy in range
	_auto_attack()

func _auto_attack() -> void:
	if not can_attack():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: CharacterBase = null
	var nearest_dist := INF
	for e in enemies:
		if e is CharacterBase and not e.is_dead:
			var d := global_position.distance_to(e.global_position)
			if d < nearest_dist and d <= attack_range:
				nearest = e
				nearest_dist = d
	if nearest:
		perform_attack(nearest)
