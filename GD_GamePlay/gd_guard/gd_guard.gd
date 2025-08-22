extends Resource
class_name GD_Guard

func is_satisfied(_guard_group:GD_GuardGroup,_context:Dictionary = {}) -> bool:
	## from Godot State Charts
	push_error("Guard.is_satisfied() is not implemented. Did you forget to override it?")
	return false

## TODO:未来使用还不确定。或许会有一个system来集中管理这些guard，而非单纯一个guard？
