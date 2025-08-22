class_name GD_AnyOfGuard
extends GD_Guard

@export var guards: Array[GD_Guard] = []

func is_satisfied(guard_group:GD_GuardGroup,context:Dictionary = {}) -> bool:
	if guards.is_empty():
		push_error("No guards provided to AnyOfGuard")
		return false
	for guard in guards:
		if guard.is_satisfied(guard_group,context):
			return true
	return false
