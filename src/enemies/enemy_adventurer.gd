class_name EnemyAdventurer
extends BaseEnemy

enum AdventurerClass { WARRIOR, KNIGHT, MAGE, RANGER }

@export var adventurer_class: AdventurerClass = AdventurerClass.WARRIOR

const CLASS_CONFIG := {
	AdventurerClass.WARRIOR: {"hp": 80, "damage": 12, "speed": 2.5, "mass": 1.5, "radius": 0.6, "color": Color(0.8, 0.2, 0.2)},
	AdventurerClass.KNIGHT: {"hp": 100, "damage": 8, "speed": 2.0, "mass": 1.75, "radius": 0.65, "color": Color(0.2, 0.2, 0.8)},
	AdventurerClass.MAGE: {"hp": 50, "damage": 15, "speed": 2.0, "mass": 1.25, "radius": 0.55, "color": Color(0.6, 0.2, 0.8)},
	AdventurerClass.RANGER: {"hp": 60, "damage": 10, "speed": 3.0, "mass": 1.35, "radius": 0.57, "color": Color(0.2, 0.7, 0.3)},
}


func _ready() -> void:
	super()
	var config: Dictionary = CLASS_CONFIG[adventurer_class]
	max_hp = config["hp"]
	current_hp = max_hp
	attack_damage = config["damage"]
	move_speed = config["speed"]
	mass = config["mass"]
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		radius = (col_shape.shape as CylinderShape3D).radius
	else:
		radius = config["radius"]


func take_damage(amount: int) -> void:
	super(amount)
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			var original := mat.albedo_color
			mat.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mat):
				mat.albedo_color = original
