class_name DevCheats
extends Node
## DEV ONLY. F4 in debug builds gives the parent Player every weapon and
## full ammo, so test levels don't need pickups for everything. Does
## nothing in release builds.

## Dev tool, so a raw key rather than an input action (like F2/F3).
const GIVE_ALL_KEY: Key = KEY_F4

@onready var _player: Player = get_parent() as Player


func _ready() -> void:
	# Release builds never listen, so the cheat can't be triggered at all.
	set_process_unhandled_input(OS.is_debug_build())


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != GIVE_ALL_KEY:
		return
	get_viewport().set_input_as_handled()
	_player.give_everything()
	EventBus.pickup_collected.emit("DEV: all weapons and full ammo")
