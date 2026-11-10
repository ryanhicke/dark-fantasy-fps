extends CanvasLayer
## Crosshair and the ammo counter for the current weapon.
##
## Listens to EventBus only, so it never needs a reference to the player and
## survives level changes untouched.

var _ammo_counts: Dictionary[StringName, int] = {}
var _current_ammo_type: StringName = &""

@onready var _ammo_label: Label = $AmmoLabel


func _ready() -> void:
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	_refresh_ammo()


func _on_player_ammo_changed(ammo_type: StringName, amount: int, _maximum: int) -> void:
	# Cache every type so switching weapons can show the right count at once.
	_ammo_counts[ammo_type] = amount
	if ammo_type == _current_ammo_type:
		_refresh_ammo()


func _on_player_weapon_changed(weapon_data: WeaponData) -> void:
	_current_ammo_type = weapon_data.ammo_type if weapon_data != null else &""
	_refresh_ammo()


func _refresh_ammo() -> void:
	_ammo_label.visible = _current_ammo_type != &""
	if _ammo_label.visible:
		_ammo_label.text = "%s: %d" % [
			String(_current_ammo_type).capitalize(), _ammo_counts.get(_current_ammo_type, 0)
		]
