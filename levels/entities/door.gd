class_name Door
extends AnimatableBody3D
## A brush door (TrenchBroom func_door) that slides up when used, Doom-style,
## waits, then closes. Reopens instead of crushing anyone in the doorway.
##
## FuncGodot builds the brush mesh and collision shapes as children and
## stores the TrenchBroom properties in func_godot_properties at map build
## time; they are read once in _ready.

enum State {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING,
}

## Must match inverse_scale_factor in levels/map_config/dark_fantasy_map_settings.tres.
const MAP_UNITS_PER_METER: float = 32.0
## Doors with a targetname join this group so levers can find them.
const TRIGGER_GROUP: StringName = &"trigger_targets"
## A wait of this (or any negative value) keeps the door open forever.
const STAY_OPEN: float = -1.0
## Meters trimmed off each side of the blocking check, so walls touching
## the door's edges don't count as blockers.
const BLOCK_CHECK_INSET: float = 0.05
## Defaults mirror the func_door entry in levels/map_config/ (map units / seconds).
const DEFAULT_SPEED_UNITS: float = 100.0
const DEFAULT_WAIT: float = 3.0
const DEFAULT_LIP_UNITS: float = 8.0

## Filled by FuncGodot at map build. Exported so the values are saved in
## the level scene and available at runtime.
@export var func_godot_properties: Dictionary = {}

var required_key: int = KeyRing.NO_KEY
var state: State = State.CLOSED
## Set from TrenchBroom. A door with a targetname is opened only by levers
## that target it, never by the use key.
var targetname: String = ""
## Lever pulls needed before the door opens (e.g. 2 for a two-lever gate).
var trigger_count: int = 1
var _triggers_received: int = 0

var _speed: float = 0.0
var _wait: float = 0.0
var _wait_left: float = 0.0
## Middle of the door brush in this node's space; sounds play from here,
## not from the origin (which can be anywhere on a map brush).
var _center: Vector3 = Vector3.ZERO
var _closed_y: float = 0.0
var _open_y: float = 0.0
var _block_check: ShapeCast3D


func _enter_tree() -> void:
	add_to_group(SaveSnapshot.SAVEABLE_GROUP)


func _ready() -> void:
	required_key = int(func_godot_properties.get("key_type", KeyRing.NO_KEY))
	_speed = float(func_godot_properties.get("speed", DEFAULT_SPEED_UNITS)) / MAP_UNITS_PER_METER
	_wait = float(func_godot_properties.get("wait", DEFAULT_WAIT))
	targetname = str(func_godot_properties.get("targetname", ""))
	trigger_count = maxi(int(func_godot_properties.get("count", 1)), 1)
	if not targetname.is_empty():
		add_to_group(TRIGGER_GROUP)
	var lip: float = float(func_godot_properties.get("lip", DEFAULT_LIP_UNITS)) / MAP_UNITS_PER_METER
	var bounds: AABB = _local_bounds()
	_center = bounds.get_center()
	_closed_y = position.y
	_open_y = _closed_y + maxf(bounds.size.y - lip, 0.0)
	_block_check = _create_block_check(bounds)
	set_physics_process(false)


## True if [param keys] lets the holder through a door needing [param key].
static func is_unlocked_for(key: int, keys: KeyRing) -> bool:
	return key == KeyRing.NO_KEY or (keys != null and keys.has_key(key))


## Called by the player's use key.
func use(user: Node) -> void:
	if not targetname.is_empty():
		return
	match state:
		State.CLOSED, State.CLOSING:
			if not is_unlocked_for(required_key, KeyRing.find_on(user)):
				EventBus.door_locked.emit(required_key)
				_play_sound(AudioManager.sounds.door_locked)
				return
			_set_state(State.OPENING)
		State.OPEN:
			# Using an open door holds it open a little longer.
			_wait_left = _wait


## Called by a lever targeting this door. Opens once enough pulls arrive.
func trigger() -> void:
	_triggers_received += 1
	if _triggers_received >= trigger_count and state != State.OPEN:
		_set_state(State.OPENING)


## Saveable contract.
func save_state() -> Dictionary:
	return {"state": state, "y": position.y, "triggers": _triggers_received, "wait_left": _wait_left}


## Restores without sounds: the door just is where it was.
func load_state(saved: Dictionary) -> void:
	_triggers_received = int(saved.get("triggers", 0))
	position.y = clampf(float(saved.get("y", _closed_y)), minf(_closed_y, _open_y), maxf(_closed_y, _open_y))
	var restored: int = int(saved.get("state", State.CLOSED))
	state = restored as State if restored >= State.CLOSED and restored <= State.CLOSING else State.CLOSED
	_wait_left = float(saved.get("wait_left", _wait))
	match state:
		State.CLOSED:
			set_physics_process(false)
		State.OPEN:
			set_physics_process(_wait >= 0.0)
		_:
			set_physics_process(true)


func _physics_process(delta: float) -> void:
	match state:
		State.OPENING:
			position.y = move_toward(position.y, _open_y, _speed * delta)
			if position.y == _open_y:
				_set_state(State.OPEN)
		State.OPEN:
			_wait_left -= delta
			if _wait_left <= 0.0:
				_set_state(State.CLOSING)
		State.CLOSING:
			if _is_blocked():
				_set_state(State.OPENING)
				return
			position.y = move_toward(position.y, _closed_y, _speed * delta)
			if position.y == _closed_y:
				_set_state(State.CLOSED)


func _set_state(new_state: State) -> void:
	if new_state == State.OPENING and state != State.OPENING:
		_play_sound(AudioManager.sounds.door_open)
	elif new_state == State.CLOSING:
		_play_sound(AudioManager.sounds.door_close)
	state = new_state
	match state:
		State.OPEN:
			_wait_left = _wait
			# Nothing left to animate for a door that never closes.
			set_physics_process(_wait >= 0.0)
		State.CLOSED:
			set_physics_process(false)
		_:
			set_physics_process(true)


func _play_sound(stream: AudioStream) -> void:
	AudioManager.play_sfx_at(stream, global_transform * _center)


## Something standing in the doorway (player or enemy) stops it closing.
func _is_blocked() -> bool:
	_block_check.force_shapecast_update()
	for i: int in _block_check.get_collision_count():
		if _block_check.get_collider(i) is CharacterBody3D:
			return true
	return false


## Bounds of the brush meshes in this node's space. Computed once.
func _local_bounds() -> AABB:
	var bounds: AABB = AABB()
	var found: bool = false
	for child: Node in get_children():
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var child_bounds: AABB = mesh_instance.transform * mesh_instance.mesh.get_aabb()
		bounds = child_bounds if not found else bounds.merge(child_bounds)
		found = true
	if not found:
		push_warning("%s: no brush mesh found; door will not move." % name)
	return bounds


## A box covering the closed doorway. Top-level so it stays put while the
## door moves; only queried while closing, so it costs nothing otherwise.
func _create_block_check(bounds: AABB) -> ShapeCast3D:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(
		maxf(bounds.size.x - BLOCK_CHECK_INSET * 2.0, BLOCK_CHECK_INSET),
		maxf(bounds.size.y, BLOCK_CHECK_INSET),
		maxf(bounds.size.z - BLOCK_CHECK_INSET * 2.0, BLOCK_CHECK_INSET)
	)
	var cast: ShapeCast3D = ShapeCast3D.new()
	cast.shape = box
	cast.target_position = Vector3.ZERO
	cast.enabled = false
	cast.top_level = true
	cast.add_exception(self)
	add_child(cast)
	cast.global_transform = Transform3D(global_basis, global_transform * bounds.get_center())
	return cast
