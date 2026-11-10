extends GutTest
## GameView pixel size -> render resolution math and the F2 cycle order.

const BASE_SIZE: Vector2 = Vector2(1280, 720)


func test_render_size_divides_by_pixel_size() -> void:
	assert_eq(GameView.render_size_for(BASE_SIZE, 1), Vector2i(1280, 720))
	assert_eq(GameView.render_size_for(BASE_SIZE, 2), Vector2i(640, 360))
	assert_eq(GameView.render_size_for(BASE_SIZE, 3), Vector2i(426, 240))
	assert_eq(GameView.render_size_for(BASE_SIZE, 4), Vector2i(320, 180))


func test_render_size_never_hits_zero() -> void:
	assert_eq(GameView.render_size_for(Vector2(1, 1), 4), Vector2i(1, 1))
	assert_eq(GameView.render_size_for(BASE_SIZE, 0), Vector2i(1280, 720))


func test_cycle_wraps_after_the_largest_pixel_size() -> void:
	assert_eq(GameView.next_pixel_size(1), 2)
	assert_eq(GameView.next_pixel_size(3), 4)
	assert_eq(GameView.next_pixel_size(GameView.MAX_PIXEL_SIZE), GameView.MIN_PIXEL_SIZE)
