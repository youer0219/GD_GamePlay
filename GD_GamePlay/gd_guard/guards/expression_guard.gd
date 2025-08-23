class_name GD_ExpressionGuard
extends GD_Guard

## TODO:目前基本不可用。带研究明白后再处理。

@export_multiline var expression_string: String = ""

# 缓存已解析的表达式以提高性能
var _cached_expression: Expression
var _last_expression_string: String = ""

func is_satisfied(guard_group: GD_GuardGroup, context: Dictionary = {}) -> bool:
	if expression_string.is_empty():
		push_error("Expression string is empty in ExpressionGuard")
		return false
	
	# 如果需要，重新解析表达式
	if _last_expression_string != expression_string:
		_cached_expression = _parse_expression(expression_string)
		_last_expression_string = expression_string
	
	if _cached_expression == null:
		return false
	
	# 准备执行环境
	var execution_context = _prepare_execution_context(guard_group, context)
	
	# 执行表达式
	var result = _execute_expression(_cached_expression, execution_context)
	
	# 确保返回布尔值
	if result is bool:
		return result
	else:
		push_error("Expression did not return a boolean value: " + expression_string)
		return false

func _parse_expression(expr: String) -> Expression:
	var expression = Expression.new()
	var error = expression.parse(expr, [])
	
	if error != OK:
		push_error("Failed to parse expression: " + expr + "\nError: " + str(error))
		return null
	
	return expression

func _prepare_execution_context(guard_group: GD_GuardGroup, context: Dictionary) -> Dictionary:
	var execution_context = context.duplicate()
	
	# 添加 owner 的属性到执行上下文
	if guard_group.owner:
		# 获取所有可读属性
		var properties = guard_group.owner.get_property_list()
		for property in properties:
			var name = property["name"]
			# 跳过一些不需要的属性
			if name.begins_with("_") or name in ["script", "script_instance"]:
				continue
				
			# 只添加可读属性
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE or property["usage"] & PROPERTY_USAGE_STORAGE:
				if not execution_context.has(name):
					execution_context[name] = guard_group.owner.get(name)
	
	return execution_context

func _execute_expression(expression: Expression, context: Dictionary) -> Variant:
	# 将字典转换为参数数组（按字母顺序排序以确保一致性）
	var keys = context.keys()
	keys.sort()
	
	var args = []
	for key in keys:
		args.append(context[key])
	
	# 执行表达式
	var result = expression.execute(args, null, false)
	
	if expression.has_execute_failed():
		push_error("Expression execution failed: " + expression_string)
		return false
	
	return result

# 可选：添加一个方法来验证表达式语法
func is_expression_valid() -> bool:
	if expression_string.is_empty():
		return false
		
	var test_expression = Expression.new()
	var error = test_expression.parse(expression_string, [])
	
	return error == OK
