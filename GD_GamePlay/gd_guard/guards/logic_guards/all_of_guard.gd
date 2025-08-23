class_name GD_AllOfGuard
extends GD_LogicGuard

@export var guards:Array[GD_Guard] = [] 

func is_satisfied(context:Dictionary = {}) -> bool:
	if guards.is_empty():
		push_error("No guards provided to AllOfGuard")
		return false
	for guard in guards:
		if not guard.is_satisfied(context):
			return false
	return true
