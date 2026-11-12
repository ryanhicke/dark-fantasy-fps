class_name CrystalObelisk
extends StaticBody3D
## A Level 8 crystal obelisk (docs/enemies.md, great demon). Only one
## damage type hurts it, shown by the icon on top: warhammer (BLUNT),
## staff of fireball (FIRE), francisca (THROWN), or wand of magic missile
## (MAGIC). Breaking it emits EventBus.obelisk_destroyed.
##
## Joins the homing target group so the magic missile can lock onto it,
## even when it is placed high up or behind a gap.

const ICON_TEXT: Dictionary[Damage.Type, String] = {
	Damage.Type.BLUNT: "HAMMER",
	Damage.Type.FIRE: "FIRE",
	Damage.Type.THROWN: "AXE",
	Damage.Type.MAGIC: "MISSILE",
}
const CRYSTAL_TINT: Dictionary[Damage.Type, Color] = {
	Damage.Type.BLUNT: Color(0.7, 0.72, 0.78),
	Damage.Type.FIRE: Color(1.0, 0.55, 0.2),
	Damage.Type.THROWN: Color(0.75, 0.6, 0.4),
	Damage.Type.MAGIC: Color(0.5, 0.7, 1.0),
}
## Meters above the origin that homing missiles aim at (crystal center).
const AIM_HEIGHT: float = 1.5

## Filled by FuncGodot at map build; its weak_to overrides the export below.
@export var func_godot_properties: Dictionary = {}
## The only damage type that hurts this obelisk.
@export var weak_to: Damage.Type = Damage.Type.BLUNT
@export var flash_color: Color = Color(1.0, 1.0, 1.0)
@export var flash_duration: float = 0.1

var _base_color: Color

@onready var _health: HealthComponent = $HealthComponent
@onready var _crystal: MeshInstance3D = $Crystal
@onready var _icon: Label3D = $Icon
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _material: StandardMaterial3D = _crystal.material_override as StandardMaterial3D


## Every type immune except [param type]. Static so tests can check it.
static func resistances_for(type: Damage.Type) -> DamageResistances:
	var result: DamageResistances = DamageResistances.new()
	result.slash = 0.0
	result.pierce = 0.0
	result.blunt = 0.0
	result.fire = 0.0
	result.lightning = 0.0
	result.magic = 0.0
	result.thrown = 0.0
	match type:
		Damage.Type.SLASH:
			result.slash = 1.0
		Damage.Type.PIERCE:
			result.pierce = 1.0
		Damage.Type.BLUNT:
			result.blunt = 1.0
		Damage.Type.FIRE:
			result.fire = 1.0
		Damage.Type.LIGHTNING:
			result.lightning = 1.0
		Damage.Type.MAGIC:
			result.magic = 1.0
		Damage.Type.THROWN:
			result.thrown = 1.0
	return result


func _enter_tree() -> void:
	add_to_group(HomingProjectile.TARGET_GROUP)


func _ready() -> void:
	if func_godot_properties.has("weak_to"):
		weak_to = int(func_godot_properties["weak_to"]) as Damage.Type
	_health.resistances = resistances_for(weak_to)
	_base_color = CRYSTAL_TINT.get(weak_to, Color.WHITE)
	_material.albedo_color = _base_color
	_icon.text = ICON_TEXT.get(weak_to, "?")
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	_health.immune_hit.connect(_on_immune_hit)


## HomingProjectile.TARGET_GROUP contract.
func can_be_targeted() -> bool:
	return not _health.is_dead()


## HomingProjectile.TARGET_GROUP contract.
func get_aim_point() -> Vector3:
	return global_position + Vector3.UP * AIM_HEIGHT


func _on_damaged(_amount: float, _type: Damage.Type, _source: Node) -> void:
	_material.albedo_color = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(_material, "albedo_color", _base_color, flash_duration)


func _on_immune_hit(_type: Damage.Type, _source: Node) -> void:
	AudioManager.play_sfx_at(AudioManager.sounds.obelisk_clink, get_aim_point())


func _on_died(_source: Node) -> void:
	AudioManager.play_sfx_at(AudioManager.sounds.obelisk_shatter, get_aim_point())
	_crystal.visible = false
	_icon.visible = false
	# Deferred: changing collision state inside a physics callback is not allowed.
	_collision.set_deferred("disabled", true)
	EventBus.obelisk_destroyed.emit()
