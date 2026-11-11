extends GutTest
## Crystal obelisks (docs/enemies.md, Level 8): one weapon each, and
## breaking one tells the great demon.

const OBELISK_SCENE: PackedScene = preload("res://levels/entities/crystal_obelisk.tscn")
const ALL_TYPES: Array[Damage.Type] = [
	Damage.Type.SLASH, Damage.Type.PIERCE, Damage.Type.BLUNT, Damage.Type.FIRE,
	Damage.Type.LIGHTNING, Damage.Type.MAGIC, Damage.Type.THROWN,
]
## The four weapons the doc assigns to obelisks, by damage type.
const OBELISK_WEAPONS: Dictionary[Damage.Type, String] = {
	Damage.Type.BLUNT: "res://weapons/warhammer/warhammer.tres",
	Damage.Type.FIRE: "res://spells/fireball/fireball.tres",
	Damage.Type.THROWN: "res://weapons/francisca/francisca.tres",
	Damage.Type.MAGIC: "res://spells/magic_missile/magic_missile.tres",
}
const SETTLE_FRAMES: int = 2


func _obelisk(weak_to: Damage.Type) -> CrystalObelisk:
	var obelisk: CrystalObelisk = OBELISK_SCENE.instantiate() as CrystalObelisk
	obelisk.weak_to = weak_to
	add_child_autofree(obelisk)
	return obelisk


func test_each_obelisk_weapon_has_its_own_damage_type() -> void:
	for type: Damage.Type in OBELISK_WEAPONS:
		var weapon: WeaponData = load(OBELISK_WEAPONS[type]) as WeaponData
		assert_eq(weapon.damage_type, type, weapon.display_name)
	var sword: WeaponData = load("res://weapons/sword/sword.tres") as WeaponData
	assert_false(OBELISK_WEAPONS.has(sword.damage_type), "the sword breaks no obelisk")


func test_only_its_weapon_hurts_it() -> void:
	for weak: Damage.Type in OBELISK_WEAPONS:
		var resistances: DamageResistances = CrystalObelisk.resistances_for(weak)
		for type: Damage.Type in ALL_TYPES:
			var expected: float = 1.0 if type == weak else 0.0
			assert_eq(resistances.multiplier_for(type), expected, "%s vs %s" % [weak, type])


func test_wrong_weapon_does_nothing_right_weapon_breaks_it() -> void:
	var obelisk: CrystalObelisk = _obelisk(Damage.Type.BLUNT)
	var health: HealthComponent = HealthComponent.find_on(obelisk)
	health.take_damage(500.0, Damage.Type.SLASH, null)
	health.take_damage(500.0, Damage.Type.FIRE, null)
	assert_eq(health.current_health, health.max_health)
	watch_signals(EventBus)
	health.take_damage(500.0, Damage.Type.BLUNT, null)
	assert_true(health.is_dead())
	assert_signal_emit_count(EventBus, "obelisk_destroyed", 1)


func test_magic_missile_can_lock_onto_it() -> void:
	var obelisk: CrystalObelisk = _obelisk(Damage.Type.MAGIC)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_true(obelisk.is_in_group(HomingProjectile.TARGET_GROUP))
	assert_true(obelisk.can_be_targeted())
	HealthComponent.find_on(obelisk).take_damage(500.0, Damage.Type.MAGIC, null)
	assert_false(obelisk.can_be_targeted(), "broken ones aren't targets")


func test_arena_has_one_obelisk_per_weapon() -> void:
	var arena: Node = (load("res://levels/great_demon_arena.tscn") as PackedScene).instantiate()
	var found: Array[Damage.Type] = []
	for child: Node in arena.get_node("Obelisks").get_children():
		found.append((child as CrystalObelisk).weak_to)
	arena.free()
	found.sort()
	var expected: Array[Damage.Type] = []
	expected.assign(OBELISK_WEAPONS.keys())
	expected.sort()
	assert_eq(found, expected)
