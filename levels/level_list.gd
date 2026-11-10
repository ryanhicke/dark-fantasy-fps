class_name LevelList
extends Resource
## The ordered sequence of levels in a playthrough.
##
## Stores paths rather than PackedScenes so loading the list doesn't load
## every level into memory up front.

@export_file("*.tscn") var level_paths: Array[String] = []


func size() -> int:
	return level_paths.size()


func has_level(index: int) -> bool:
	return index >= 0 and index < level_paths.size()


## Returns "" for an index outside the list.
func get_level_path(index: int) -> String:
	if not has_level(index):
		return ""
	return level_paths[index]


func is_last(index: int) -> bool:
	return index == level_paths.size() - 1
