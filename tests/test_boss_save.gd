extends GutTest
## The great demon's stage, its summoners, and their summoned enemies, and
## destroyed obelisks, survive a quicksave round trip.

const DEMON_SCENE: PackedScene = preload("res://enemies/great_demon/great_demon.tscn")
const OBELISK_SCENE: PackedScene = preload("res://levels/entities/crystal_obelisk.tscn")
const FINAL_DATA: String = "res://enemies/great_demon/great_demon_final.tres"
const SETTLE_FRAMES: int = 3


func _make_arena() -> Node3D:
	var arena: Node3D = Node3D.new()
	add_child_autofree(arena)
	var demon: Enemy = DEMON_SCENE.instantiate() as Enemy
	demon.name = "GreatDemon"
	arena.add_child(demon)
	var obelisk: Node3D = OBELISK_SCENE.instantiate() as Node3D
	obelisk.name = "Obelisk"
	obelisk.position = Vector3(20.0, 0.0, 0.0)
	arena.add_child(obelisk)
	return arena


func _phases(arena: Node3D) -> GreatDemonPhases:
	return arena.get_node("GreatDemon/Phases") as GreatDemonPhases


func _round_trip(before: Node3D) -> Node3D:
	var nodes: Dictionary = SaveSnapshot.capture_nodes(before)
	var after: Node3D = _make_arena()
	await wait_physics_frames(SETTLE_FRAMES)
	assert_eq(SaveSnapshot.apply_nodes(after, nodes), 0, "every saved node found")
	return after


func test_stage_cracks_and_summons_come_back() -> void:
	var before: Node3D = _make_arena()
	await wait_physics_frames(SETTLE_FRAMES)
	(before.get_node("GreatDemon") as Enemy).wake()
	_phases(before).on_obelisk_destroyed()
	_phases(before).on_obelisk_destroyed()
	# Summoners run in _process.
	await wait_process_frames(SETTLE_FRAMES)
	var werewolves_before: EnemySummoner = before.get_node("GreatDemon/WerewolfSummoner") as EnemySummoner
	var alive_before: int = werewolves_before.alive_count()
	assert_gt(alive_before, 0, "a wave was summoned")

	var after: Node3D = await _round_trip(before)
	assert_eq(_phases(after).obelisks_destroyed, 2)
	assert_true((after.get_node("GreatDemon/Sprite/Crack2") as Node3D).visible)
	assert_false((after.get_node("GreatDemon/Sprite/Crack3") as Node3D).visible)
	var werewolves_after: EnemySummoner = after.get_node("GreatDemon/WerewolfSummoner") as EnemySummoner
	assert_true(werewolves_after.is_active())
	assert_eq(werewolves_after.alive_count(), alive_before)


func test_final_phase_comes_back_vulnerable() -> void:
	var before: Node3D = _make_arena()
	await wait_physics_frames(SETTLE_FRAMES)
	for i: int in 4:
		_phases(before).on_obelisk_destroyed()
	var after: Node3D = await _round_trip(before)
	var demon: Enemy = after.get_node("GreatDemon") as Enemy
	assert_eq(demon.data.resource_path, FINAL_DATA)
	assert_true(_phases(after).is_final_phase())
	for summoner: String in ["DemonSummoner", "ImpSummoner", "WerewolfSummoner"]:
		assert_false((demon.get_node(summoner) as EnemySummoner).is_active())


func test_destroyed_obelisk_stays_destroyed_silently() -> void:
	var before: Node3D = _make_arena()
	await wait_physics_frames(SETTLE_FRAMES)
	HealthComponent.find_on(before.get_node("Obelisk")).take_damage(9999.0, Damage.Type.BLUNT, null)
	watch_signals(EventBus)
	var after: Node3D = await _round_trip(before)
	assert_false((after.get_node("Obelisk") as CrystalObelisk).can_be_targeted())
	assert_signal_not_emitted(EventBus, "obelisk_destroyed")
