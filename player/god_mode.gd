class_name GodMode
extends Node
## Invulnerability cheat. Tab toggles it on the parent Player, and the HUD
## shows CHEATER while it is on. Works in release builds too: unlike
## DevCheats this is a player-facing cheat, Doom-style.

## A cheat, so a raw key rather than a rebindable input action.
const TOGGLE_KEY: Key = KEY_TAB

## Static so the cheat carries over to the next level's player, which is a
## new node. Not written to save files: it lasts until toggled off or the
## game is closed.
static var active: bool = false

@onready var _health: HealthComponent = get_parent().get_node(NodePath(HealthComponent.NODE_NAME)) as HealthComponent


func _ready() -> void:
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != TOGGLE_KEY:
		return
	get_viewport().set_input_as_handled()
	toggle()


func toggle() -> void:
	active = not active
	_apply()


func _apply() -> void:
	_health.cheat_invulnerable = active
	EventBus.player_cheat_changed.emit(active)
