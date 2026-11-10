extends Node
## Global signal hub so systems can talk without holding references to each other.
##
## No class_name: the autoload name (EventBus) is the global identifier, and a
## matching class_name would conflict with it.
##
## Signals are declared here and emitted by other systems, so the
## "unused_signal" warning is suppressed per signal.
## Payloads are intentionally minimal for now; extend them as systems land.

@warning_ignore("unused_signal")
signal player_damaged(amount: float)

@warning_ignore("unused_signal")
signal player_health_changed(current: float, maximum: float)

@warning_ignore("unused_signal")
signal player_died

## Emitted when the player asks to respawn after dying.
@warning_ignore("unused_signal")
signal player_respawn_requested

## Sorted list of KeyRing.KeyType values the player holds in this level.
@warning_ignore("unused_signal")
signal player_keys_changed(keys: Array[int])

@warning_ignore("unused_signal")
signal key_picked_up(key_type: int)

## The player tried a door that needs [param required_key] and lacks it.
@warning_ignore("unused_signal")
signal door_locked(required_key: int)

@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node)

@warning_ignore("unused_signal")
signal secret_found

@warning_ignore("unused_signal")
signal level_completed

@warning_ignore("unused_signal")
signal player_ammo_changed(ammo_type: StringName, amount: int, maximum: int)

## The 3D/HUD render resolution changed (GameView pixel size or window size).
@warning_ignore("unused_signal")
signal render_resolution_changed(render_size: Vector2i)

## Emitted when the player starts raising a weapon. Null means no weapon.
@warning_ignore("unused_signal")
signal player_weapon_changed(weapon_data: WeaponData)
