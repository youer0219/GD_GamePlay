extends Resource
class_name GD_Guard

func is_satisfied(_guard_group:GD_GuardGroup,_context:Dictionary = {}) -> bool:
	## from Godot State Charts
	push_error("Guard.is_satisfied() is not implemented. Did you forget to override it?")
	return false
