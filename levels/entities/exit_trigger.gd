class_name ExitTrigger
extends Area3D
## Invisible brush volume (TrenchBroom trigger_exit). The player walking in
## completes the level.

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	EventBus.level_completed.emit()
