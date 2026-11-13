class_name HudStatus
extends Control
## The status strip along the bottom of the HUD: health and mana bars on the
## left, the held weapon's ammo on the right, and key icons above the bars.
##
## Bars and icons rather than words, because they stay readable at the low
## internal resolution where the default font goes soft.
##
## Listens to EventBus only and updates on change, never per frame.

const MANA: StringName = &"mana"

@export_group("Health Colors")
## Health at or below these fractions of maximum turns the number amber,
## then red, so low health reads at a glance.
@export_range(0.0, 1.0) var health_warning_fraction: float = 0.5
@export_range(0.0, 1.0) var health_danger_fraction: float = 0.25
@export var health_normal_color: Color = Color(0.9, 0.9, 0.85)
@export var health_warning_color: Color = Color(1.0, 0.75, 0.2)
@export var health_danger_color: Color = Color(1.0, 0.2, 0.15)
@export_group("")

## Icon shown beside the count for each ammo type that isn't mana.
@export var ammo_icons: Dictionary[StringName, Texture2D] = {}

var _ammo_counts: Dictionary[StringName, int] = {}
var _current_ammo_type: StringName = &""

@onready var _health_bar: ProgressBar = $Vitals/Row/HealthBar
@onready var _health_value: Label = $Vitals/Row/HealthValue
@onready var _mana_bar: ProgressBar = $Vitals/Row/ManaBar
@onready var _mana_value: Label = $Vitals/Row/ManaValue
@onready var _ammo_panel: Control = $Ammo
@onready var _ammo_value: Label = $Ammo/Row/AmmoValue
@onready var _ammo_icon: TextureRect = $Ammo/Row/AmmoIcon
## Indexed by KeyRing.KeyType.
@onready var _key_icons: Array[TextureRect] = [$Keys/KeyGold, $Keys/KeySilver, $Keys/KeyBone]


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	EventBus.player_keys_changed.connect(_on_player_keys_changed)
	_refresh_ammo()


func health_color(current: float, maximum: float) -> Color:
	var fraction: float = current / maximum if maximum > 0.0 else 0.0
	if fraction <= health_danger_fraction:
		return health_danger_color
	if fraction <= health_warning_fraction:
		return health_warning_color
	return health_normal_color


func _on_player_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	# Round up so the player never sees 0 while still alive.
	_health_value.text = str(ceili(current))
	_health_value.add_theme_color_override(&"font_color", health_color(current, maximum))


func _on_player_ammo_changed(ammo_type: StringName, amount: int, maximum: int) -> void:
	if ammo_type == MANA:
		_mana_bar.max_value = maximum
		_mana_bar.value = amount
		_mana_value.text = str(amount)
		return
	# Cache every type so switching weapons can show the right count at once.
	_ammo_counts[ammo_type] = amount
	if ammo_type == _current_ammo_type:
		_refresh_ammo()


func _on_player_weapon_changed(weapon_data: WeaponData) -> void:
	_current_ammo_type = weapon_data.ammo_type if weapon_data != null else &""
	_refresh_ammo()


func _on_player_keys_changed(keys: Array[int]) -> void:
	for key_type: int in _key_icons.size():
		_key_icons[key_type].visible = keys.has(key_type)


## Melee weapons use no ammo and spells use mana, which has its own bar, so
## the ammo panel only shows for arrows and axes.
func _refresh_ammo() -> void:
	_ammo_panel.visible = _current_ammo_type != &"" and _current_ammo_type != MANA
	if not _ammo_panel.visible:
		return
	_ammo_value.text = str(_ammo_counts.get(_current_ammo_type, 0))
	_ammo_icon.texture = ammo_icons.get(_current_ammo_type)
