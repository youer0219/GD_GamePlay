class_name GD_AllOfGuard
extends GD_LogicGuard

@export var guards:Array[GD_Guard] = [] 

func is_satisfied(guard_group:GD_GuardGroup,context:Dictionary = {}) -> bool:
	if guards.is_empty():
		push_error("No guards provided to AllOfGuard")
		return false
	for guard in guards:
		if not guard.is_satisfied(guard_group,context):
			return false
	return true
