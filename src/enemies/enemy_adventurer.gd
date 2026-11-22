class_name EnemyAdventurer
extends BaseEnemy

enum AdventurerClass {
	BRAWLER = 0,
	GUARD = 1,
	ACOLYTE = 2,
	SCOUT = 3,
	WARRIOR = 0,
	KNIGHT = 1,
	MAGE = 2,
	RANGER = 3,
}

@export var adventurer_class: AdventurerClass = AdventurerClass.BRAWLER

const CLASS_CONFIG := {
	AdventurerClass.BRAWLER: {"hp": 2200, "damage": 120, "speed": 2.5, "mass": 1.5, "radius": 0.6, "color": Color(0.8, 0.2, 0.2)},
	AdventurerClass.GUARD: {"hp": 3000, "damage": 80, "speed": 2.0, "mass": 1.75, "radius": 0.65, "color": Color(0.2, 0.2, 0.8)},
	AdventurerClass.ACOLYTE: {"hp": 1500, "damage": 150, "speed": 2.0, "mass": 1.25, "radius": 0.55, "color": Color(0.6, 0.2, 0.8)},
	AdventurerClass.SCOUT: {"hp": 2200, "damage": 100, "speed": 3.0, "mass": 1.35, "radius": 0.57, "color": Color(0.2, 0.7, 0.3)},
}


func _ready() -> void:
	super()
	var config: Dictionary = CLASS_CONFIG[adventurer_class]
	move_speed = config["speed"]
	mass = config["mass"]
	var col_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape != null and col_shape.shape is CylinderShape3D:
		radius = (col_shape.shape as CylinderShape3D).radius
	else:
		radius = config["radius"]


func take_damage(amount: int) -> void:
	super(amount)
	if not is_inside_tree():
		return
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			var original := mat.albedo_color
			mat.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mat):
				mat.albedo_color = original
