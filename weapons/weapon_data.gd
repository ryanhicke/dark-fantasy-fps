class_name WeaponData
extends Resource
## Tunable stats for one weapon. New weapons should mostly be a new .tres
## file; new code is only for genuinely new behavior.

@export var display_name: String = ""

@export_group("Damage")
@export var damage: float = 10.0
@export var damage_type: Damage.Type = Damage.Type.PHYSICAL

@export_group("Timing")
## Seconds from the start of one attack to the earliest start of the next.
@export var cooldown: float = 0.5
## Seconds between starting an attack and the hit landing. Keep below
## cooldown, otherwise the next attack waits for the hit anyway.
@export var windup: float = 0.0

@export_group("Melee")
## Reach in meters, measured from the camera.
@export var melee_range: float = 2.0
## Radius of the swept sphere. Larger is more forgiving to aim.
@export var melee_radius: float = 0.35
