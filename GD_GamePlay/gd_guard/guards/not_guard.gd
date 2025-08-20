class_name GD_NotGuard
extends GD_Guard

@export var guard: GD_Guard

func is_satisfied(context:Dictionary = {})->bool:
	if guard == null:
		return true
	return not guard.is_satisfied(context)
