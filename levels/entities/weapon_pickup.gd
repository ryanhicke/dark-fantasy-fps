class_name WeaponPickup
extends Pickup
## Gives [member weapon] (and its WeaponData.pickup_ammo). Already owning
## it still takes the pickup if the ammo is wanted.

@export var weapon: WeaponData


func _collect(player: Player) -> bool:
	if weapon == null:
		push_error("%s: no weapon assigned." % name)
		return false
	return player.give_weapon(weapon)


func _message() -> String:
	return "Picked up the %s" % weapon.display_name
