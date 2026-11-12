extends GutTest
## Which pooled player plays the next sound.


func test_idle_voices_are_used_in_order() -> void:
	var pool: VoicePool = VoicePool.new(3)
	assert_eq(pool.acquire(), 0)
	assert_eq(pool.acquire(), 1)
	assert_eq(pool.acquire(), 2)


func test_a_released_voice_is_reused_before_stealing() -> void:
	var pool: VoicePool = VoicePool.new(3)
	for i: int in 3:
		pool.acquire()
	pool.release(1)
	assert_false(pool.is_busy(1))
	assert_eq(pool.acquire(), 1)


func test_when_all_are_busy_the_oldest_is_stolen() -> void:
	var pool: VoicePool = VoicePool.new(3)
	for i: int in 3:
		pool.acquire()
	assert_eq(pool.acquire(), 0, "voice 0 started first")
	assert_eq(pool.acquire(), 1, "now voice 1 is the oldest")


func test_reacquiring_a_released_voice_makes_it_the_newest() -> void:
	var pool: VoicePool = VoicePool.new(2)
	pool.acquire()
	pool.acquire()
	pool.release(0)
	pool.acquire()
	assert_eq(pool.acquire(), 1, "voice 0 restarted after voice 1")


func test_empty_pool_returns_minus_one() -> void:
	assert_eq(VoicePool.new(0).acquire(), -1)


func test_release_ignores_out_of_range_indexes() -> void:
	var pool: VoicePool = VoicePool.new(1)
	pool.release(-1)
	pool.release(5)
	assert_eq(pool.size(), 1)
