class_name EnemyHero
extends BaseEnemy

enum HeroClass { WARRIOR, KNIGHT, MAGE, RANGER }

@export var hero_class: HeroClass = HeroClass.WARRIOR

const CLASS_CONFIG := {
	HeroClass.WARRIOR: {"hp": 80, "damage": 12, "speed": 2.5, "mass": 1.5, "color": Color(0.8, 0.2, 0.2)},
	HeroClass.KNIGHT: {"hp": 100, "damage": 8, "speed": 2.0, "mass": 2.0, "color": Color(0.2, 0.2, 0.8)},
	HeroClass.MAGE: {"hp": 50, "damage": 15, "speed": 2.0, "mass": 1.0, "color": Color(0.6, 0.2, 0.8)},
	HeroClass.RANGER: {"hp": 60, "damage": 10, "speed": 3.0, "mass": 1.2, "color": Color(0.2, 0.7, 0.3)},
}


func _ready() -> void:
	super()
	var config: Dictionary = CLASS_CONFIG[hero_class]
	max_hp = config["hp"]
	current_hp = max_hp
	attack_damage = config["damage"]
	move_speed = config["speed"]
	mass = config["mass"]


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
