extends GutTest
## Quicksave file format, the saveable contract, and the player/progress
## halves of a save.

const PATH: String = "user://test_quicksave.sav"


class SaveableBox:
	extends Node
	var value: int = 0

	func save_state() -> Dictionary:
		return {"value": value}

	func load_state(state: Dictionary) -> void:
		value = int(state.get("value", 0))


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _tree_with_box(box_name: String, value: int) -> Node:
	var root: Node = Node.new()
	var holder: Node = Node.new()
	holder.name = "Holder"
	root.add_child(holder)
	var box: SaveableBox = SaveableBox.new()
	box.name = box_name
	box.value = value
	box.add_to_group(SaveSnapshot.SAVEABLE_GROUP)
	holder.add_child(box)
	add_child_autofree(root)
	return root


func test_write_then_read_round_trips() -> void:
	var snapshot: Dictionary = SaveSnapshot.make({"level_index": 3}, {"nodes": {"A": {"x": Vector3(1, 2, 3)}}})
	assert_eq(SaveSnapshot.write(PATH, snapshot), OK)
	var loaded: Dictionary = SaveSnapshot.read(PATH)
	assert_eq(loaded[SaveSnapshot.KEY_GAME]["level_index"], 3)
	assert_eq(loaded[SaveSnapshot.KEY_LEVEL]["nodes"]["A"]["x"], Vector3(1, 2, 3))


func test_missing_file_reads_empty() -> void:
	assert_true(SaveSnapshot.read("user://does_not_exist.sav").is_empty())


func test_other_version_is_refused() -> void:
	var snapshot: Dictionary = SaveSnapshot.make({}, {})
	snapshot[SaveSnapshot.KEY_VERSION] = SaveSnapshot.VERSION + 1
	SaveSnapshot.write(PATH, snapshot)
	assert_true(SaveSnapshot.read(PATH).is_empty())


func test_garbage_file_is_refused() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not a save at all")
	file.close()
	assert_true(SaveSnapshot.read(PATH).is_empty())


func test_nodes_round_trip_by_path() -> void:
	var source: Node = _tree_with_box("Box", 7)
	var nodes: Dictionary = SaveSnapshot.capture_nodes(source)
	assert_true(nodes.has("Holder/Box"))
	var target: Node = _tree_with_box("Box", 0)
	assert_eq(SaveSnapshot.apply_nodes(target, nodes), 0)
	assert_eq((target.get_node("Holder/Box") as SaveableBox).value, 7)


func test_missing_nodes_are_skipped_and_counted() -> void:
	var target: Node = _tree_with_box("Other", 1)
	var missing: int = SaveSnapshot.apply_nodes(target, {"Holder/Box": {"value": 9}})
	assert_eq(missing, 1)
	assert_eq((target.get_node("Holder/Other") as SaveableBox).value, 1)


func test_player_state_dict_round_trip() -> void:
	var state: PlayerState = PlayerState.new()
	state.health = 42.5
	state.ammo = {&"arrows": 12}
	state.owned_weapons = [&"sword", &"bow"]
	var restored: PlayerState = PlayerState.from_dict(state.to_dict())
	assert_eq(restored.health, 42.5)
	assert_eq(restored.ammo[&"arrows"], 12)
	assert_eq(restored.owned_weapons, [&"sword", &"bow"] as Array[StringName])


func test_player_state_ignores_bad_fields() -> void:
	var restored: PlayerState = PlayerState.from_dict({"health": "lots", "ammo": 5, "owned_weapons": "sword"})
	assert_eq(restored.health, 0.0)
	assert_true(restored.ammo.is_empty())
	assert_true(restored.owned_weapons.is_empty())


func test_level_stats_progress_round_trip() -> void:
	var stats: LevelStats = LevelStats.new()
	stats.kills = 4
	stats.secrets = 1
	stats.time_seconds = 61.5
	var restored: LevelStats = LevelStats.new()
	restored.load_dict(stats.to_dict())
	assert_eq(restored.kills, 4)
	assert_eq(restored.secrets, 1)
	assert_eq(restored.time_seconds, 61.5)


func test_key_ring_set_keys_drops_unknown() -> void:
	var ring: KeyRing = KeyRing.new()
	add_child_autofree(ring)
	ring.set_keys([2, 0, 99, -1, 0, "gold"])
	assert_eq(ring.get_keys(), [0, 2] as Array[int])
