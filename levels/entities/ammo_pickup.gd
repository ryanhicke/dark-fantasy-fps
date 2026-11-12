class_name AmmoPickup
extends Pickup
## Gives [member amount] of [member ammo_type]. Left in place while full.

@export var ammo_type: StringName = &"arrows"
@export var amount: int = 10
## Shown on the HUD when collected.
@export var pickup_message: String = "Picked up some arrows"


func _collect(player: Player) -> bool:
	return player.give_ammo(ammo_type, amount) > 0


func _message() -> String:
	return pickup_message


func _default_sound() -> AudioStream:
	return AudioManager.sounds.ammo_pickup
