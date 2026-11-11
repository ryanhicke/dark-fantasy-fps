class_name SpinningProjectile
extends Projectile
## A projectile whose model tumbles end over end in flight (the francisca),
## so the arc reads clearly. Only the child "Spin" node rotates; the
## projectile itself still faces its velocity for the hit ray.

## Radians per second around the local X axis (end over end).
@export var spin_speed: float = 18.0

@onready var _spin: Node3D = $Spin


func _process(delta: float) -> void:
	_spin.rotate_x(-spin_speed * delta)
