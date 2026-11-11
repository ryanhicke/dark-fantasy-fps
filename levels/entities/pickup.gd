class_name Pickup
extends Area3D
## Base for things the player collects by touching them (weapons, ammo).
## Bobs a placeholder sprite; subclasses decide what collecting does.
##
## Expects a child MeshInstance3D named "Sprite" whose material_override is
## local to scene, so [member tint] stays per-pickup. Set collision_layer to
## 0 and the mask to the player's layer.

## Placeholder color until pickups have sprites.
@export var tint: Color = Color(1.0, 1.0, 1.0)
@export var bob_height: float = 0.1
## Full bob cycles per second.
@export var bob_speed: float = 0.8

var _rest_y: float = 0.0
var _bob_phase: float = 0.0

@onready var _sprite: MeshInstance3D = $Sprite


func _ready() -> void:
	(_sprite.material_override as StandardMaterial3D).albedo_color = tint
	_rest_y = _sprite.position.y
	# Random start so several pickups in view don't bob in lockstep.
	_bob_phase = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_phase = fmod(_bob_phase + bob_speed * TAU * delta, TAU)
	_sprite.position.y = _rest_y + sin(_bob_phase) * bob_height


func _on_body_entered(body: Node3D) -> void:
	var player: Player = body as Player
	if player == null or HealthComponent.find_on(player).is_dead():
		return
	if not _collect(player):
		return
	EventBus.pickup_collected.emit(_message())
	queue_free()


## Override. Returns true if the player gained anything; otherwise the
## pickup stays (e.g. ammo while already full), Doom-style.
func _collect(_player: Player) -> bool:
	return false


## Override. Shown on the HUD when collected.
func _message() -> String:
	return ""
