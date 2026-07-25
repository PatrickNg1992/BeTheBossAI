class_name BaseBossMonster
extends BasePuck

signal bar_broken(bars_remaining: int)
signal bars_changed(bars_remaining: int, current_bar_hp: int, bar_max_hp: int)
signal card_draw_requested()

@export var max_bars: int = 15
@export var bar_max_hp: int = 100

var bars_remaining: int
var is_invincible: bool = false


func _ready() -> void:
	super()
	add_to_group("player")
	bars_remaining = max_bars
	current_hp = bar_max_hp
	max_hp = bar_max_hp
	bars_changed.emit(bars_remaining, current_hp, bar_max_hp)


func take_damage(amount: int) -> void:
	if is_dead or is_invincible:
		return
	var remaining_damage: int = amount
	while remaining_damage > 0 and not is_dead:
		var dmg_to_bar: int = mini(remaining_damage, current_hp)
		current_hp -= dmg_to_bar
		remaining_damage -= dmg_to_bar
		health_changed.emit(current_hp, max_hp)
		bars_changed.emit(bars_remaining, current_hp, bar_max_hp)

		if current_hp <= 0:
			bars_remaining -= 1
			bar_broken.emit(bars_remaining)

			if bars_remaining <= 0:
				die()
				return

			current_hp = bar_max_hp
			health_changed.emit(current_hp, max_hp)
			bars_changed.emit(bars_remaining, current_hp, bar_max_hp)
			card_draw_requested.emit()
			_start_invincibility()
			remaining_damage = 0


func _start_invincibility() -> void:
	is_invincible = true
	_invincible_flash()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self):
		is_invincible = false
		var mesh := get_node_or_null("PuckMesh") as MeshInstance3D
		if mesh:
			mesh.visible = true

func _invincible_flash() -> void:
	var mesh := get_node_or_null("PuckMesh") as MeshInstance3D
	if not mesh:
		return
	while is_invincible:
		mesh.visible = false
		await get_tree().create_timer(0.15).timeout
		if not is_invincible:
			break
		mesh.visible = true
		await get_tree().create_timer(0.15).timeout
