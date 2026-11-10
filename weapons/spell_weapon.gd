class_name SpellWeapon
extends RangedWeapon
## A staff or wand that casts a SpellData spell. Firing, mana cost, and
## cooldown come from RangedWeapon; this adds the cast motion (a short
## forward thrust of the view model). Future non-projectile spells such as
## healing will hook in here.

@export_group("Cast Animation")
## Meters the view model thrusts forward when casting.
@export var thrust_distance: float = 0.12
@export var thrust_time: float = 0.06
@export var thrust_recover_time: float = 0.2

var _cast_tween: Tween


func _ready() -> void:
	super()
	attacked.connect(_on_attacked)


func _on_interrupted() -> void:
	super()
	_stop_cast_animation()
	if _view_model != null:
		_view_model.position = _rest_position


func _on_attacked() -> void:
	if _view_model == null:
		return
	_stop_cast_animation()
	_cast_tween = create_tween()
	_cast_tween.tween_property(_view_model, "position", _rest_position + Vector3.FORWARD * thrust_distance, thrust_time)
	_cast_tween.tween_property(_view_model, "position", _rest_position, thrust_recover_time)


func _stop_cast_animation() -> void:
	if _cast_tween != null:
		_cast_tween.kill()
		_cast_tween = null
