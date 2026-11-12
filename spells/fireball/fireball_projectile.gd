class_name FireballProjectile
extends Projectile
## Explodes on impact: full damage to whatever it hit, plus falloff splash
## damage to everything else in range that the blast can see, including
## the caster (scaled by SpellData.caster_splash_scale).
##
## Expects children "SplashCast" (ShapeCast3D) and "SplashSightCast"
## (RayCast3D), both disabled. They are updated once per explosion, which
## avoids the Dictionary allocations of direct space queries.

## Splash measures to a target's body center, not its feet. Player and
## enemies are both about 1.8 m tall with origins at the feet.
const TARGET_CENTER_HEIGHT: float = 0.9
## Meters the blast center is pulled back from the impact point, so it sits
## in open air instead of inside the wall it hit.
const BLAST_STANDOFF: float = 0.1

## Visual-only effect spawned at the blast center.
@export var explosion_scene: PackedScene

var splash_radius: float = 0.0
var splash_damage: float = 0.0
var caster_splash_scale: float = 0.0

@onready var _splash_cast: ShapeCast3D = $SplashCast
@onready var _sight_cast: RayCast3D = $SplashSightCast


func apply_weapon_data(weapon_data: WeaponData) -> void:
	var spell: SpellData = weapon_data as SpellData
	if spell == null:
		return
	splash_radius = spell.splash_radius
	splash_damage = spell.splash_damage
	caster_splash_scale = spell.caster_splash_scale


## Linear falloff: [param max_damage] at the center, 0 at [param radius].
## Static so tests run the exact math the game uses.
static func splash_damage_at(distance: float, radius: float, max_damage: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	return max_damage * (1.0 - maxf(distance, 0.0) / radius)


func _on_hit(collider: Object, point: Vector3) -> void:
	var direct: HealthComponent = HealthComponent.find_on(collider as Node)
	if direct != null:
		direct.take_damage(damage, damage_type, source)
	var center: Vector3 = point - velocity.normalized() * BLAST_STANDOFF
	if splash_radius > 0.0 and splash_damage > 0.0:
		_apply_splash(center, collider)
	_spawn_explosion(center)
	_play_impact_sound(center)
	queue_free()


func _apply_splash(center: Vector3, direct_collider: Object) -> void:
	var sphere: SphereShape3D = _splash_cast.shape as SphereShape3D
	sphere.radius = splash_radius
	_splash_cast.global_position = center
	_splash_cast.force_shapecast_update()
	_sight_cast.global_position = center
	for i: int in _splash_cast.get_collision_count():
		var body: Node3D = _splash_cast.get_collider(i) as Node3D
		# The direct hit already took full damage; don't add splash on top.
		if body == null or body == direct_collider:
			continue
		var health: HealthComponent = HealthComponent.find_on(body)
		if health == null or health.is_dead():
			continue
		var body_center: Vector3 = body.global_position + Vector3.UP * TARGET_CENTER_HEIGHT
		if not _blast_reaches(body, body_center):
			continue
		var amount: float = splash_damage_at(center.distance_to(body_center), splash_radius, splash_damage)
		if body == source:
			amount *= caster_splash_scale
		health.take_damage(amount, damage_type, source)


## False if a wall (or another body) stands between the blast and the target.
func _blast_reaches(body: Node3D, body_center: Vector3) -> bool:
	_sight_cast.target_position = _sight_cast.to_local(body_center)
	_sight_cast.force_raycast_update()
	return not _sight_cast.is_colliding() or _sight_cast.get_collider() == body


func _spawn_explosion(center: Vector3) -> void:
	if explosion_scene == null:
		return
	var effect: Node3D = explosion_scene.instantiate() as Node3D
	get_parent().add_child(effect)
	effect.global_position = center
