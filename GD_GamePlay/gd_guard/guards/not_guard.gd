class_name GD_NotGuard
extends GD_Guard

@export var guard: GD_Guard

func is_satisfied(guard_group:GD_GuardGroup,context:Dictionary = {})->bool:
	if guard == null:
		push_error("No guard provided to NotGuard")
		return true
	return not guard.is_satisfied(guard_group,context)
