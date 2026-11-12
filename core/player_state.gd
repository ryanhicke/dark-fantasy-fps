class_name PlayerState
extends Resource
## The bundle of player state carried from one level to the next.
##
## A Resource so quicksave can serialize it later. Keys are deliberately not
## here: they are local to one level.
##
@export var health: float = 0.0
@export var ammo: Dictionary[StringName, int] = {}
## WeaponData.id of every weapon the player owns.
@export var owned_weapons: Array[StringName] = []


## Returns an independent copy, so a stored bundle can't be changed through
## a reference held somewhere else.
func copy() -> PlayerState:
	var result: PlayerState = PlayerState.new()
	result.health = health
	result.ammo = ammo.duplicate()
	result.owned_weapons = owned_weapons.duplicate()
	return result


## Plain values for the save file (no Objects allowed there).
func to_dict() -> Dictionary:
	return {"health": health, "ammo": ammo.duplicate(), "owned_weapons": owned_weapons.duplicate()}


## Missing or wrong-typed fields keep their defaults, so a damaged save
## can't crash the load.
static func from_dict(data: Dictionary) -> PlayerState:
	var result: PlayerState = PlayerState.new()
	var stored_health: Variant = data.get("health", 0.0)
	if stored_health is float or stored_health is int:
		result.health = float(stored_health)
	var stored_ammo: Variant = data.get("ammo", {})
	if stored_ammo is Dictionary:
		for ammo_type: Variant in stored_ammo:
			var amount: Variant = stored_ammo[ammo_type]
			if amount is int:
				result.ammo[StringName(str(ammo_type))] = amount
	var stored_weapons: Variant = data.get("owned_weapons", [])
	if stored_weapons is Array:
		for id: Variant in stored_weapons:
			result.owned_weapons.append(StringName(str(id)))
	return result

