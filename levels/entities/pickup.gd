class_name Pickup
extends Area3D
## Base for things the player collects by touching them (weapons, ammo).
## Bobs a placeholder sprite; subclasses decide what collecting does.
##
## Expects a child MeshInstance3D named "Sprite" whose material_override is
## local to scene, so [member tint] stays per-pickup. Set collision_layer to
## 0 and the mask to the player's layer.

## Filled by FuncGodot at map build; appear_on_unseal (0/1) overrides the
## export below.
@export var func_godot_properties: Dictionary = {}
## Placeholder color until pickups have sprites.
@export var tint: Color = Color(1.0, 1.0, 1.0)
## Hidden and untouchable until the great demon is unsealed (its last
## obelisk falls), e.g. the lightning pickup and the mana beside it.
@export var appear_on_unseal: bool = false
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
	if func_godot_properties.has("appear_on_unseal"):
		appear_on_unseal = int(func_godot_properties["appear_on_unseal"]) != 0
	if appear_on_unseal:
		_set_present(false)
		EventBus.great_demon_unsealed.connect(_set_present.bind(true), CONNECT_ONE_SHOT)


func _set_present(present: bool) -> void:
	visible = present
	set_process(present)
	# Deferred: may run inside a physics callback (an obelisk breaking).
	set_deferred("monitoring", present)


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
