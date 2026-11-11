class_name EnemyRangedAttack
extends RefCounted
## Fires an enemy's projectile (EnemyData ranged fields) at a target.


## Spawns, aims, and launches the projectile. Returns null if the data's
## scene is not a Projectile.
static func fire(data: EnemyData, shooter: Node3D, target: Node3D, aim_height: float) -> Projectile:
	var projectile: Projectile = data.projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("%s: projectile_scene is not a Projectile." % shooter.name)
		return null
	# Parent to the level, not the enemy, so the shot outlives the shooter
	# and is freed with the level.
	shooter.get_parent().add_child(projectile)
	var muzzle: Vector3 = shooter.global_position + Vector3.UP * data.muzzle_height
	var aim_point: Vector3 = target.global_position + Vector3.UP * aim_height
	projectile.launch(
		muzzle,
		Projectile.aim_velocity(muzzle, aim_point, data.projectile_speed, data.projectile_gravity),
		data.projectile_gravity,
		data.attack_damage,
		data.attack_damage_type,
		shooter as CollisionObject3D
	)
	if data.projectile_data != null:
		projectile.apply_weapon_data(data.projectile_data)
	var homing: HomingProjectile = projectile as HomingProjectile
	if homing != null:
		homing.homing_target = target
	return projectile
