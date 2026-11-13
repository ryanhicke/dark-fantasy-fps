extends GutTest
## The HUD status strip: health and mana bars, the ammo panel, and key icons,
## driven through EventBus on the real HUD scene.

const HUD_SCENE: PackedScene = preload("res://ui/hud.tscn")
const BOW: WeaponData = preload("res://weapons/bow/bow.tres")
const SWORD: WeaponData = preload("res://weapons/sword/sword.tres")
const FIREBALL: WeaponData = preload("res://spells/fireball/fireball.tres")

var _status: HudStatus


func before_each() -> void:
	var hud: Node = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	_status = hud.get_node("Status") as HudStatus


func _bar(path: String) -> ProgressBar:
	return _status.get_node(path) as ProgressBar


func _label(path: String) -> Label:
	return _status.get_node(path) as Label


func test_health_fills_the_bar_and_rounds_the_number_up() -> void:
	EventBus.player_health_changed.emit(40.2, 100.0)
	assert_eq(_bar("Vitals/Row/HealthBar").max_value, 100.0)
	assert_almost_eq(_bar("Vitals/Row/HealthBar").value, 40.2, 0.001)
	assert_eq(_label("Vitals/Row/HealthValue").text, "41")


func test_health_number_turns_amber_then_red() -> void:
	assert_eq(_status.health_color(100.0, 100.0), _status.health_normal_color)
	assert_eq(_status.health_color(50.0, 100.0), _status.health_warning_color)
	assert_eq(_status.health_color(25.0, 100.0), _status.health_danger_color)
	assert_eq(_status.health_color(10.0, 0.0), _status.health_danger_color)


func test_mana_has_its_own_bar_whatever_weapon_is_held() -> void:
	EventBus.player_weapon_changed.emit(SWORD)
	EventBus.player_ammo_changed.emit(&"mana", 35, 100)
	assert_eq(_bar("Vitals/Row/ManaBar").value, 35.0)
	assert_eq(_label("Vitals/Row/ManaValue").text, "35")


func test_ammo_panel_shows_the_held_weapons_count_and_icon() -> void:
	EventBus.player_ammo_changed.emit(&"arrows", 17, 100)
	EventBus.player_weapon_changed.emit(BOW)
	assert_true(_status.get_node("Ammo").visible)
	assert_eq(_label("Ammo/Row/AmmoValue").text, "17")
	var icon: TextureRect = _status.get_node("Ammo/Row/AmmoIcon") as TextureRect
	assert_eq(icon.texture, _status.ammo_icons[&"arrows"])
	EventBus.player_ammo_changed.emit(&"arrows", 16, 100)
	assert_eq(_label("Ammo/Row/AmmoValue").text, "16")


func test_ammo_panel_hides_for_melee_and_spells() -> void:
	EventBus.player_weapon_changed.emit(BOW)
	EventBus.player_weapon_changed.emit(SWORD)
	assert_false(_status.get_node("Ammo").visible)
	EventBus.player_weapon_changed.emit(BOW)
	EventBus.player_weapon_changed.emit(FIREBALL)
	assert_false(_status.get_node("Ammo").visible)
	EventBus.player_weapon_changed.emit(null)
	assert_false(_status.get_node("Ammo").visible)


func test_every_non_mana_ammo_type_has_an_icon() -> void:
	var inventory: Inventory = autofree(Inventory.new())
	for ammo_type: StringName in inventory.max_ammo:
		if ammo_type != HudStatus.MANA:
			assert_not_null(_status.ammo_icons.get(ammo_type), String(ammo_type))


func test_key_icons_show_only_the_keys_held() -> void:
	var held: Array[int] = [KeyRing.KeyType.GOLD, KeyRing.KeyType.BONE]
	EventBus.player_keys_changed.emit(held)
	assert_true(_status.get_node("Keys/KeyGold").visible)
	assert_false(_status.get_node("Keys/KeySilver").visible)
	assert_true(_status.get_node("Keys/KeyBone").visible)
	var none: Array[int] = []
	EventBus.player_keys_changed.emit(none)
	assert_false(_status.get_node("Keys/KeyGold").visible)
	assert_false(_status.get_node("Keys/KeyBone").visible)
