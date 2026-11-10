class_name SpellData
extends WeaponData
## A spell cast from a staff or wand. Cost uses the inherited ammo fields
## (ammo_type = &"mana"), so spending, regen, and the HUD work unchanged.
## Only behavior that weapons don't have lives here.

@export_group("Splash")
## Meters. 0 disables splash damage.
@export var splash_radius: float = 0.0
## Damage at the center of the blast, falling linearly to 0 at the radius.
## The creature hit directly takes [member WeaponData.damage] instead.
@export var splash_damage: float = 0.0
## Multiplier on splash damage dealt to the caster. 0 = immune, 1 = full.
@export_range(0.0, 1.0) var caster_splash_scale: float = 0.5
