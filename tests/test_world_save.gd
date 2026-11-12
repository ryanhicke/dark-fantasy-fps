extends GutTest
## Doors, levers, pickups, keys, secrets, and boss exits survive a
## quicksave round trip, and taken pickups stay taken.

const LEVER_SCENE: PackedScene = preload("res://levels/entities/lever.tscn")
const HEALTH_SCENE: PackedScene = preload("res://levels/entities/health_small.tscn")
const KEY_SCENE: PackedScene = preload("res://levels/entities/key_pickup.tscn")
const DOOR_SCRIPT: GDScript = preload("res://levels/entities/door.gd")
const EXIT_SCRIPT: GDScript = preload("res://levels/entities/exit_trigger.gd")
const SECRET_SCRIPT: GDScript = preload("res://levels/entities/secret_trigger.gd")


func _make_door(root: Node) -> Door:
	var door: Door = DOOR_SCRIPT.new() as Door
	door.name = "Door"
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(4.0, 4.0, 1.0)
	mesh.mesh = box
	door.add_child(mesh)
	root.add_child(door)
	return door


func _make_exit(root: Node) -> ExitTrigger:
	var exit: ExitTrigger = EXIT_SCRIPT.new() as ExitTrigger
	exit.name = "Exit"
	exit.func_godot_properties = {"boss": 1}
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 2.0)
	shape.shape = box
	exit.add_child(shape)
	root.add_child(exit)
	return exit


## A level-like root holding one of each entity, named so paths match.
func _make_world() -> Node3D:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	_make_door(root)
	var lever: Node = LEVER_SCENE.instantiate()
	lever.name = "Lever"
	root.add_child(lever)
	var potion: Node = HEALTH_SCENE.instantiate()
	potion.name = "Potion"
	root.add_child(potion)
	var key: Node = KEY_SCENE.instantiate()
	key.name = "Key"
	root.add_child(key)
	var secret: Node = SECRET_SCRIPT.new()
	secret.name = "Secret"
	root.add_child(secret)
	_make_exit(root)
	return root


func test_door_position_and_state_come_back() -> void:
	var before: Node3D = _make_world()
	var door: Door = before.get_node("Door") as Door
	door.trigger()
	door.position.y += 1.5
	var nodes: Dictionary = SaveSnapshot.capture_nodes(before)
	var after: Node3D = _make_world()
	SaveSnapshot.apply_nodes(after, nodes)
	var loaded: Door = after.get_node("Door") as Door
	assert_eq(loaded.state, Door.State.OPENING)
	assert_almost_eq(loaded.position.y, door.position.y, 0.001)
	assert_true(loaded.is_physics_processing())


func test_pulled_lever_stays_pulled() -> void:
	var before: Node3D = _make_world()
	(before.get_node("Lever") as Lever).use(null)
	var after: Node3D = _make_world()
	SaveSnapshot.apply_nodes(after, SaveSnapshot.capture_nodes(before))
	assert_true((after.get_node("Lever") as Lever).is_pulled)


func test_taken_pickups_and_keys_are_removed_on_load() -> void:
	var before: Node3D = _make_world()
	before.get_node("Potion").free()
	before.get_node("Key").free()
	var after: Node3D = _make_world()
	SaveSnapshot.apply_nodes(after, SaveSnapshot.capture_nodes(before))
	await wait_process_frames(1)
	assert_null(after.get_node_or_null("Potion"))
	assert_null(after.get_node_or_null("Key"))
	assert_not_null(after.get_node_or_null("Door"), "other things stay")


func test_untaken_pickups_stay() -> void:
	var before: Node3D = _make_world()
	var after: Node3D = _make_world()
	SaveSnapshot.apply_nodes(after, SaveSnapshot.capture_nodes(before))
	await wait_process_frames(1)
	assert_not_null(after.get_node_or_null("Potion"))
	assert_not_null(after.get_node_or_null("Key"))


func test_found_secret_and_open_boss_exit_come_back() -> void:
	var before: Node3D = _make_world()
	(before.get_node("Secret") as SecretTrigger).is_found = true
	(before.get_node("Exit") as ExitTrigger).open(true)
	var after: Node3D = _make_world()
	SaveSnapshot.apply_nodes(after, SaveSnapshot.capture_nodes(before))
	assert_true((after.get_node("Secret") as SecretTrigger).is_found)
	assert_true((after.get_node("Exit") as ExitTrigger).is_open)
