class_name RiseTrigger
extends Area3D
## Keeps its parent Enemy dormant (hidden in the ground, no AI, no
## collision) until the player enters this area, then makes it rise once.
##
## The area does the proximity check through physics overlap events, so a
## dormant enemy costs nothing per frame (no distance checks, no raycasts).
## Set collision_layer to 0 and the mask to the player's layer.

var _enemy: Enemy


func _ready() -> void:
	_enemy = get_parent() as Enemy
	if _enemy == null:
		push_error("%s: RiseTrigger must be a child of an Enemy." % name)
		return
	body_entered.connect(_on_body_entered)
	# Deferred: the Enemy's own _ready runs after this child's.
	_enemy.make_dormant.call_deferred()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(Player.GROUP) or not _enemy.is_dormant():
		return
	body_entered.disconnect(_on_body_entered)
	# Deferred: toggling monitoring inside a physics callback is not allowed.
	set_deferred("monitoring", false)
	_enemy.rise_from_ground()
