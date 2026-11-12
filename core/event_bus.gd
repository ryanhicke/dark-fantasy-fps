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

@warning_ignore("unused_signal")
signal player_healed(amount: float)

## Full-screen flash, e.g. a lightning cast. Uses the color's alpha.
@warning_ignore("unused_signal")
signal screen_flash_requested(color: Color)

## The great demon's last obelisk fell: it can now be hurt (by lightning),
## and pickups set to appear_on_unseal show up.
@warning_ignore("unused_signal")
signal great_demon_unsealed

## The armor spell started (true) or wore off (false).
@warning_ignore("unused_signal")
signal player_invulnerability_changed(active: bool)

## The armor spell is about to wear off (Invulnerability.warning_time left).
@warning_ignore("unused_signal")
signal player_invulnerability_ending

## Emitted when the player asks to respawn after dying.
@warning_ignore("unused_signal")
signal player_respawn_requested

## Sorted list of KeyRing.KeyType values the player holds in this level.
@warning_ignore("unused_signal")
signal player_keys_changed(keys: Array[int])

@warning_ignore("unused_signal")
signal key_picked_up(key_type: int)

## A weapon or ammo pickup was collected. [param message] is shown on the HUD.
@warning_ignore("unused_signal")
signal pickup_collected(message: String)

## The player tried a door that needs [param required_key] and lacks it.
@warning_ignore("unused_signal")
signal door_locked(required_key: int)

@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node)

@warning_ignore("unused_signal")
signal secret_found

## A Level 8 crystal obelisk was destroyed. The great demon listens.
@warning_ignore("unused_signal")
signal obelisk_destroyed

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

## Shakes the player's view; [param strength] 0..1 (explosions, roars).
@warning_ignore("unused_signal")
signal screen_shake_requested(strength: float)

## A short line in the HUD message area (game saved, secret found).
@warning_ignore("unused_signal")
signal hud_message_requested(text: String)

