class_name KeyRing
extends Node
## Keys the player holds in the current level.
##
## Deliberately not part of the player state carried between levels: keys
## are local to one level, and every level spawns a fresh player.
##
## Add as a child named "KeyRing". Pickups and doors look it up by that name
## on the body that touched or used them, only at that moment.

signal keys_changed(keys: Array[int])

enum KeyType {
	GOLD,
	SILVER,
	BONE,
}

## Door value meaning "no key needed". Matches the "None" choice of
## func_door's key_type in levels/map_config/.
const NO_KEY: int = -1
const NODE_NAME: StringName = &"KeyRing"
const KEY_NAMES: Array[String] = ["Gold", "Silver", "Bone"]
const KEY_COLORS: Array[Color] = [
	Color(1.0, 0.8, 0.2),
	Color(0.75, 0.8, 0.9),
	Color(0.9, 0.87, 0.75),
]

var _keys: Array[int] = []


func _ready() -> void:
	# Announce the empty ring so the HUD clears keys from a previous life.
	_announce()


## Returns the KeyRing on [param target], or null if it can't carry keys.
static func find_on(target: Node) -> KeyRing:
	if target == null:
		return null
	return target.get_node_or_null(NodePath(NODE_NAME)) as KeyRing


static func key_name(key_type: int) -> String:
	if key_type < 0 or key_type >= KEY_NAMES.size():
		return "Unknown"
	return KEY_NAMES[key_type]


static func key_color(key_type: int) -> Color:
	if key_type < 0 or key_type >= KEY_COLORS.size():
		return Color.WHITE
	return KEY_COLORS[key_type]


func has_key(key_type: int) -> bool:
	return _keys.has(key_type)


## Returns false if the key was already held (nothing changes).
func add_key(key_type: int) -> bool:
	if key_type == NO_KEY or has_key(key_type):
		return false
	_keys.append(key_type)
	_keys.sort()
	_announce()
	return true


## Replaces every key at once (quickload). Unknown values are dropped.
func set_keys(keys: Array) -> void:
	_keys.clear()
	for key: Variant in keys:
		if key is int and key >= 0 and key < KEY_NAMES.size() and not _keys.has(key):
			_keys.append(key)
	_keys.sort()
	_announce()


func get_keys() -> Array[int]:
	return _keys.duplicate()


func _announce() -> void:
	keys_changed.emit(get_keys())
	EventBus.player_keys_changed.emit(get_keys())
