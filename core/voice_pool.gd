class_name VoicePool
extends RefCounted
## Bookkeeping for a fixed pool of audio players: which one plays the next
## sound. An idle player is used first; when every player is busy, the one
## started longest ago is stolen, since the newest sound is usually the one
## that matters (a fresh hit beats the tail of an old one).
##
## Busy state is tracked here (acquire/release) instead of polling each
## player, so it never depends on audio-thread timing.

var _busy: Array[bool] = []
## Order each voice was last acquired in; lower is older.
var _started: PackedInt64Array = PackedInt64Array()
var _clock: int = 0


func _init(voice_count: int) -> void:
	_busy.resize(voice_count)
	_busy.fill(false)
	_started.resize(voice_count)
	_started.fill(0)


func size() -> int:
	return _busy.size()


func is_busy(index: int) -> bool:
	return _busy[index]


## Marks a voice busy and returns its index, or -1 for an empty pool.
func acquire() -> int:
	var count: int = _busy.size()
	if count == 0:
		return -1
	var chosen: int = _busy.find(false)
	if chosen < 0:
		chosen = 0
		for i: int in range(1, count):
			if _started[i] < _started[chosen]:
				chosen = i
	_clock += 1
	_busy[chosen] = true
	_started[chosen] = _clock
	return chosen


func release(index: int) -> void:
	if index >= 0 and index < _busy.size():
		_busy[index] = false
