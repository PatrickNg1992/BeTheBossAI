extends Node

## Pending-Notification autoload. Holds at most one pending Notification,
## stored as a localization key. The Menu consumes the slot on entry and
## clears it. Multiplayer flows call set_pending() before switching here.

var _pending: String = ""


func set_pending(key: String) -> void:
	_pending = key


## Returns the stored key and clears the slot, so a Notification shows
## exactly once.
func take_pending() -> String:
	var key := _pending
	_pending = ""
	return key
