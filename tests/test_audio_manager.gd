extends GutTest
## AudioManager buses, pools, and music switching. Uses a fresh instance
## next to the autoload; buses are shared, and ensure_buses is idempotent.

const AudioManagerScript: GDScript = preload("res://core/audio_manager.gd")

var _audio: Node


func before_each() -> void:
	_audio = AudioManagerScript.new()
	add_child_autofree(_audio)


## A looping stream never emits finished, so busy voices stay busy and the
## tests don't depend on audio-thread timing.
func _looping_stream() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	var data: PackedByteArray = PackedByteArray()
	data.resize(256)
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 256
	return stream


func test_game_buses_exist_and_send_where_expected() -> void:
	for bus: StringName in AudioBuses.CREATED:
		var index: int = AudioServer.get_bus_index(bus)
		assert_gt(index, 0, "%s bus" % bus)
		assert_eq(AudioServer.get_bus_send(index), AudioBuses.SENDS[bus])


func test_ensure_buses_does_not_add_duplicates() -> void:
	var count: int = AudioServer.bus_count
	AudioManagerScript.ensure_buses()
	assert_eq(AudioServer.bus_count, count)


func test_sfx_plays_on_the_sfx_bus() -> void:
	var stream: AudioStream = _looping_stream()
	var player: AudioStreamPlayer = _audio.play_sfx(stream)
	assert_not_null(player)
	assert_eq(player.stream, stream)
	assert_eq(player.bus, AudioBuses.SFX)


func test_ui_sounds_use_the_ui_bus_without_pitch_change() -> void:
	var player: AudioStreamPlayer = _audio.play_ui(_looping_stream())
	assert_eq(player.bus, AudioBuses.UI)
	assert_eq(player.pitch_scale, 1.0)
	assert_eq(player.process_mode, Node.PROCESS_MODE_INHERIT, "inherits ALWAYS")


func test_pitch_variation_stays_in_range() -> void:
	for i: int in 20:
		var player: AudioStreamPlayer = _audio.play_sfx(_looping_stream(), 0.0, 0.1)
		assert_between(player.pitch_scale, 0.9, 1.1)


func test_positional_sound_is_placed_in_the_world() -> void:
	var at: Vector3 = Vector3(3.0, 1.0, -7.0)
	var player: AudioStreamPlayer3D = _audio.play_sfx_at(_looping_stream(), at)
	assert_eq(player.global_position, at)
	assert_eq(player.bus, AudioBuses.SFX)


func test_null_streams_play_nothing() -> void:
	assert_null(_audio.play_sfx(null))
	assert_null(_audio.play_ui(null))
	assert_null(_audio.play_sfx_at(null, Vector3.ZERO))


func test_a_full_pool_steals_the_oldest_player() -> void:
	var first: AudioStreamPlayer = _audio.play_sfx(_looping_stream())
	for i: int in AudioManagerScript.SFX_POOL_SIZE - 1:
		assert_ne(_audio.play_sfx(_looping_stream()), first)
	var newest: AudioStream = _looping_stream()
	assert_eq(_audio.play_sfx(newest), first)
	assert_eq(first.stream, newest)


func test_game_sounds_pause_with_the_game_but_music_does_not() -> void:
	var sfx: AudioStreamPlayer = _audio.play_sfx(_looping_stream())
	assert_eq(sfx.get_parent().process_mode, Node.PROCESS_MODE_PAUSABLE)
	assert_eq(_audio.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_music_switches_and_stops() -> void:
	var first: AudioStream = _looping_stream()
	var second: AudioStream = _looping_stream()
	_audio.play_music(first, 0.0)
	assert_eq(_audio.current_music(), first)
	_audio.play_music(second, 0.0)
	assert_eq(_audio.current_music(), second)
	_audio.stop_music(0.0)
	assert_null(_audio.current_music())


func test_asking_for_the_current_track_does_not_restart_it() -> void:
	var track: AudioStream = _looping_stream()
	_audio.play_music(track, 0.0)
	var player: AudioStreamPlayer = _audio._music_players[_audio._music_index]
	_audio.play_music(track, 0.0)
	assert_eq(_audio._music_players[_audio._music_index], player)
	assert_eq(player.stream, track)


func test_apply_volume_sets_the_bus_and_mutes_at_zero() -> void:
	var index: int = AudioServer.get_bus_index(AudioBuses.MUSIC)
	var before_db: float = AudioServer.get_bus_volume_db(index)
	var before_mute: bool = AudioServer.is_bus_mute(index)
	_audio.apply_volume(AudioBuses.MUSIC, 50)
	assert_almost_eq(AudioServer.get_bus_volume_db(index), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(index))
	_audio.apply_volume(AudioBuses.MUSIC, 0)
	assert_true(AudioServer.is_bus_mute(index))
	AudioServer.set_bus_volume_db(index, before_db)
	AudioServer.set_bus_mute(index, before_mute)


func test_percent_to_db() -> void:
	assert_eq(AudioBuses.percent_to_db(100), 0.0)
	assert_almost_eq(AudioBuses.percent_to_db(50), -6.02, 0.01)
	assert_eq(AudioBuses.percent_to_db(0), AudioBuses.SILENT_DB)
	assert_eq(AudioBuses.percent_to_db(150), 0.0, "clamped to 100%")
