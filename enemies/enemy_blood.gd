class_name EnemyBlood
extends CPUParticles3D
## Doom-style blood (or bone dust, or ichor) spray when an enemy is hit, and
## a bigger one when it dies. Flat unshaded billboard squares, so it costs
## one tiny draw per burst and suits the pixel look.
##
## One emitter per enemy, built at spawn, so hits never allocate.

const PARTICLE_COUNT: int = 10
const PARTICLE_SIZE: float = 0.07
const LIFETIME: float = 0.55
const HIT_SPEED: float = 2.5
const DEATH_SPEED: float = 4.5

var _material: StandardMaterial3D


static func create(color: Color) -> EnemyBlood:
	var blood: EnemyBlood = EnemyBlood.new()
	blood._build(color)
	return blood


func _build(color: Color) -> void:
	name = "Blood"
	emitting = false
	one_shot = true
	explosiveness = 1.0
	amount = PARTICLE_COUNT
	lifetime = LIFETIME
	# World space, so a moving or dying enemy leaves its spray behind.
	local_coords = false
	direction = Vector3.UP
	spread = 70.0
	gravity = Vector3(0.0, -12.0, 0.0)
	initial_velocity_min = HIT_SPEED * 0.5
	initial_velocity_max = HIT_SPEED
	scale_amount_min = 0.6
	scale_amount_max = 1.4
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(PARTICLE_SIZE, PARTICLE_SIZE)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = _material
	mesh = quad
	set_spray_color(color)


func set_spray_color(color: Color) -> void:
	_material.albedo_color = color
	visible = color.a > 0.0


func spray_hit() -> void:
	_spray(HIT_SPEED)


func spray_death() -> void:
	_spray(DEATH_SPEED)


func _spray(speed: float) -> void:
	if not visible:
		return
	initial_velocity_min = speed * 0.5
	initial_velocity_max = speed
	restart()
