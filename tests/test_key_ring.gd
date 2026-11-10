extends GutTest
## KeyRing contents and the door lock rule.

const GOLD: int = KeyRing.KeyType.GOLD
const SILVER: int = KeyRing.KeyType.SILVER
const BONE: int = KeyRing.KeyType.BONE

var _keys: KeyRing


func before_each() -> void:
	_keys = KeyRing.new()
	add_child_autofree(_keys)
	watch_signals(_keys)


func test_starts_empty() -> void:
	assert_false(_keys.has_key(GOLD))
	assert_eq(_keys.get_keys(), [] as Array[int])


func test_add_key_holds_it_and_signals() -> void:
	assert_true(_keys.add_key(GOLD))
	assert_true(_keys.has_key(GOLD))
	assert_false(_keys.has_key(SILVER))
	assert_signal_emitted_with_parameters(_keys, "keys_changed", [[GOLD] as Array[int]])


func test_adding_a_held_key_changes_nothing() -> void:
	_keys.add_key(GOLD)
	assert_false(_keys.add_key(GOLD))
	assert_eq(_keys.get_keys(), [GOLD] as Array[int])


func test_no_key_value_cannot_be_added() -> void:
	assert_false(_keys.add_key(KeyRing.NO_KEY))
	assert_eq(_keys.get_keys(), [] as Array[int])


func test_keys_are_reported_sorted() -> void:
	_keys.add_key(BONE)
	_keys.add_key(GOLD)
	assert_eq(_keys.get_keys(), [GOLD, BONE] as Array[int])


func test_get_keys_returns_a_copy() -> void:
	_keys.add_key(GOLD)
	var copy: Array[int] = _keys.get_keys()
	copy.append(SILVER)
	assert_false(_keys.has_key(SILVER))


func test_key_names_and_colors_cover_every_type() -> void:
	for key: int in KeyRing.KeyType.values():
		assert_ne(KeyRing.key_name(key), "Unknown")
	assert_eq(KeyRing.KEY_COLORS.size(), KeyRing.KeyType.size())
	assert_eq(KeyRing.key_name(99), "Unknown")


func test_find_on_returns_ring_or_null() -> void:
	var holder: Node = Node.new()
	add_child_autofree(holder)
	assert_null(KeyRing.find_on(holder))
	assert_null(KeyRing.find_on(null))
	var ring: KeyRing = KeyRing.new()
	ring.name = KeyRing.NODE_NAME
	holder.add_child(ring)
	assert_eq(KeyRing.find_on(holder), ring)


func test_unlocked_door_opens_for_anyone() -> void:
	assert_true(Door.is_unlocked_for(KeyRing.NO_KEY, null))
	assert_true(Door.is_unlocked_for(KeyRing.NO_KEY, _keys))


func test_locked_door_needs_the_matching_key() -> void:
	assert_false(Door.is_unlocked_for(GOLD, null), "no key ring at all")
	assert_false(Door.is_unlocked_for(GOLD, _keys), "empty ring")
	_keys.add_key(SILVER)
	assert_false(Door.is_unlocked_for(GOLD, _keys), "wrong key")
	_keys.add_key(GOLD)
	assert_true(Door.is_unlocked_for(GOLD, _keys))
