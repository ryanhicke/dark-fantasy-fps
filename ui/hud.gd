extends CanvasLayer
## Crosshair, health, ammo, keys, pickup/door messages, damage flash, the
## respawn prompt, and a debug FPS/resolution readout (F3, debug builds).
##
## Listens to EventBus only, so it never needs a reference to the player and
## survives level changes untouched.

## Seconds after death before the respawn prompt appears and Enter works.
@export var respawn_prompt_delay: float = 2.0
## Peak opacity of the red screen flash when the player is hurt.
@export var damage_flash_alpha: float = 0.35
@export var damage_flash_duration: float = 0.3
@export var damage_flash_color: Color = Color(0.8, 0.0, 0.0)
@export var heal_flash_color: Color = Color(0.2, 0.9, 0.3)
## Seconds per on/off blink while the armor spell is about to fade.
@export var armor_blink_period: float = 0.15
## Seconds a pickup or door message stays on screen.
@export var message_duration: float = 2.5

## Dev tool, so a raw key rather than an input action.
const DEBUG_TOGGLE_KEY: Key = KEY_F3

var _ammo_counts: Dictionary[StringName, int] = {}
var _current_ammo_type: StringName = &""
var _awaiting_respawn: bool = false
var _flash_tween: Tween
var _armor_blink_tween: Tween
var _render_size: Vector2i = Vector2i.ZERO

@onready var _ammo_label: Label = $AmmoLabel
@onready var _health_label: Label = $HealthLabel
@onready var _damage_flash: ColorRect = $DamageFlash
@onready var _armor_tint: ColorRect = $ArmorTint
@onready var _death_prompt: Label = $DeathPrompt
@onready var _keys_label: Label = $KeysLabel
@onready var _message_label: Label = $MessageLabel
@onready var _message_timer: Timer = $MessageTimer
@onready var _debug_label: Label = $DebugLabel
@onready var _debug_timer: Timer = $DebugTimer


func _ready() -> void:
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.screen_flash_requested.connect(_on_screen_flash_requested)
	EventBus.player_invulnerability_changed.connect(_on_player_invulnerability_changed)
	EventBus.player_invulnerability_ending.connect(_on_player_invulnerability_ending)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawn_requested.connect(_on_player_respawn_requested)
	EventBus.player_keys_changed.connect(_on_player_keys_changed)
	EventBus.key_picked_up.connect(_on_key_picked_up)
	EventBus.pickup_collected.connect(_show_message)
	EventBus.door_locked.connect(_on_door_locked)
	_message_timer.timeout.connect(_on_message_timer_timeout)
	EventBus.render_resolution_changed.connect(_on_render_resolution_changed)
	_debug_timer.timeout.connect(_refresh_debug)
	_refresh_ammo()


func _unhandled_input(event: InputEvent) -> void:
	if _is_debug_toggle(event):
		get_viewport().set_input_as_handled()
		_toggle_debug()
		return
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
	_flash_screen(damage_flash_color)


func _on_player_healed(_amount: float) -> void:
	_flash_screen(heal_flash_color)


func _on_screen_flash_requested(color: Color) -> void:
	_flash_screen(Color(color, 1.0), color.a)


func _flash_screen(color: Color, alpha: float = -1.0) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_damage_flash.color = Color(color, alpha if alpha >= 0.0 else damage_flash_alpha)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_damage_flash, "color:a", 0.0, damage_flash_duration)


func _on_player_invulnerability_changed(active: bool) -> void:
	_stop_armor_blink()
	_armor_tint.visible = active
	if not active:
		_show_message("Your armor fades")


## Blink the tint in the last moment so the player knows exactly when they
## can be hurt again.
func _on_player_invulnerability_ending() -> void:
	_stop_armor_blink()
	_armor_blink_tween = create_tween().set_loops()
	_armor_blink_tween.tween_callback(_toggle_armor_tint).set_delay(armor_blink_period)


func _toggle_armor_tint() -> void:
	_armor_tint.visible = not _armor_tint.visible


func _stop_armor_blink() -> void:
	if _armor_blink_tween != null:
		_armor_blink_tween.kill()
		_armor_blink_tween = null


func _on_player_died() -> void:
	await get_tree().create_timer(respawn_prompt_delay).timeout
	_death_prompt.visible = true
	_awaiting_respawn = true


func _on_player_respawn_requested() -> void:
	_hide_message()


func _on_player_keys_changed(keys: Array[int]) -> void:
	_keys_label.visible = not keys.is_empty()
	var names: PackedStringArray = PackedStringArray()
	for key: int in keys:
		names.append(KeyRing.key_name(key))
	_keys_label.text = "Keys: %s" % ", ".join(names)


func _on_key_picked_up(key_type: int) -> void:
	_show_message("Picked up the %s Key" % KeyRing.key_name(key_type))


func _on_door_locked(required_key: int) -> void:
	_show_message("You need the %s Key" % KeyRing.key_name(required_key))


func _on_message_timer_timeout() -> void:
	_hide_message()


func _show_message(text: String, expires: bool = true) -> void:
	_message_label.text = text
	_message_label.visible = true
	if expires:
		_message_timer.start(message_duration)
	else:
		_message_timer.stop()


func _hide_message() -> void:
	_message_timer.stop()
	_message_label.visible = false


func _refresh_ammo() -> void:
	_ammo_label.visible = _current_ammo_type != &""
	if _ammo_label.visible:
		_ammo_label.text = "%s: %d" % [
			String(_current_ammo_type).capitalize(), _ammo_counts.get(_current_ammo_type, 0)
		]


func _on_render_resolution_changed(render_size: Vector2i) -> void:
	_render_size = render_size
	_refresh_debug()


func _is_debug_toggle(event: InputEvent) -> bool:
	var key: InputEventKey = event as InputEventKey
	return (OS.is_debug_build() and key != null and key.pressed and not key.echo
		and key.keycode == DEBUG_TOGGLE_KEY)


func _toggle_debug() -> void:
	_debug_label.visible = not _debug_label.visible
	# Only ticks while shown, so the readout costs nothing when hidden.
	if _debug_label.visible:
		_refresh_debug()
		_debug_timer.start()
	else:
		_debug_timer.stop()


## Refreshed on a timer, not every frame, to avoid a string per frame.
func _refresh_debug() -> void:
	if _debug_label.visible:
		_debug_label.text = "%d FPS  %dx%d" % [
			Engine.get_frames_per_second(), _render_size.x, _render_size.y
		]
