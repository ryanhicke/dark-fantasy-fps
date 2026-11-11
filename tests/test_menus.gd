extends GutTest
## Menu selection wrapping and the graphics level labels.

const BASE_SIZE: Vector2 = Vector2(1280, 720)


func test_moving_down_from_the_last_item_wraps_to_the_first() -> void:
	assert_eq(MenuPage.wrap_index(2, 1, 3), 0)


func test_moving_up_from_the_first_item_wraps_to_the_last() -> void:
	assert_eq(MenuPage.wrap_index(0, -1, 3), 2)


func test_moving_within_the_list_does_not_wrap() -> void:
	assert_eq(MenuPage.wrap_index(0, 1, 3), 1)
	assert_eq(MenuPage.wrap_index(2, -1, 3), 1)


func test_empty_list_stays_at_zero() -> void:
	assert_eq(MenuPage.wrap_index(0, 1, 0), 0)


func test_graphics_labels_name_each_level_and_its_resolution() -> void:
	assert_eq(OptionsMenu.graphics_label(1, BASE_SIZE), "Graphics: High (1280x720)")
	assert_eq(OptionsMenu.graphics_label(2, BASE_SIZE), "Graphics: Medium (640x360)")
	assert_eq(OptionsMenu.graphics_label(3, BASE_SIZE), "Graphics: Low (426x240)")
	assert_eq(OptionsMenu.graphics_label(4, BASE_SIZE), "Graphics: Very Low (320x180)")


func test_every_pixel_size_has_a_name() -> void:
	for pixel_size: int in range(GameView.MIN_PIXEL_SIZE, GameView.MAX_PIXEL_SIZE + 1):
		assert_true(OptionsMenu.LEVEL_NAMES.has(pixel_size), "no name for %d" % pixel_size)


func test_base_size_matches_the_project_setting() -> void:
	assert_eq(OptionsMenu.base_size(), BASE_SIZE)


func test_hidden_buttons_are_skipped_until_refreshed() -> void:
	var page: MenuPage = MenuPage.new()
	var shown: Button = Button.new()
	var hidden: Button = Button.new()
	hidden.visible = false
	page.add_child(shown)
	page.add_child(hidden)
	add_child_autofree(page)
	assert_eq(page._buttons, [shown] as Array[Button])
	hidden.visible = true
	page.refresh_buttons()
	assert_eq(page._buttons, [shown, hidden] as Array[Button])


func test_dev_level_buttons_show_in_debug_builds() -> void:
	var menu: CanvasLayer = (load("res://ui/main_menu.tscn") as PackedScene).instantiate() as CanvasLayer
	add_child_autofree(menu)
	assert_eq((menu.get_node("MainPage/GalleryButton") as Button).visible, OS.is_debug_build())
	assert_eq((menu.get_node("MainPage/ArenaButton") as Button).visible, OS.is_debug_build())
	for path: String in [menu.get("enemy_gallery_path"), menu.get("great_demon_arena_path")]:
		assert_true(ResourceLoader.exists(path), path)
