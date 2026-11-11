class_name SpellData
extends WeaponData
## A spell cast from a staff or wand. Cost uses the inherited ammo fields
## (ammo_type = &"mana"), so spending, regen, and the HUD work unchanged.
## Only behavior that weapons don't have lives here.

## Spells with no projectile_scene act on the caster instead.
enum SelfEffect {
	NONE,
	HEAL,
	INVULNERABLE,
}

@export_group("Self Effect")
## What a cast does to the caster when the spell has no projectile.
@export var self_effect: SelfEffect = SelfEffect.NONE
## HEAL: hit points restored per cast.
@export var effect_amount: float = 0.0
## INVULNERABLE: seconds of protection per cast.
@export var effect_duration: float = 0.0

@export_group("Splash")
## Meters. 0 disables splash damage.
@export var splash_radius: float = 0.0
## Damage at the center of the blast, falling linearly to 0 at the radius.
## The creature hit directly takes [member WeaponData.damage] instead.
@export var splash_damage: float = 0.0
## Multiplier on splash damage dealt to the caster. 0 = immune, 1 = full.
@export_range(0.0, 1.0) var caster_splash_scale: float = 0.5

@export_group("Homing")
## Radians per second a HomingProjectile can turn toward its target. 0
## flies straight. Keep it low enough that strafing can still dodge.
@export var homing_turn_rate: float = 0.0
## Player casts lock onto the target nearest the crosshair within this
## many degrees of it. 0 never locks (the missile flies straight).
@export var homing_lock_angle_deg: float = 0.0
## Meters. Targets farther away are never locked.
@export var homing_lock_range: float = 40.0
