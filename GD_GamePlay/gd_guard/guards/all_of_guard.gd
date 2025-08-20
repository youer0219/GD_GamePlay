class_name GD_AllOfGuard
extends GD_Guard

@export var guards:Array[GD_Guard] = [] 

func is_satisfied(context:Dictionary = {}) -> bool:
	for guard in guards:
		if not guard.is_satisfied(context):
			return false
	return true
