class_name ExplosionEffect
extends Node3D
## Visual-only burst: grows and fades a billboarded sprite, then frees
## itself. Fakes a glow without a real-time light (performance rule 5).
##
## Expects a child MeshInstance3D named "Sprite" whose material_override is
## a transparent StandardMaterial3D, local to scene so each burst fades alone.

@export var duration: float = 0.3
## Sprite scale at the end of the burst (it starts at 1).
@export var end_scale: float = 2.5

@onready var _sprite: MeshInstance3D = $Sprite
@onready var _material: StandardMaterial3D = _sprite.material_override as StandardMaterial3D


func _ready() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_sprite, "scale", Vector3.ONE * end_scale, duration)
	tween.tween_property(_material, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
