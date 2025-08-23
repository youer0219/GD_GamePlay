class_name GD_AnyOfGuard
extends GD_LogicGuard

@export var guards: Array[GD_Guard] = []

func is_satisfied(context:Dictionary = {}) -> bool:
	if guards.is_empty():
		push_error("No guards provided to AnyOfGuard")
		return false
	for guard in guards:
		if guard.is_satisfied(context):
			return true
	return false
