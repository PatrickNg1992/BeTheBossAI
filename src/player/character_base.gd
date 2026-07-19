class_name CharacterBase
extends CharacterBody3D

signal health_changed(current_hp: int, max_hp: int)
signal died()

@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

var current_hp: int
var is_dead: bool = false
var _attack_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func die() -> void:
	is_dead = true
	died.emit()
	# Remove after short delay
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

func can_attack() -> bool:
	return _attack_timer <= 0.0 and not is_dead

func perform_attack(target: CharacterBase) -> void:
	if not can_attack():
		return
	_attack_timer = attack_cooldown
	target.take_damage(attack_damage)

func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
