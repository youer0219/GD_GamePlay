class_name GD_AnyOfGuard
extends GD_Guard

@export var guards: Array[GD_Guard] = []

func is_satisfied(context:Dictionary = {}) -> bool:
	for guard in guards:
		if guard.is_satisfied(context):
			return true
	return false
