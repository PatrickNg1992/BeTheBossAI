extends CharacterBody3D

@export var speed: float = 5.0

func _physics_process(_delta: float) -> void:
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
