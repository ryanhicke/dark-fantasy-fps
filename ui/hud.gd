extends CanvasLayer
## Crosshair, health, ammo counter, damage flash, and the respawn prompt.
##
## Listens to EventBus only, so it never needs a reference to the player and
## survives level changes untouched.

## Seconds after death before the respawn prompt appears and Enter works.
@export var respawn_prompt_delay: float = 2.0
## Peak opacity of the red screen flash when the player is hurt.
@export var damage_flash_alpha: float = 0.35
@export var damage_flash_duration: float = 0.3

var _ammo_counts: Dictionary[StringName, int] = {}
var _current_ammo_type: StringName = &""
var _awaiting_respawn: bool = false
var _flash_tween: Tween

@onready var _ammo_label: Label = $AmmoLabel
@onready var _health_label: Label = $HealthLabel
@onready var _damage_flash: ColorRect = $DamageFlash
@onready var _death_prompt: Label = $DeathPrompt


func _ready() -> void:
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	_refresh_ammo()


func _unhandled_input(event: InputEvent) -> void:
	if _awaiting_respawn and event.is_action_pressed("respawn"):
		_awaiting_respawn = false
		_death_prompt.visible = false
		get_viewport().set_input_as_handled()
		EventBus.player_respawn_requested.emit()


func _on_player_ammo_changed(ammo_type: StringName, amount: int, _maximum: int) -> void:
	# Cache every type so switching weapons can show the right count at once.
	_ammo_counts[ammo_type] = amount
	if ammo_type == _current_ammo_type:
		_refresh_ammo()


func _on_player_weapon_changed(weapon_data: WeaponData) -> void:
	_current_ammo_type = weapon_data.ammo_type if weapon_data != null else &""
	_refresh_ammo()


func _on_player_health_changed(current: float, _maximum: float) -> void:
	# Round up so the player never sees 0 while still alive.
	_health_label.text = "Health: %d" % ceili(current)


func _on_player_damaged(_amount: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_damage_flash.color.a = damage_flash_alpha
	_flash_tween = create_tween()
	_flash_tween.tween_property(_damage_flash, "color:a", 0.0, damage_flash_duration)


func _on_player_died() -> void:
	await get_tree().create_timer(respawn_prompt_delay).timeout
	_death_prompt.visible = true
	_awaiting_respawn = true


func _refresh_ammo() -> void:
	_ammo_label.visible = _current_ammo_type != &""
	if _ammo_label.visible:
		_ammo_label.text = "%s: %d" % [
			String(_current_ammo_type).capitalize(), _ammo_counts.get(_current_ammo_type, 0)
		]
