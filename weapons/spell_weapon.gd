class_name SpellWeapon
extends RangedWeapon
## A staff or wand that casts a SpellData spell. Firing, mana cost, and
## cooldown come from RangedWeapon; this adds the cast motion (a short
## forward thrust of the view model) and, for homing spells, the lock-on.
## Future non-projectile spells such as healing will hook in here.
##
## Homing spells need a child RayCast3D named "LockCast" (disabled) for
## the lock-on's line-of-sight check. Hitscan spells need one named
## "BoltCast" (disabled) for the hit.

@export_group("Cast Animation")
## Meters the view model thrusts forward when casting.
@export var thrust_distance: float = 0.12
@export var thrust_time: float = 0.06
@export var thrust_recover_time: float = 0.2

var _cast_tween: Tween

@onready var _lock_cast: RayCast3D = get_node_or_null("LockCast") as RayCast3D
@onready var _bolt_cast: RayCast3D = get_node_or_null("BoltCast") as RayCast3D


func _ready() -> void:
	super()
	attacked.connect(_on_attacked)
	# Top-level so they aren't moved by the cast animation.
	for cast: RayCast3D in [_lock_cast, _bolt_cast]:
		if cast != null:
			cast.top_level = true
			cast.enabled = false


func setup(owner_body: CollisionObject3D, aim: Node3D, inventory: Inventory) -> void:
	super(owner_body, aim, inventory)
	for cast: RayCast3D in [_lock_cast, _bolt_cast]:
		if cast != null and owner_body != null:
			cast.add_exception(owner_body)


func _can_fire() -> bool:
	var spell: SpellData = data as SpellData
	var caster: Player = _owner_body as Player
	if spell == null or caster == null:
		return true
	match spell.self_effect:
		SpellData.SelfEffect.HEAL:
			# Never waste mana at full health.
			return caster.can_heal()
		SpellData.SelfEffect.INVULNERABLE:
			# Recasting early would only waste most of the 75 mana.
			return not caster.is_invulnerable()
	return true


func _fire_without_projectile() -> void:
	var spell: SpellData = data as SpellData
	var caster: Player = _owner_body as Player
	if spell == null or caster == null:
		return
	if spell.hitscan_range > 0.0:
		_fire_hitscan(spell)
		return
	match spell.self_effect:
		SpellData.SelfEffect.HEAL:
			caster.heal(spell.effect_amount)
		SpellData.SelfEffect.INVULNERABLE:
			caster.make_invulnerable(spell.effect_duration)


## Instant hit along the aim (lightning): damages the first thing that can
## be hurt, draws the bolt, and flashes the screen.
func _fire_hitscan(spell: SpellData) -> void:
	if _bolt_cast == null:
		push_error("%s: hitscan spell needs a BoltCast child." % name)
		return
	var origin: Vector3 = _aim.global_position
	var forward: Vector3 = -_aim.global_transform.basis.z
	var end: Vector3 = origin + forward * spell.hitscan_range
	_bolt_cast.global_position = origin
	_bolt_cast.target_position = _bolt_cast.to_local(end)
	_bolt_cast.force_raycast_update()
	if _bolt_cast.is_colliding():
		end = _bolt_cast.get_collision_point()
		var target: HealthComponent = HealthComponent.find_on(_bolt_cast.get_collider() as Node)
		if target != null:
			target.take_damage(spell.damage, spell.damage_type, _owner_body)
		_play_strike_sound(target != null)
	if spell.effect_scene != null:
		var bolt: Node3D = spell.effect_scene.instantiate() as Node3D
		# The level owns it, so it doesn't swing with the camera.
		_owner_body.get_parent().add_child(bolt)
		bolt.call(&"strike", origin + forward * muzzle_offset + Vector3.DOWN * 0.15, end)
	if spell.screen_flash_color.a > 0.0:
		EventBus.screen_flash_requested.emit(spell.screen_flash_color)


func _on_projectile_launched(projectile: Projectile) -> void:
	var homing: HomingProjectile = projectile as HomingProjectile
	var spell: SpellData = data as SpellData
	if homing == null or spell == null or spell.homing_lock_angle_deg <= 0.0 or _lock_cast == null:
		return
	homing.homing_target = HomingLock.find_target(
		get_tree(),
		_aim.global_position,
		-_aim.global_transform.basis.z,
		deg_to_rad(spell.homing_lock_angle_deg),
		spell.homing_lock_range,
		_lock_cast
	)


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
