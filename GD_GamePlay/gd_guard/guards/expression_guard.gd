class_name GD_ExpressionGuard
extends GD_Guard

@export_multiline var expression_string: String = ""

# 缓存表达式及内容哈希
var _cached_expression: Expression
var _last_expression_hash: int = 0

func is_satisfied(context: Dictionary = {}) -> bool:
	if expression_string.is_empty():
		push_error("Expression string is empty")
		return false
	
	# 计算当前表达式哈希值
	var current_hash = expression_string.hash()
	
	# 仅当表达式内容变化时重新解析
	if _cached_expression == null || _last_expression_hash != current_hash:
		# 提取并排序变量名（确保参数顺序一致性）
		var variable_names = context.keys()
		variable_names.sort()
		
		_cached_expression = _parse_expression(expression_string, variable_names)
		_last_expression_hash = current_hash
	
	if _cached_expression == null:
		return false
	
	# 执行表达式（变量名顺序需与解析时一致）
	var result = _execute_expression(_cached_expression, context)
	return result if result is bool else false

func _parse_expression(expr: String, variable_names: PackedStringArray) -> Expression:
	var expression = Expression.new()
	if expression.parse(expr, variable_names) != OK:  # 关键：解析时传入变量名
		push_error("Parse failed: " + expression.get_error_text())
		return null
	return expression

func _execute_expression(expression: Expression, context: Dictionary) -> Variant:
	# 按字母顺序构建参数数组（与解析时顺序一致）
	var keys = context.keys()
	keys.sort()
	var args = keys.map(func(key): return context[key])
	
	var result = expression.execute(args, null, false)
	if expression.has_execute_failed():
		push_error("Execute failed: " + expression.get_error_text())
		return false
	return result
