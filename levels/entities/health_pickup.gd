class_name HealthPickup
extends Pickup
## Restores [member amount] health, capped at max. Left in place while the
## player is at full health, Doom-style, so it isn't wasted.

@export var amount: float = 10.0
## Shown on the HUD when collected.
@export var pickup_message: String = "Picked up a healing draught"


func _collect(player: Player) -> bool:
	return player.heal(amount)


func _message() -> String:
	return pickup_message
