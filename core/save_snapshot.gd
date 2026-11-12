class_name SaveSnapshot
extends RefCounted
## Quicksave file format and the "saveable" contract.
##
## A node joins SAVEABLE_GROUP and implements:
##   save_state() -> Dictionary   plain values only (no Objects)
##   load_state(state: Dictionary) -> void
## Its entry is keyed by its path inside the level, so the same map always
## gives the same keys (FuncGodot names entities by their order in the map).
##
## Files are written with store_var and read with objects disallowed, so a
## tampered save can never instance a script.

const SAVEABLE_GROUP: StringName = &"saveable"
## Bump when the layout changes incompatibly. Older files are refused.
const VERSION: int = 1
const KEY_VERSION: String = "version"
const KEY_GAME: String = "game"
const KEY_LEVEL: String = "level"
## File signature, checked before decoding so a stray file is rejected
## without engine errors.
const MAGIC: PackedByteArray = [0x44, 0x46, 0x51, 0x53, 0x41, 0x56, 0x45, 0x31]  # "DFQSAVE1"
## store_var writes a 4-byte length before the value.
const LENGTH_PREFIX_BYTES: int = 4


## Wraps the two halves of a save with the format version.
static func make(game: Dictionary, level: Dictionary) -> Dictionary:
	return {KEY_VERSION: VERSION, KEY_GAME: game, KEY_LEVEL: level}


static func write(path: String, snapshot: Dictionary) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(MAGIC)
	file.store_var(snapshot, false)
	return file.get_error()


## Returns {} when the file is missing, corrupt, or from another version.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < MAGIC.size() + LENGTH_PREFIX_BYTES:
		return {}
	if file.get_buffer(MAGIC.size()) != MAGIC:
		push_warning("SaveSnapshot: %s is not a save file." % path)
		return {}
	var start: int = file.get_position()
	if file.get_32() > file.get_length() - file.get_position():
		push_warning("SaveSnapshot: %s is truncated." % path)
		return {}
	file.seek(start)
	var data: Variant = file.get_var(false)
	if not data is Dictionary:
		push_warning("SaveSnapshot: %s is not a save file." % path)
		return {}
	var snapshot: Dictionary = data
	if snapshot.get(KEY_VERSION, -1) != VERSION:
		push_warning("SaveSnapshot: %s is from an incompatible version." % path)
		return {}
	if not snapshot.get(KEY_GAME) is Dictionary or not snapshot.get(KEY_LEVEL) is Dictionary:
		push_warning("SaveSnapshot: %s is incomplete." % path)
		return {}
	return snapshot


## State of every saveable node under [param root], keyed by relative path.
static func capture_nodes(root: Node) -> Dictionary:
	var nodes: Dictionary = {}
	for node: Node in root.get_tree().get_nodes_in_group(SAVEABLE_GROUP):
		if root.is_ancestor_of(node):
			nodes[String(root.get_path_to(node))] = node.call(&"save_state")
	return nodes


## Applies [param nodes] under [param root]. Entries whose node no longer
## exists (the map was edited since the save) are skipped. Returns how many
## were skipped, so the caller can warn.
static func apply_nodes(root: Node, nodes: Dictionary) -> int:
	var missing: int = 0
	for path: Variant in nodes:
		var node: Node = root.get_node_or_null(NodePath(str(path)))
		var state: Variant = nodes[path]
		if node == null or not node.has_method(&"load_state") or not state is Dictionary:
			missing += 1
			continue
		node.call(&"load_state", state)
	return missing


## Reads a Vector3 saved by store_var, or [param fallback] if it isn't one.
static func vec3(state: Dictionary, key: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	var value: Variant = state.get(key, fallback)
	return value if value is Vector3 else fallback
