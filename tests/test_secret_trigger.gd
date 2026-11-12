extends GutTest
## Secret triggers join the secret group (so the level can total them),
## count once for the player, and ignore everything else.

const SECRET_SCRIPT: GDScript = preload("res://levels/entities/secret_trigger.gd")
const PLAYER_SCRIPT: GDScript = preload("res://player/player.gd")


func _make_secret() -> SecretTrigger:
	var secret: SecretTrigger = SECRET_SCRIPT.new() as SecretTrigger
	add_child_autofree(secret)
	return secret


func test_secret_is_in_the_secret_group() -> void:
	assert_true(_make_secret().is_in_group(SecretTrigger.SECRET_GROUP))


func test_player_finds_the_secret_once() -> void:
	var secret: SecretTrigger = _make_secret()
	# Never added to the tree, so the player's _ready (and its child nodes) never run.
	var player: Player = autofree(PLAYER_SCRIPT.new()) as Player
	watch_signals(EventBus)
	secret._on_body_entered(player)
	secret._on_body_entered(player)
	assert_true(secret.is_found)
	assert_signal_emit_count(EventBus, "secret_found", 1)


func test_other_bodies_do_not_find_it() -> void:
	var secret: SecretTrigger = _make_secret()
	var body: StaticBody3D = autofree(StaticBody3D.new())
	watch_signals(EventBus)
	secret._on_body_entered(body)
	assert_false(secret.is_found)
	assert_signal_not_emitted(EventBus, "secret_found")
