# expression_guard.gd
class_name GD_ExpressionGuard
extends GD_Guard

@export_multiline var expression_string: String = ""

# 缓存已解析的表达式以提高性能
var _cached_expression: Expression
var _last_expression_string: String = ""

func is_satisfied(context: Dictionary = {}) -> bool:
	if expression_string.is_empty():
		push_error("Expression string is empty in ExpressionGuard")
		return false
	
	# 如果需要，重新解析表达式
	if _last_expression_string != expression_string:
		_cached_expression = _parse_expression(expression_string)
		_last_expression_string = expression_string
	
	if _cached_expression == null:
		return false
	
	# 执行表达式
	var result = _execute_expression(_cached_expression, context)
	
	# 确保返回布尔值
	if result is bool:
		return result
	else:
		push_error("Expression did not return a boolean value: " + expression_string)
		return false

func _parse_expression(expr: String) -> Expression:
	var expression = Expression.new()
	# 不预先定义变量名，让表达式自行解析
	var error = expression.parse(expr, [])
	
	if error != OK:
		push_error("Failed to parse expression: " + expr + "\nError: " + expression.get_error_text())
		return null
	
	return expression

func _execute_expression(expression: Expression, context: Dictionary) -> Variant:
	# 创建一个数组，包含所有上下文值（按字母顺序排序以确保一致性）
	var keys = context.keys()
	keys.sort()
	
	var args = []
	for key in keys:
		args.append(context[key])
	
	# 执行表达式
	var result = expression.execute(args, null, false)
	
	if expression.has_execute_failed():
		push_error("Expression execution failed: " + expression_string + "\nError: " + expression.get_error_text())
		return false
	
	return result

# 可选：添加一个方法来验证表达式语法
func is_expression_valid() -> bool:
	if expression_string.is_empty():
		return false
		
	var test_expression = Expression.new()
	var error = test_expression.parse(expression_string, [])
	
	return error == OK
