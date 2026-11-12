class_name KeyPickup
extends Area3D
## A floating key (TrenchBroom item_key). Touching it adds the key to the
## toucher's KeyRing; anything without one (enemies) is ignored.
##
## Expects a child MeshInstance3D named "Sprite" whose material_override is
## local to scene, so each key can show its own sprite.

## Filled by FuncGodot at map build; its key_type overrides the export below.
@export var func_godot_properties: Dictionary = {}
## Used when the key is placed by hand in a scene instead of from a map.
@export_enum("Gold", "Silver", "Bone") var key_type: int = KeyRing.KeyType.GOLD
## One sprite per KeyRing.KeyType, in enum order. A key without a sprite
## falls back to a flat quad in KeyRing.key_color(). Applied at runtime so
## Godot's detect-3D import keeps the textures uncompressed (see Pickup).
@export var sprites: Array[Texture2D] = []
## Pixels below this alpha are cut out, keeping hard pixel-art edges.
@export var alpha_scissor_threshold: float = 0.5
@export var bob_height: float = 0.1
## Full bob cycles per second.
@export var bob_speed: float = 0.8

var _rest_y: float = 0.0
var _bob_phase: float = 0.0

@onready var _sprite: MeshInstance3D = $Sprite
@onready var _material: StandardMaterial3D = _sprite.material_override as StandardMaterial3D


func _ready() -> void:
	if func_godot_properties.has("key_type"):
		key_type = int(func_godot_properties["key_type"])
	if key_type >= 0 and key_type < sprites.size() and sprites[key_type] != null:
		_material.albedo_color = Color.WHITE
		_material.albedo_texture = sprites[key_type]
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_material.alpha_scissor_threshold = alpha_scissor_threshold
	else:
		_material.albedo_color = KeyRing.key_color(key_type)
	_rest_y = _sprite.position.y
	# Random start so several keys in view don't bob in lockstep.
	_bob_phase = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_phase = fmod(_bob_phase + bob_speed * TAU * delta, TAU)
	_sprite.position.y = _rest_y + sin(_bob_phase) * bob_height


func _on_body_entered(body: Node3D) -> void:
	var keys: KeyRing = KeyRing.find_on(body)
	if keys == null:
		return
	keys.add_key(key_type)
	EventBus.key_picked_up.emit(key_type)
	AudioManager.play_sfx(AudioManager.sounds.key_pickup)
	queue_free()
