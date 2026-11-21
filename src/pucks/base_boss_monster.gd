class_name BaseBossMonster
extends BasePuck

signal bar_broken(bars_remaining: int)
signal bars_changed(bars_remaining: int, current_bar_hp: int, bar_max_hp: int)
signal card_draw_requested()

var is_invincible: bool = false


func _ready() -> void:
	super()
	add_to_group("player")


func notify_bar_broken_from_manager(bars_left: int) -> void:
	bar_broken.emit(bars_left)
	if bars_left > 0:
		card_draw_requested.emit()
		_start_invincibility()


func _start_invincibility() -> void:
	if not is_inside_tree():
		return
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
	if not mesh or not is_inside_tree():
		return
	while is_invincible:
		mesh.visible = false
		await get_tree().create_timer(0.15).timeout
		if not is_invincible or not is_inside_tree():
			break
		mesh.visible = true
		await get_tree().create_timer(0.15).timeout
