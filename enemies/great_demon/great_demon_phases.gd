class_name GreatDemonPhases
extends Node
## Runs the great demon fight (docs/enemies.md, Level 8). Child of the
## great demon's Enemy node.
##
## Sealed: the demon's EnemyData makes it immune to everything, and its
## EnemySummoner children summon constantly once it notices the player.
## Each EventBus.obelisk_destroyed: it roars, a crack of light opens,
## summons come faster, and summoners whose unlock_at_stage is reached
## join in (werewolves after the 2nd obelisk). After the last obelisk it
## stops summoning and switches to [member final_data]: it can now be hurt,
## only by lightning, and attacks directly.
##
## Cracks are the children of the Sprite named Crack1, Crack2, ... and
## start hidden.

signal stage_changed(obelisks_destroyed: int)

@export var obelisk_count: int = 4
## Stats for the final, vulnerable phase (lightning-only resistances).
@export var final_data: EnemyData
## Each destroyed obelisk multiplies every summon interval by this, so
## summons come faster as the fight goes on.
@export_range(0.1, 1.0) var interval_scale_per_obelisk: float = 0.75
## Played on each destroyed obelisk. Null is silent.
@export var roar_sound: AudioStream

var obelisks_destroyed: int = 0

var _demon: Enemy
var _sprite: EnemySprite
var _summoners: Array[EnemySummoner] = []
var _base_intervals: Array[float] = []
var _cracks: Array[Node3D] = []
var _fight_started: bool = false


func _ready() -> void:
	_demon = get_parent() as Enemy
	if _demon == null or final_data == null:
		push_error("%s: needs an Enemy parent and final_data." % name)
		return
	_sprite = _demon.get_node("Sprite") as EnemySprite
	for child: Node in _demon.get_children():
		var summoner: EnemySummoner = child as EnemySummoner
		if summoner != null:
			_summoners.append(summoner)
			_base_intervals.append(summoner.summon_interval)
	for i: int in obelisk_count:
		var crack: Node3D = _sprite.get_node_or_null("Crack%d" % (i + 1)) as Node3D
		if crack != null:
			crack.visible = false
			_cracks.append(crack)
	_demon.alerted.connect(_on_demon_alerted)
	EventBus.obelisk_destroyed.connect(on_obelisk_destroyed)


func is_final_phase() -> bool:
	return obelisks_destroyed >= obelisk_count


## Also callable directly (tests, scripted sequences).
func on_obelisk_destroyed() -> void:
	if is_final_phase() or _demon.is_dead():
		return
	obelisks_destroyed += 1
	if obelisks_destroyed - 1 < _cracks.size():
		_cracks[obelisks_destroyed - 1].visible = true
	if is_final_phase():
		_enter_final_phase()
	else:
		# Breaking an obelisk starts the fight even if it hadn't seen the
		# player yet; waking emits alerted, which starts the summoners.
		_demon.wake()
		_update_summoners()
	# After any data change, which resets the sprite color and would cut
	# the roar's flash short.
	_roar()
	stage_changed.emit(obelisks_destroyed)


func _on_demon_alerted() -> void:
	if _fight_started or is_final_phase():
		return
	_fight_started = true
	_update_summoners()


func _update_summoners() -> void:
	if not _fight_started:
		return
	var scale: float = pow(interval_scale_per_obelisk, obelisks_destroyed)
	for i: int in _summoners.size():
		var summoner: EnemySummoner = _summoners[i]
		summoner.summon_interval = _base_intervals[i] * scale
		summoner.set_active(obelisks_destroyed >= summoner.unlock_at_stage)


func _enter_final_phase() -> void:
	for summoner: EnemySummoner in _summoners:
		summoner.set_active(false)
	_demon.change_data(final_data)
	# Reveals the lightning pickup (and its mana) in the arena.
	EventBus.great_demon_unsealed.emit()


func _roar() -> void:
	_demon.play_sound(roar_sound)
	_sprite.flash_pain(EnemyBrain.State.CHASE, false)
