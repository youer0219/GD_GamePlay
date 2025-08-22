extends Resource
class_name GD_GuardGroup

## TODO:是否应该为node？
var owner:Object
@export var context:Dictionary
@export var init_guard:GD_Guard

func _init(group_owner:Object = null) -> void:
	owner = group_owner

func is_satisfied()->bool:
	if not init_guard:
		push_error("No initial guard set in GuardGroup")
		return false
	return init_guard.is_satisfied(self,context)

# 添加一个便捷方法用于快速检查多个条件
static func evaluate(guard_to_check: GD_Guard, owner_node: Object, extra_context: Dictionary = {}) -> bool:
	var group = GD_GuardGroup.new()
	group.owner = owner_node
	group.context = extra_context
	group.init_guard = guard_to_check
	return group.is_satisfied()
