extends GutTest
## LevelList lookups and the shipped level list file.

const LEVEL_A: String = "res://levels/a.tscn"
const LEVEL_B: String = "res://levels/b.tscn"

var _list: LevelList


func before_each() -> void:
	_list = LevelList.new()
	_list.level_paths = [LEVEL_A, LEVEL_B] as Array[String]


func test_lookup_by_index() -> void:
	assert_eq(_list.size(), 2)
	assert_eq(_list.get_level_path(0), LEVEL_A)
	assert_eq(_list.get_level_path(1), LEVEL_B)


func test_out_of_range_index_returns_empty() -> void:
	assert_false(_list.has_level(-1))
	assert_false(_list.has_level(2))
	assert_eq(_list.get_level_path(2), "")


func test_only_the_last_index_is_last() -> void:
	assert_false(_list.is_last(0))
	assert_true(_list.is_last(1))


func test_shipped_list_points_at_real_scenes() -> void:
	var shipped: LevelList = load("res://levels/level_list.tres") as LevelList
	assert_not_null(shipped)
	assert_gt(shipped.size(), 0)
	for path: String in shipped.level_paths:
		assert_true(ResourceLoader.exists(path), "missing level: %s" % path)
