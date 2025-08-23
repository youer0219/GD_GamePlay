extends Resource
class_name GD_GuardGroup

const OWNER_STR := &"owner"
const ARRAY_ELEMENT_STR := &"array_element"
const ARRAY_FIRST_ELEMENT_STR := &"array_first_element"
const ARRAY_SECOND_ELEMENT_STR := &"array_second_element"

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
	context[OWNER_STR] = owner
	return init_guard.is_satisfied(context.duplicate())

# 用于数组遍历的方法
func array_traversal(array_element:Object)->bool:
	context[ARRAY_ELEMENT_STR] = array_element
	return is_satisfied()

# 用于数组排序的方法
func array_sort(first_element:Object,second_element:Object)->bool:
	context[ARRAY_FIRST_ELEMENT_STR] = first_element
	context[ARRAY_SECOND_ELEMENT_STR] = second_element
	return is_satisfied()

# 添加一个便捷方法用于快速检查多个条件
static func evaluate(guard_to_check: GD_Guard, owner_node: Object, extra_context: Dictionary = {}) -> bool:
	var group = GD_GuardGroup.new()
	group.owner = owner_node
	group.context = extra_context
	group.init_guard = guard_to_check
	return group.is_satisfied()
