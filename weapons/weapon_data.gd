class_name WeaponData
extends Resource
## Tunable stats for one weapon. New weapons should mostly be a new .tres
## file; new code is only for genuinely new behavior.

@export var display_name: String = ""
## Stable name used for ownership and save data (e.g. &"bow"). Never
## rename once levels or saves use it.
@export var id: StringName = &""
## Number key that selects this weapon, 1-9. Fixed per weapon, Doom-style,
## so a key always means the same weapon whatever else is owned.
@export_range(1, 9) var slot: int = 1
## Ammo given along with the weapon when its pickup is collected.
@export var pickup_ammo: int = 0

@export_group("Damage")
@export var damage: float = 10.0
@export var damage_type: Damage.Type = Damage.Type.SLASH

@export_group("Timing")
## Seconds from the start of one attack to the earliest start of the next.
@export var cooldown: float = 0.5
## Seconds between starting an attack and the hit landing. Keep below
## cooldown, otherwise the next attack waits for the hit anyway.
@export var windup: float = 0.0

@export_group("Ammo")
## Inventory ammo key, e.g. &"arrows". Empty means the weapon needs no ammo.
@export var ammo_type: StringName = &""
@export var ammo_cost: int = 0

@export_group("Melee")
## Reach in meters, measured from the camera.
@export var melee_range: float = 2.0
## Radius of the swept sphere. Larger is more forgiving to aim.
@export var melee_radius: float = 0.35

@export_group("Projectile")
@export var projectile_scene: PackedScene
## Launch speed in m/s for an uncharged shot.
@export var projectile_speed: float = 30.0
## Downward pull in m/s² on the projectile. 0 flies dead straight.
@export var projectile_gravity: float = 0.0

@export_group("Charge")
## Seconds to reach full charge while the trigger is held. 0 = no charging:
## the weapon fires on press and repeats while held.
@export var charge_time: float = 0.0
## Damage at full charge. Uncharged shots use [member damage]; partial
## charges blend linearly between the two.
@export var max_charge_damage: float = 0.0
## Launch speed at full charge. Partial charges blend from
## [member projectile_speed].
@export var max_charge_speed: float = 0.0
