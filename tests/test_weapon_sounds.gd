extends GutTest
## Which sound each weapon event plays. Sound slots are set on duplicates
## of the real data, never on the shared .tres resources.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const BOW_SCENE: PackedScene = preload("res://weapons/bow/bow.tscn")
const ARROW_SCENE: PackedScene = preload("res://weapons/arrow/arrow.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://spells/fireball/fireball_explosion.tscn")
const SWORD_DATA: WeaponData = preload("res://weapons/sword/sword.tres")
const SETTLE_FRAMES: int = 3
const TICK: float = 1.0 / 60.0

var _arena: Node3D
var _played: Array[AudioStream] = []


func before_each() -> void:
	_arena = Node3D.new()
	add_child_autofree(_arena)
	_played.clear()
	AudioManager.sound_played.connect(_on_sound_played)


func after_each() -> void:
	AudioManager.sound_played.disconnect(_on_sound_played)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sound_played(stream: AudioStream) -> void:
	_played.append(stream)


func _sound(label: String) -> AudioStream:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.resource_name = label
	return stream


## The player's sword, its data duplicated with test sounds.
func _sword_for(player: Player) -> MeleeWeapon:
	for child: Node in player.get_node("Head/Camera3D/WeaponHolder").get_children():
		var weapon: MeleeWeapon = child as MeleeWeapon
		if weapon != null and weapon.data == SWORD_DATA:
			weapon.data = SWORD_DATA.duplicate() as WeaponData
			weapon.data.attack_sound = _sound("swing")
			weapon.data.hit_sound = _sound("hit")
			weapon.data.wall_hit_sound = _sound("wall")
			weapon._is_drawn = true
			return weapon
	return null


## Swings and runs ticks until the windup has struck.
func _swing(sword: MeleeWeapon) -> void:
	sword.set_trigger(true)
	var ticks: int = ceili(sword.data.windup / TICK) + 2
	for i: int in ticks:
		sword._physics_process(TICK)
	sword.set_trigger(false)


func _make_wall(at: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 0.5)
	shape.shape = box
	body.add_child(shape)
	_arena.add_child(body)
	body.global_position = at


func test_swing_at_an_enemy_plays_swing_then_hit() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	_arena.add_child(player)
	var bandit: Enemy = BANDIT_SCENE.instantiate() as Enemy
	_arena.add_child(bandit)
	bandit.global_position = Vector3(0.0, 0.0, -1.2)
	await wait_physics_frames(SETTLE_FRAMES)
	var sword: MeleeWeapon = _sword_for(player)
	_swing(sword)
	assert_eq(_played, [sword.data.attack_sound, sword.data.hit_sound] as Array[AudioStream])


func test_swing_at_a_wall_plays_the_wall_hit() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	_arena.add_child(player)
	_make_wall(Vector3(0.0, 1.5, -1.2))
	await wait_physics_frames(SETTLE_FRAMES)
	var sword: MeleeWeapon = _sword_for(player)
	_swing(sword)
	assert_eq(_played, [sword.data.attack_sound, sword.data.wall_hit_sound] as Array[AudioStream])


func test_swing_at_nothing_plays_only_the_swing() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	_arena.add_child(player)
	await wait_physics_frames(SETTLE_FRAMES)
	var sword: MeleeWeapon = _sword_for(player)
	_swing(sword)
	assert_eq(_played, [sword.data.attack_sound] as Array[AudioStream])


func test_bow_plays_draw_then_release() -> void:
	var bow: RangedWeapon = BOW_SCENE.instantiate() as RangedWeapon
	bow.data = bow.data.duplicate() as WeaponData
	bow.data.charge_sound = _sound("draw")
	bow.data.attack_sound = _sound("release")
	bow.data.projectile_scene = null
	add_child_autofree(bow)
	bow._is_drawn = true
	bow.set_trigger(true)
	bow._physics_process(TICK)
	assert_eq(_played, [bow.data.charge_sound] as Array[AudioStream])
	bow.set_trigger(false)
	assert_eq(_played, [bow.data.charge_sound, bow.data.attack_sound] as Array[AudioStream])


func test_cancelled_draw_cuts_off_the_draw_sound() -> void:
	var bow: RangedWeapon = BOW_SCENE.instantiate() as RangedWeapon
	bow.data = bow.data.duplicate() as WeaponData
	bow.data.charge_sound = _sound("draw")
	add_child_autofree(bow)
	bow._is_drawn = true
	bow.set_trigger(true)
	bow._physics_process(TICK)
	var draw_player: AudioStreamPlayer = bow._charge_player
	assert_not_null(draw_player)
	bow.interrupt()
	assert_false(draw_player.playing)
	assert_null(bow._charge_player)


func test_projectile_plays_its_impact_where_it_hits() -> void:
	var arrow: Projectile = ARROW_SCENE.instantiate() as Projectile
	arrow.impact_sound = _sound("thud")
	_arena.add_child(arrow)
	arrow.launch(Vector3.ZERO, Vector3.FORWARD, 0.0, 1.0, Damage.Type.PIERCE, null)
	arrow._on_hit(null, Vector3(1.0, 2.0, 3.0))
	assert_eq(_played, [arrow.impact_sound] as Array[AudioStream])


func test_flight_sound_rides_with_the_projectile() -> void:
	var arrow: Projectile = ARROW_SCENE.instantiate() as Projectile
	arrow.flight_sound = _sound("whoosh")
	_arena.add_child(arrow)
	arrow.launch(Vector3.ZERO, Vector3.FORWARD, 0.0, 1.0, Damage.Type.PIERCE, null)
	var carried: AudioStreamPlayer3D = null
	for child: Node in arrow.get_children():
		if child is AudioStreamPlayer3D:
			carried = child as AudioStreamPlayer3D
	assert_not_null(carried)
	assert_eq(carried.stream, arrow.flight_sound)
	assert_eq(carried.bus, AudioBuses.SFX)


func test_projectile_without_flight_sound_adds_no_player() -> void:
	var arrow: Projectile = ARROW_SCENE.instantiate() as Projectile
	_arena.add_child(arrow)
	arrow.launch(Vector3.ZERO, Vector3.FORWARD, 0.0, 1.0, Damage.Type.PIERCE, null)
	for child: Node in arrow.get_children():
		assert_false(child is AudioStreamPlayer3D)


func test_explosion_plays_its_sound() -> void:
	var explosion: ExplosionEffect = EXPLOSION_SCENE.instantiate() as ExplosionEffect
	explosion.sound = _sound("boom")
	_arena.add_child(explosion)
	await wait_process_frames(1)
	assert_eq(_played, [explosion.sound] as Array[AudioStream])
