extends StaticBody3D
## DEV ONLY. Stands in for a Level 8 crystal obelisk until the real ones
## exist: any weapon breaks it, and breaking it emits
## EventBus.obelisk_destroyed so the great demon fight can be tested.
## The real obelisk is weak to one specific weapon (docs/enemies.md).

@export var flash_color: Color = Color(1.0, 1.0, 1.0)
@export var flash_duration: float = 0.1

var _base_color: Color

@onready var _health: HealthComponent = $HealthComponent
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _material: StandardMaterial3D = _mesh.get_active_material(0) as StandardMaterial3D


func _ready() -> void:
	_base_color = _material.albedo_color
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _on_damaged(_amount: float, _type: Damage.Type, _source: Node) -> void:
	_material.albedo_color = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(_material, "albedo_color", _base_color, flash_duration)


func _on_died(_source: Node) -> void:
	_mesh.visible = false
	# Deferred: changing collision state inside a physics callback is not allowed.
	_collision.set_deferred("disabled", true)
	EventBus.obelisk_destroyed.emit()
