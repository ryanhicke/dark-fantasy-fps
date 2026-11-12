extends GutTest
## Shared GameSounds for world objects, pickups, menus, and the HUD. Each
## test swaps AudioManager.sounds for a copy full of test streams, so the
## real core/game_sounds.tres is never touched.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const HEALTH_PICKUP: PackedScene = preload("res://levels/entities/health_small.tscn")
const KEY_PICKUP: PackedScene = preload("res://levels/entities/key_pickup.tscn")
const LEVER_SCENE: PackedScene = preload("res://levels/entities/lever.tscn")
const OBELISK_SCENE: PackedScene = preload("res://levels/entities/crystal_obelisk.tscn")
const DOOR_SCRIPT: GDScript = preload("res://levels/entities/door.gd")
const EXIT_SCRIPT: GDScript = preload("res://levels/entities/exit_trigger.gd")

var _real_sounds: GameSounds
var _sounds: GameSounds
var _played: Array[AudioStream] = []


func before_each() -> void:
	_real_sounds = AudioManager.sounds
	_sounds = GameSounds.new()
	for property: Dictionary in _sounds.get_property_list():
		if property["type"] == TYPE_OBJECT and property["hint_string"] == "AudioStream":
			var stream: AudioStreamWAV = AudioStreamWAV.new()
			stream.resource_name = property["name"]
			_sounds.set(property["name"], stream)
	AudioManager.sounds = _sounds
	_played.clear()
	AudioManager.sound_played.connect(_on_sound_played)


func after_each() -> void:
	AudioManager.sound_played.disconnect(_on_sound_played)
	AudioManager.sounds = _real_sounds
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sound_played(stream: AudioStream) -> void:
	_played.append(stream)


func _hurt_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	HealthComponent.find_on(player).set_health(50.0)
	return player


## [param at] is set before the door enters the tree: an AnimatableBody3D
## only takes a moved transform on its next physics step.
func _make_door(props: Dictionary, at: Vector3 = Vector3.ZERO) -> Door:
	var door: Door = DOOR_SCRIPT.new() as Door
	door.func_godot_properties = props
	door.position = at
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(4.0, 4.0, 1.0)
	mesh.mesh = box
	door.add_child(mesh)
	add_child_autofree(door)
	return door


func test_the_shared_sound_file_loads() -> void:
	assert_not_null(_real_sounds)


func test_pickup_plays_its_kinds_shared_sound() -> void:
	var player: Player = _hurt_player()
	var pickup: HealthPickup = HEALTH_PICKUP.instantiate() as HealthPickup
	add_child_autofree(pickup)
	pickup._on_body_entered(player)
	assert_eq(_played, [_sounds.health_pickup] as Array[AudioStream])


func test_pickup_sound_override_wins() -> void:
	var player: Player = _hurt_player()
	var pickup: HealthPickup = HEALTH_PICKUP.instantiate() as HealthPickup
	pickup.pickup_sound = AudioStreamWAV.new()
	add_child_autofree(pickup)
	pickup._on_body_entered(player)
	assert_eq(_played, [pickup.pickup_sound] as Array[AudioStream])


func test_pickup_left_in_place_is_silent() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	var pickup: HealthPickup = HEALTH_PICKUP.instantiate() as HealthPickup
	add_child_autofree(pickup)
	pickup._on_body_entered(player)
	assert_eq(_played, [] as Array[AudioStream], "full health: not collected")


func test_key_pickup_plays_the_key_sound() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	var key: KeyPickup = KEY_PICKUP.instantiate() as KeyPickup
	add_child_autofree(key)
	key._on_body_entered(player)
	assert_eq(_played, [_sounds.key_pickup] as Array[AudioStream])


func test_door_plays_open_then_close() -> void:
	var door: Door = _make_door({"wait": 0.1})
	door.use(null)
	assert_eq(_played, [_sounds.door_open] as Array[AudioStream])
	door._set_state(Door.State.CLOSING)
	assert_eq(_played, [_sounds.door_open, _sounds.door_close] as Array[AudioStream])


func test_locked_door_plays_the_locked_sound() -> void:
	var door: Door = _make_door({"key_type": KeyRing.KeyType.GOLD})
	door.use(null)
	assert_eq(_played, [_sounds.door_locked] as Array[AudioStream])
	assert_eq(door.state, Door.State.CLOSED)


func test_door_sound_comes_from_the_middle_of_the_brush() -> void:
	var door: Door = _make_door({}, Vector3(10.0, 0.0, 0.0))
	var player: AudioStreamPlayer3D = null
	door.use(null)
	# The pooled player that took the open sound sits at the door's center.
	for child: Node in AudioManager.get_node("GameSounds").get_children():
		var positional: AudioStreamPlayer3D = child as AudioStreamPlayer3D
		if positional != null and positional.stream == _sounds.door_open:
			player = positional
	assert_not_null(player)
	assert_eq(player.global_position, Vector3(10.0, 0.0, 0.0))


func test_lever_plays_the_pull_sound_once() -> void:
	var lever: Lever = LEVER_SCENE.instantiate() as Lever
	add_child_autofree(lever)
	lever.use(null)
	lever.use(null)
	assert_eq(_played, [_sounds.lever_pull] as Array[AudioStream])


func test_boss_exit_opening_plays_the_portal_sound() -> void:
	var exit: ExitTrigger = EXIT_SCRIPT.new() as ExitTrigger
	exit.func_godot_properties = {"boss": 1}
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 2.0)
	shape.shape = box
	exit.add_child(shape)
	add_child_autofree(exit)
	exit.open()
	assert_eq(_played, [_sounds.portal_open] as Array[AudioStream])


func test_obelisk_clinks_at_the_wrong_weapon_and_shatters_at_the_right_one() -> void:
	var obelisk: CrystalObelisk = OBELISK_SCENE.instantiate() as CrystalObelisk
	obelisk.weak_to = Damage.Type.BLUNT
	add_child_autofree(obelisk)
	var health: HealthComponent = HealthComponent.find_on(obelisk)
	health.take_damage(50.0, Damage.Type.SLASH, null)
	assert_eq(_played, [_sounds.obelisk_clink] as Array[AudioStream])
	health.take_damage(100000.0, Damage.Type.BLUNT, null)
	assert_eq(_played.back(), _sounds.obelisk_shatter)


func test_immune_hit_is_reported_but_not_on_the_dead() -> void:
	var health: HealthComponent = HealthComponent.new()
	health.resistances = CrystalObelisk.resistances_for(Damage.Type.FIRE)
	add_child_autofree(health)
	watch_signals(health)
	health.take_damage(10.0, Damage.Type.SLASH, null)
	assert_signal_emit_count(health, "immune_hit", 1)
	assert_signal_not_emitted(health, "damaged")
	health.take_damage(100000.0, Damage.Type.FIRE, null)
	health.take_damage(10.0, Damage.Type.SLASH, null)
	assert_signal_emit_count(health, "immune_hit", 1, "dead: no more clinks")


func test_menu_move_select_and_back() -> void:
	var page: MenuPage = MenuPage.new()
	var ok: Button = Button.new()
	var back: Button = Button.new()
	page.add_child(ok)
	page.add_child(back)
	add_child_autofree(page)
	page.back_button = back
	page.focus_first()
	page.move_focus(1)
	ok.pressed.emit()
	back.pressed.emit()
	assert_eq(
		_played,
		[_sounds.menu_move, _sounds.menu_select, _sounds.menu_back] as Array[AudioStream]
	)


func test_options_back_row_plays_the_back_sound() -> void:
	var page: OptionsMenu = (load("res://ui/options_menu.tscn") as PackedScene).instantiate() as OptionsMenu
	add_child_autofree(page)
	(page.get_node("BackButton") as Button).pressed.emit()
	assert_eq(_played, [_sounds.menu_back] as Array[AudioStream])


func test_armor_fading_plays_its_warning() -> void:
	var hud: Node = (load("res://ui/hud.tscn") as PackedScene).instantiate()
	add_child_autofree(hud)
	EventBus.player_invulnerability_ending.emit()
	assert_eq(_played, [_sounds.armor_fading] as Array[AudioStream])
