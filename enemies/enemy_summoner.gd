class_name EnemySummoner
extends Node3D
## Lets its parent Enemy summon other enemies (e.g. the necromancer's
## demons). Summoned enemies rise out of the ground around the summoner.
##
## Performance: every enemy it can summon is instantiated once at level
## load into a fixed pool of [member max_alive] nodes. A summon reuses a
## pool node that was never used or has died (its corpse vanishes), so the
## fight never instantiates nodes and never exceeds the cap.
##
## Expects a child RayCast3D named "SpawnCast" (disabled) that keeps
## summons from appearing inside walls. Node3D (not Node) so the cast
## follows the summoner; place it about 1 m up so it clears the floor.

## The enemy scene to summon. Must have an Enemy root.
@export var summon_scene: PackedScene
## Most summoned enemies alive at once. Also the pool size.
@export var max_alive: int = 5
## Off: only set_active() starts and stops summoning (a boss script in
## charge, e.g. GreatDemonPhases). On: starts by itself at the health
## threshold below.
@export var auto_start: bool = true
## With auto_start: starts summoning once the summoner's health falls to
## this fraction or below. 1 summons from level start, so keep it below 1.
@export_range(0.0, 1.0) var start_below_health: float = 0.5
## For bosses with stages (GreatDemonPhases): this summoner joins in once
## this many stages are done (e.g. werewolves after the 2nd obelisk).
@export var unlock_at_stage: int = 0
## Seconds between summon waves once active.
@export var summon_interval: float = 6.0
## Enemies raised per wave (limited by free room under the cap).
@export var per_wave: int = 2
## Meters from the summoner where summons rise.
@export var spawn_radius: float = 3.0
## Meters kept between a summon and a wall the spawn ray hit.
@export var wall_margin: float = 0.6

var _owner_enemy: Enemy
var _owner_health: HealthComponent
var _pool: Array[Enemy] = []
var _used: Array[bool] = []
var _active: bool = false
var _time_to_next: float = 0.0

@onready var _spawn_cast: RayCast3D = $SpawnCast


## How many to raise this wave. Static so the cap rule can be unit tested.
static func wave_size(alive: int, cap: int, wave: int) -> int:
	return clampi(cap - alive, 0, wave)


func _ready() -> void:
	set_process(false)
	_owner_enemy = get_parent() as Enemy
	if _owner_enemy == null or summon_scene == null:
		push_error("%s: needs an Enemy parent and a summon_scene." % name)
		return
	_owner_health = HealthComponent.find_on(_owner_enemy)
	_owner_health.health_changed.connect(_on_owner_health_changed)
	_owner_health.died.connect(_on_owner_died)
	_spawn_cast.enabled = false
	_spawn_cast.add_exception(_owner_enemy)
	# Deferred: the level is still adding its children right now.
	_fill_pool.call_deferred()


func _fill_pool() -> void:
	var level: Node = _owner_enemy.get_parent()
	for i: int in max_alive:
		var summon: Enemy = summon_scene.instantiate() as Enemy
		summon.counts_for_stats = false
		summon.name = "%s_Summon%d" % [_owner_enemy.name, i]
		level.add_child(summon)
		summon.make_dormant()
		_pool.append(summon)
		_used.append(false)


func is_active() -> bool:
	return _active


## Starts or stops summoning waves. Starting summons a wave right away.
func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	if active:
		_time_to_next = 0.0
	set_process(active)


func alive_count() -> int:
	var alive: int = 0
	for i: int in _pool.size():
		if _used[i] and not _pool[i].is_dead():
			alive += 1
	return alive


func _process(delta: float) -> void:
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	_time_to_next = summon_interval
	_summon_wave()


func _summon_wave() -> void:
	var count: int = wave_size(alive_count(), max_alive, per_wave)
	for n: int in count:
		var slot: int = _free_slot()
		if slot < 0:
			return
		_used[slot] = true
		_pool[slot].respawn_rising(_spawn_point(n, count))


## A never-used slot first, so corpses stay on the floor as long as possible.
func _free_slot() -> int:
	for i: int in _pool.size():
		if not _used[i]:
			return i
	for i: int in _pool.size():
		if _pool[i].is_dead():
			return i
	return -1


## Spreads a wave evenly around the summoner, from a random start angle.
func _spawn_point(index: int, count: int) -> Vector3:
	var angle: float = randf() * TAU if index == 0 else 0.0
	angle += TAU * float(index) / float(maxi(count, 1))
	var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius
	_spawn_cast.target_position = _spawn_cast.to_local(_spawn_cast.global_position + offset)
	_spawn_cast.force_raycast_update()
	var point: Vector3 = _owner_enemy.global_position + offset
	if _spawn_cast.is_colliding():
		var hit: Vector3 = _spawn_cast.get_collision_point()
		var safe: float = maxf(0.0, Vector2(hit.x, hit.z).distance_to(
			Vector2(_spawn_cast.global_position.x, _spawn_cast.global_position.z)) - wall_margin)
		point = _owner_enemy.global_position + offset.normalized() * safe
	return point


func _on_owner_health_changed(current: float, maximum: float) -> void:
	if not auto_start or _active or maximum <= 0.0 or current <= 0.0:
		return
	if current / maximum <= start_below_health:
		set_active(true)


## Summons already raised keep fighting; no new ones come.
func _on_owner_died(_source: Node) -> void:
	set_active(false)
