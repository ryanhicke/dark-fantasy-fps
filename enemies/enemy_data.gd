class_name EnemyData
extends Resource
## Tunable stats for one enemy type. New enemies should mostly be a new
## .tres file plus a sprite; new code only for genuinely new behavior.

@export var display_name: String = ""
@export var max_health: float = 60.0
## Armor, resistances, and weaknesses by damage type. Null means no
## modifiers. Shared by every enemy using this data.
@export var resistances: DamageResistances
## Stand-in for sprite frames until real art exists: tints the placeholder
## quad. Alpha 0 keeps the scene's material color.
@export var placeholder_color: Color = Color(0.0, 0.0, 0.0, 0.0)

@export_group("Movement")
## Chase speed in m/s. Keep well below the player's so they can kite.
@export var move_speed: float = 4.0

## Flyers ignore gravity and chase toward a point above the target. Give
## the scene motion_mode = Floating so there is no floor snapping.
@export var flying: bool = false
## Meters above the target's origin that a flyer tries to hold.
@export var hover_height: float = 2.5

@export_group("Senses")
## Meters. The player must also be in line of sight to wake the enemy.
@export var sight_range: float = 20.0

@export_group("Attack")
## Meters between the enemy's and target's origins. Must exceed the sum of
## both collision radii, or the enemy can never get close enough to swing.
@export var attack_range: float = 1.8
@export var attack_damage: float = 10.0
@export var attack_damage_type: Damage.Type = Damage.Type.SLASH
## Seconds of telegraph before the hit lands. Backing out of range during
## the windup dodges the attack.
@export var attack_windup: float = 0.5
## Seconds after the hit before the enemy can move or attack again.
@export var attack_recovery: float = 0.6

@export_group("Ranged Attack")
## Set to make this a ranged enemy: at the end of the windup it fires this
## scene (a Projectile) at the target instead of hitting directly. Ranged
## enemies also need line of sight to start an attack.
@export var projectile_scene: PackedScene
## Launch speed in m/s.
@export var projectile_speed: float = 25.0
## Downward pull in m/s² on the projectile; the shot is aimed up to make up for it.
@export var projectile_gravity: float = 0.0
## Meters above the enemy's origin where projectiles spawn.
@export var muzzle_height: float = 1.4
## Optional. Passed to the projectile's apply_weapon_data() for extra
## fields such as fireball splash (a SpellData). Damage, type, and speed
## still come from this resource.
@export var projectile_data: WeaponData

@export_group("Sounds")
## Played once when the enemy wakes up. Null is silent.
@export var alert_sound: AudioStream

@export_group("Second Phase")
## If set, a lethal hit doesn't kill: the enemy collapses, then rises in
## place with this data (e.g. a disguised werewolf). Only the final death
## counts as a kill.
@export var revive_as: EnemyData
## Seconds spent lying down before rising as [member revive_as].
@export var revive_delay: float = 1.2

@export_group("Pain")
## 0..1 chance that a non-lethal hit staggers the enemy, cancelling its attack.
@export_range(0.0, 1.0) var pain_chance: float = 0.5
@export var pain_duration: float = 0.35


func is_ranged() -> bool:
	return projectile_scene != null
