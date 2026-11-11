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
