class_name LevelStats
extends RefCounted
## Tallies for one play of a level, shown on the intermission screen.

const SECONDS_PER_MINUTE: int = 60

var level_name: String = ""
var kills: int = 0
var total_kills: int = 0
var secrets: int = 0
var total_secrets: int = 0
var time_seconds: float = 0.0


## Formats as m:ss, e.g. 75.4 -> "1:15". Minutes are not capped at 59.
static func format_time(seconds: float) -> String:
	var whole: int = maxi(floori(seconds), 0)
	return "%d:%02d" % [floori(whole / float(SECONDS_PER_MINUTE)), whole % SECONDS_PER_MINUTE]
