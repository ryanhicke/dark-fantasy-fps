extends GutTest
## Levers open the doors they target (two-lever gates need both), named
## doors ignore the use key, and boss exits open only when a boss dies.

const LEVER_SCENE: PackedScene = preload("res://levels/entities/lever.tscn")
const DOOR_SCRIPT: GDScript = preload("res://levels/entities/door.gd")
const EXIT_SCRIPT: GDScript = preload("res://levels/entities/exit_trigger.gd")


func _make_door(props: Dictionary) -> Door:
	var door: Door = DOOR_SCRIPT.new() as Door
	door.func_godot_properties = props
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(4.0, 4.0, 1.0)
	mesh.mesh = box
	door.add_child(mesh)
	add_child_autofree(door)
	return door


func _make_lever(target: String, marked: bool = false) -> Lever:
	var lever: Lever = LEVER_SCENE.instantiate() as Lever
	lever.func_godot_properties = {"target": target, "marked": 1 if marked else 0}
	add_child_autofree(lever)
	return lever


func _make_exit(boss: bool) -> ExitTrigger:
	var exit: ExitTrigger = EXIT_SCRIPT.new() as ExitTrigger
	exit.func_godot_properties = {"boss": 1 if boss else 0}
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 2.0)
	shape.shape = box
	exit.add_child(shape)
	add_child_autofree(exit)
	return exit


func test_lever_opens_its_target_door() -> void:
	var door: Door = _make_door({"targetname": "gate", "wait": -1})
	_make_lever("gate").use(null)
	assert_eq(door.state, Door.State.OPENING)


func test_lever_ignores_other_doors() -> void:
	var door: Door = _make_door({"targetname": "other", "wait": -1})
	_make_lever("gate").use(null)
	assert_eq(door.state, Door.State.CLOSED)


func test_two_lever_gate_needs_both() -> void:
	var gate: Door = _make_door({"targetname": "gate", "count": 2, "wait": -1})
	var first: Lever = _make_lever("gate", true)
	var second: Lever = _make_lever("gate", true)
	first.use(null)
	assert_eq(gate.state, Door.State.CLOSED, "one lever is not enough")
	first.use(null)
	assert_eq(gate.state, Door.State.CLOSED, "pulling the same lever twice does not count")
	second.use(null)
	assert_eq(gate.state, Door.State.OPENING)


func test_named_door_ignores_the_use_key() -> void:
	var door: Door = _make_door({"targetname": "gate", "wait": -1})
	door.use(null)
	assert_eq(door.state, Door.State.CLOSED)


func test_unnamed_door_still_opens_with_use() -> void:
	var door: Door = _make_door({"wait": 3})
	door.use(null)
	assert_eq(door.state, Door.State.OPENING)


func test_lever_mark_shows_only_when_marked() -> void:
	assert_true(_make_lever("gate", true).get_node("Mark").visible)
	assert_false(_make_lever("trap", false).get_node("Mark").visible)


func test_plain_exit_starts_open() -> void:
	assert_true(_make_exit(false).is_open)


func test_boss_exit_waits_for_a_boss() -> void:
	var exit: ExitTrigger = _make_exit(true)
	assert_false(exit.is_open)
	var minion: Node = autofree(Node.new())
	EventBus.enemy_killed.emit(minion)
	assert_false(exit.is_open, "ordinary kills do not open it")
	var boss: Node = autofree(Node.new())
	boss.add_to_group(ExitTrigger.BOSS_GROUP)
	EventBus.enemy_killed.emit(boss)
	assert_true(exit.is_open)


func test_boss_scenes_are_in_the_boss_group() -> void:
	for path: String in ["res://enemies/necromancer/necromancer.tscn", "res://enemies/great_demon/great_demon.tscn"]:
		var state: SceneState = (load(path) as PackedScene).get_state()
		assert_true(state.get_node_groups(0).has(String(ExitTrigger.BOSS_GROUP)), path)
