extends Node
## Music and SFX playback through pooled players, plus the audio buses.
##
## Every player is created once at startup and reused, so playing a sound
## never adds nodes (CLAUDE.md rules 6 and 7). One-shot sounds go through
## these pools rather than a player on the node that made them, because a
## projectile or pickup is often freed while its sound is still playing.
##
## The Music, SFX, and UI buses are added in code if missing, so there is no
## bus layout file to keep in sync. Buses that already exist (say, from a
## default_bus_layout.tres) are left as they are.
##
## Runs with process_mode ALWAYS so music and menu sounds carry on while the
## tree is paused (intermission). Game sounds sit under a PAUSABLE node and
## pause with the game.
##
## No class_name: the autoload name (AudioManager) is the global identifier.

## Emitted for every sound started through a pool. Lets tests (and any
## future debug readout) see what played without polling the players.
signal sound_played(stream: AudioStream)

## Non-positional game sounds (the player's own weapon, pickups).
const SFX_POOL_SIZE: int = 8
const UI_POOL_SIZE: int = 4
## Sounds placed in the world (impacts, explosions, doors).
const POSITIONAL_POOL_SIZE: int = 16
## Random pitch range (+/-) so repeated sounds don't sound identical.
const DEFAULT_PITCH_VARIATION: float = 0.05
const MUSIC_FADE_TIME: float = 1.0
## Positional sounds are culled beyond this distance (meters).
const POSITIONAL_MAX_DISTANCE: float = 50.0

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool: VoicePool = VoicePool.new(SFX_POOL_SIZE)
var _ui_players: Array[AudioStreamPlayer] = []
var _ui_pool: VoicePool = VoicePool.new(UI_POOL_SIZE)
var _positional_players: Array[AudioStreamPlayer3D] = []
var _positional_pool: VoicePool = VoicePool.new(POSITIONAL_POOL_SIZE)

## Two players so one track can fade out while the next fades in.
var _music_players: Array[AudioStreamPlayer] = []
var _music_tweens: Array[Tween] = [null, null]
var _music_index: int = 0
## The track asked for last (null when stopped), even while it fades in.
var _music_stream: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	_create_players()
	Settings.volume_changed.connect(apply_volume)
	# Deferred: Settings is a later autoload and hasn't loaded its file yet.
	_apply_saved_volumes.call_deferred()


## Plays a non-positional game sound. Returns the player, which is reused
## for later sounds, so only touch it right away (e.g. to stop a loop).
func play_sfx(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch_variation: float = DEFAULT_PITCH_VARIATION
) -> AudioStreamPlayer:
	return _play_flat(_sfx_players, _sfx_pool, stream, volume_db, pitch_variation)


## Plays a menu or HUD sound. Not pitch-varied, and not paused with the game.
func play_ui(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	return _play_flat(_ui_players, _ui_pool, stream, volume_db, 0.0)


## Plays a sound at a world position. Same reuse caveat as play_sfx.
func play_sfx_at(
	stream: AudioStream,
	position: Vector3,
	volume_db: float = 0.0,
	pitch_variation: float = DEFAULT_PITCH_VARIATION
) -> AudioStreamPlayer3D:
	if stream == null:
		return null
	var index: int = _positional_pool.acquire()
	var player: AudioStreamPlayer3D = _positional_players[index]
	player.stop()
	player.global_position = position
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = _random_pitch(pitch_variation)
	player.play()
	sound_played.emit(stream)
	return player


## Fades to [param stream], or out to silence when it is null. Asking for the
## track that is already playing does nothing, so it carries on unbroken
## across a level restart.
func play_music(stream: AudioStream, fade_time: float = MUSIC_FADE_TIME) -> void:
	if stream == _music_stream:
		return
	_music_stream = stream
	_fade_out(_music_index, fade_time)
	if stream == null:
		return
	_music_index = 1 - _music_index
	var player: AudioStreamPlayer = _music_players[_music_index]
	_kill_music_tween(_music_index)
	player.stream = stream
	player.volume_linear = 0.0 if fade_time > 0.0 else 1.0
	player.play()
	if fade_time > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(player, ^"volume_linear", 1.0, fade_time)
		_music_tweens[_music_index] = tween


func stop_music(fade_time: float = MUSIC_FADE_TIME) -> void:
	play_music(null, fade_time)


func current_music() -> AudioStream:
	return _music_stream


## Sets a bus volume from a 0-100 percent setting.
func apply_volume(bus: StringName, percent: int) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("AudioManager: no audio bus named '%s'." % bus)
		return
	AudioServer.set_bus_volume_db(index, AudioBuses.percent_to_db(percent))
	AudioServer.set_bus_mute(index, percent <= 0)


## Adds any missing game buses. Safe to call more than once.
static func ensure_buses() -> void:
	for bus: StringName in AudioBuses.CREATED:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, AudioBuses.SENDS[bus])


func _apply_saved_volumes() -> void:
	for bus: StringName in AudioBuses.DEFAULT_VOLUMES:
		apply_volume(bus, Settings.get_volume(bus))


func _create_players() -> void:
	var game_root: Node = Node.new()
	game_root.name = "GameSounds"
	game_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game_root)

	for i: int in SFX_POOL_SIZE:
		var player: AudioStreamPlayer = _new_flat_player(AudioBuses.SFX, game_root)
		player.finished.connect(_sfx_pool.release.bind(i))
		_sfx_players.append(player)

	for i: int in UI_POOL_SIZE:
		var player: AudioStreamPlayer = _new_flat_player(AudioBuses.UI, self)
		player.finished.connect(_ui_pool.release.bind(i))
		_ui_players.append(player)

	for i: int in POSITIONAL_POOL_SIZE:
		var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		player.bus = AudioBuses.SFX
		player.max_distance = POSITIONAL_MAX_DISTANCE
		game_root.add_child(player)
		player.finished.connect(_positional_pool.release.bind(i))
		_positional_players.append(player)

	for i: int in 2:
		_music_players.append(_new_flat_player(AudioBuses.MUSIC, self))


func _new_flat_player(bus: StringName, parent: Node) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = bus
	parent.add_child(player)
	return player


func _play_flat(
	players: Array[AudioStreamPlayer],
	pool: VoicePool,
	stream: AudioStream,
	volume_db: float,
	pitch_variation: float
) -> AudioStreamPlayer:
	if stream == null:
		return null
	var index: int = pool.acquire()
	var player: AudioStreamPlayer = players[index]
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = _random_pitch(pitch_variation)
	player.play()
	sound_played.emit(stream)
	return player


static func _random_pitch(variation: float) -> float:
	if variation <= 0.0:
		return 1.0
	return 1.0 + randf_range(-variation, variation)


func _fade_out(index: int, fade_time: float) -> void:
	_kill_music_tween(index)
	var player: AudioStreamPlayer = _music_players[index]
	if not player.playing:
		return
	if fade_time <= 0.0:
		player.stop()
		return
	var tween: Tween = create_tween()
	tween.tween_property(player, ^"volume_linear", 0.0, fade_time)
	tween.tween_callback(player.stop)
	_music_tweens[index] = tween


func _kill_music_tween(index: int) -> void:
	var tween: Tween = _music_tweens[index]
	if tween != null and tween.is_valid():
		tween.kill()
	_music_tweens[index] = null
