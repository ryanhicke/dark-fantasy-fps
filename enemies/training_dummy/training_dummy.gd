extends StaticBody3D
## TEST ONLY. A stationary target for checking weapon hits before real
## enemies exist. Flashes when hit, vanishes on death, then resets.

@export var flash_color: Color = Color(1.0, 0.15, 0.1)
@export var flash_duration: float = 0.15
@export var respawn_delay: float = 2.0

var _base_color: Color

@onready var _health: HealthComponent = $HealthComponent
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _material: StandardMaterial3D = _mesh.get_active_material(0) as StandardMaterial3D
@onready var _respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	_base_color = _material.albedo_color
	_respawn_timer.wait_time = respawn_delay
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)


func _on_damaged(amount: float, type: Damage.Type, _source: Node) -> void:
	print("%s took %.1f %s damage (%.1f left)" % [
		name, amount, Damage.Type.keys()[type], _health.current_health
	])
	_material.albedo_color = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(_material, "albedo_color", _base_color, flash_duration)


func _on_died(_source: Node) -> void:
	print("%s destroyed" % name)
	_mesh.visible = false
	# Deferred: changing collision state inside a physics callback is not allowed.
	_collision.set_deferred("disabled", true)
	_respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	_material.albedo_color = _base_color
	_mesh.visible = true
	_collision.disabled = false
	_health.reset()
