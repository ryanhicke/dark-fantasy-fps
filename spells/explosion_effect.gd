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
## Blast sound, played through the pool so it outlives this short effect.
@export var sound: AudioStream
## View shake (0..1) for a player standing at the blast.
@export var shake_strength: float = 0.5
## Meters from the blast at which the shake fades to nothing.
@export var shake_radius: float = 10.0

@onready var _sprite: MeshInstance3D = $Sprite
@onready var _material: StandardMaterial3D = _sprite.material_override as StandardMaterial3D
## Optional burst of sparks; fired once at spawn.
@onready var _sparks: CPUParticles3D = get_node_or_null("Sparks") as CPUParticles3D


func _ready() -> void:
	# Deferred: the spawner sets global_position right after add_child.
	_play_sound.call_deferred()
	if _sparks != null:
		# Deferred with the sound: emitting before the spawner moves the
		# effect would spray the sparks from the world origin.
		_sparks.restart.call_deferred()
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_sprite, "scale", Vector3.ONE * end_scale, duration)
	tween.tween_property(_material, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)


func _play_sound() -> void:
	AudioManager.play_sfx_at(sound, global_position)
	_shake_view()


func _shake_view() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or shake_strength <= 0.0 or shake_radius <= 0.0:
		return
	var falloff: float = 1.0 - global_position.distance_to(camera.global_position) / shake_radius
	if falloff > 0.0:
		EventBus.screen_shake_requested.emit(shake_strength * falloff)
