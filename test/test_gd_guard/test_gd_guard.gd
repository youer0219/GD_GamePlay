extends Node

# 自定义测试类 - 记录每个守卫的评估结果
class TestContext:
	var owner_property: int = 100
	var custom_value: String = "test_value"
	
	func get_owner_method() -> bool:
		return true

# 打印带颜色的测试结果
func print_result(test_name: String, passed: bool, details: String = "") -> bool:
	var color = "[color=green]" if passed else "[color=red]"
	var result = "PASSED" if passed else "FAILED"
	print_rich(color + test_name + ": " + result + "[/color]")
	if not passed and details != "":
		print_rich("[color=yellow]  → " + details + "[/color]")
	return passed

func _ready() -> void:
	run_guard_tests()
	queue_free()

func run_guard_tests() -> void:
	var all_passed = true
	
	print("\n===== 开始Guard系统测试 =====")
	all_passed = test_basic_expression_guard() and all_passed
	all_passed = test_expression_with_context() and all_passed
	all_passed = test_expression_with_owner() and all_passed
	all_passed = test_all_of_guard() and all_passed
	all_passed = test_any_of_guard() and all_passed
	all_passed = test_not_guard() and all_passed
	all_passed = test_complex_guard_combinations() and all_passed
	all_passed = test_error_handling() and all_passed
	all_passed = test_guard_group_evaluate() and all_passed
	
	if all_passed:
		print_rich("[color=green]===== 所有Guard测试通过! =====[/color]")
	else:
		print_rich("[color=red]===== Guard测试失败! =====[/color]")

# 测试基础表达式守卫
func test_basic_expression_guard() -> bool:
	var guard = GD_ExpressionGuard.new()
	guard.expression_string = "true"
	
	var result = guard.is_satisfied(GD_GuardGroup.new(), {})
	return print_result("基础表达式测试", result, "表达式 'true' 应该返回 true")

# 测试带上下文的表达式守卫
func test_expression_with_context() -> bool:
	var guard = GD_ExpressionGuard.new()
	guard.expression_string = "health > 50 and has_key"
	
	var context = {"health": 75, "has_key": true}
	var result = guard.is_satisfied(GD_GuardGroup.new(), context)
	return print_result("带上下文表达式测试", result, "表达式 'health > 50 and has_key' 应该返回 true")

# 测试带owner的表达式守卫
func test_expression_with_owner() -> bool:
	var guard = GD_ExpressionGuard.new()
	guard.expression_string = "owner_property > 50 and get_owner_method()"
	
	var test_context = TestContext.new()
	var guard_group = GD_GuardGroup.new()
	guard_group.owner = test_context
	
	var result = guard.is_satisfied(guard_group, {})
	return print_result("带Owner表达式测试", result, "表达式 'owner_property > 50 and get_owner_method()' 应该返回 true")

# 测试AllOf守卫
func test_all_of_guard() -> bool:
	# 创建两个总是返回true的表达式守卫
	var true_guard1 = GD_ExpressionGuard.new()
	true_guard1.expression_string = "true"
	
	var true_guard2 = GD_ExpressionGuard.new()
	true_guard2.expression_string = "1 == 1"
	
	# 创建一个AllOf守卫
	var all_guard = GD_AllOfGuard.new()
	all_guard.guards = [true_guard1, true_guard2] as Array[GD_Guard]
	
	var result = all_guard.is_satisfied(GD_GuardGroup.new(), {})
	return print_result("AllOf守卫测试", result, "两个true守卫的AllOf应该返回 true")

# 测试AnyOf守卫
func test_any_of_guard() -> bool:
	# 创建一个true和一个false表达式守卫
	var true_guard = GD_ExpressionGuard.new()
	true_guard.expression_string = "true"
	
	var false_guard = GD_ExpressionGuard.new()
	false_guard.expression_string = "false"
	
	# 创建一个AnyOf守卫
	var any_guard = GD_AnyOfGuard.new()
	any_guard.guards = [true_guard, false_guard] as Array[GD_Guard]
	
	var result = any_guard.is_satisfied(GD_GuardGroup.new(), {})
	return print_result("AnyOf守卫测试", result, "一个true和一个false守卫的AnyOf应该返回 true")

# 测试Not守卫
func test_not_guard() -> bool:
	var false_guard = GD_ExpressionGuard.new()
	false_guard.expression_string = "false"
	
	var not_guard = GD_NotGuard.new()
	not_guard.guard = false_guard
	
	var result = not_guard.is_satisfied(GD_GuardGroup.new(), {})
	return print_result("Not守卫测试", result, "Not false应该返回 true")

# 测试复杂守卫组合
func test_complex_guard_combinations() -> bool:
	# 创建几个表达式守卫
	var health_guard = GD_ExpressionGuard.new()
	health_guard.expression_string = "health > 50"
	
	var mana_guard = GD_ExpressionGuard.new()
	mana_guard.expression_string = "mana > 20"
	
	var has_key_guard = GD_ExpressionGuard.new()
	has_key_guard.expression_string = "has_key"
	
	# 创建组合: (health > 50 AND mana > 20) OR has_key
	var health_and_mana = GD_AllOfGuard.new()
	health_and_mana.guards = [health_guard, mana_guard] as Array[GD_Guard]
	
	var final_guard = GD_AnyOfGuard.new()
	final_guard.guards = [health_and_mana, has_key_guard] as Array[GD_Guard]
	
	# 测试场景1: 健康高、魔法低、有钥匙
	var context1 = {"health": 75, "mana": 10, "has_key": true}
	var result1 = final_guard.is_satisfied(GD_GuardGroup.new(), context1)
	
	# 测试场景2: 健康低、魔法低、无钥匙
	var context2 = {"health": 30, "mana": 10, "has_key": false}
	var result2 = final_guard.is_satisfied(GD_GuardGroup.new(), context2)
	
	return print_result("复杂守卫组合测试", result1 and not result2, 
		"场景1应该返回true, 场景2应该返回false")

# 测试错误处理
func test_error_handling() -> bool:
	var passed = true
	
	# 测试空表达式
	var empty_guard = GD_ExpressionGuard.new()
	empty_guard.expression_string = ""
	var result1 = empty_guard.is_satisfied(GD_GuardGroup.new(), {})
	passed = passed and not result1
	
	# 测试无效表达式
	var invalid_guard = GD_ExpressionGuard.new()
	invalid_guard.expression_string = "this is not valid code"
	var result2 = invalid_guard.is_satisfied(GD_GuardGroup.new(), {})
	passed = passed and not result2
	
	# 测试空AllOf守卫
	var empty_all_guard = GD_AllOfGuard.new()
	var result3 = empty_all_guard.is_satisfied(GD_GuardGroup.new(), {})
	passed = passed and not result3
	
	# 测试空AnyOf守卫
	var empty_any_guard = GD_AnyOfGuard.new()
	var result4 = empty_any_guard.is_satisfied(GD_GuardGroup.new(), {})
	passed = passed and not result4
	
	# 测试空Not守卫
	var empty_not_guard = GD_NotGuard.new()
	var result5 = empty_not_guard.is_satisfied(GD_GuardGroup.new(), {})
	passed = passed and result5  # 空Not守卫应该返回true
	
	return print_result("错误处理测试", passed, "各种错误情况应该被正确处理")

# 测试GuardGroup的便捷方法
func test_guard_group_evaluate() -> bool:
	var guard = GD_ExpressionGuard.new()
	guard.expression_string = "value > 10"
	
	var context = {"value": 15}
	var test_owner = TestContext.new()
	
	var result = GD_GuardGroup.evaluate(guard, test_owner, context)
	return print_result("GuardGroup便捷方法测试", result, "表达式 'value > 10' 应该返回 true")
