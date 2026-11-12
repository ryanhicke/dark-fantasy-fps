class_name SecretTrigger
extends Area3D
## Invisible brush volume (TrenchBroom trigger_secret) placed inside a hidden
## area. The player entering it counts the secret once, Doom-style.

## The level counts members of this group at load for the secrets total.
const SECRET_GROUP: StringName = &"secret"
const FOUND_MESSAGE: String = "A secret is revealed!"

var is_found: bool = false


func _init() -> void:
	# In _init, not _ready, so Level._ready (which runs after its children)
	# can already count the group either way.
	add_to_group(SECRET_GROUP)
	add_to_group(SaveSnapshot.SAVEABLE_GROUP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Saveable contract. The level's secret tally is saved with its stats.
func save_state() -> Dictionary:
	return {"found": is_found}


func load_state(state: Dictionary) -> void:
	if bool(state.get("found", false)):
		is_found = true
		set_deferred("monitoring", false)


func _on_body_entered(body: Node3D) -> void:
	if is_found or not body is Player:
		return
	is_found = true
	AudioManager.play_ui(AudioManager.sounds.secret_found)
	EventBus.hud_message_requested.emit(FOUND_MESSAGE)
	EventBus.secret_found.emit()
	# Deferred: this runs inside a physics callback.
	set_deferred("monitoring", false)
