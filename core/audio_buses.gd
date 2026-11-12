class_name AudioBuses
## Audio bus names and the volume conversion shared by AudioManager and
## Settings. AudioManager creates the buses at startup (see there).

const MASTER: StringName = &"Master"
const MUSIC: StringName = &"Music"
const SFX: StringName = &"SFX"
const UI: StringName = &"UI"

## Buses AudioManager adds if missing, in this order: a bus may only send to
## a bus before it, and UI sends to SFX.
const CREATED: Array[StringName] = [MUSIC, SFX, UI]
## Where each created bus sends. UI goes through SFX so the Effects volume
## also covers menu sounds.
const SENDS: Dictionary[StringName, StringName] = {
	MUSIC: MASTER,
	SFX: MASTER,
	UI: SFX,
}

## Buses the options screen exposes, with their default volume in percent.
const DEFAULT_VOLUMES: Dictionary[StringName, int] = {
	MASTER: 100,
	MUSIC: 70,
	SFX: 100,
}

const MAX_PERCENT: int = 100
## Effectively silent; the bus is also muted at 0%.
const SILENT_DB: float = -80.0


## Volume in decibels for a 0-100 percent setting. Percent is amplitude,
## so 50% is about -6 dB.
static func percent_to_db(percent: int) -> float:
	if percent <= 0:
		return SILENT_DB
	return linear_to_db(float(mini(percent, MAX_PERCENT)) / MAX_PERCENT)
