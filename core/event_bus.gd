extends Node
## Global signal hub so systems can talk without holding references to each other.
##
## No class_name: the autoload name (EventBus) is the global identifier, and a
## matching class_name would conflict with it.
##
## Signals are declared here and emitted by other systems, so the
## "unused_signal" warning is suppressed per signal.
## Payloads are intentionally minimal for now; extend them as systems land.

@warning_ignore("unused_signal")
signal player_damaged(amount: float)

@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node)

@warning_ignore("unused_signal")
signal secret_found

@warning_ignore("unused_signal")
signal level_completed
