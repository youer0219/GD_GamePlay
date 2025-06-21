extends Node

# 自定义测试效果类
class TestEffect extends Effect:
	var apply_count := 0
	var active_count := 0
	var remove_count := 0
	var tick_count := 0
	var stack_count := 0
	
	func _on_apply(_c, _r) -> void:
		apply_count += 1
	
	func _on_active(_c, _r) -> void:
		active_count += 1
	
	func _on_stack(_c, _r) -> void:
		stack_count += 1
	
	func _on_remove(_c, _r) -> void:
		remove_count += 1
	
	func _on_tick(_c, _r, _d) -> void:
		tick_count += 1
	
	func get_duration() -> float:
		return 2.0  # 2秒持续时间

# 非自动激活效果类
class NonAutoActivateEffect extends TestEffect:
	func should_active_in_addition() -> bool:
		return false

# 创建会与特定效果冲突的基础效果
class ConflictBaseEffect extends TestEffect:
	func conflicts_with(other_effect: Effect) -> bool:
		return other_effect.effect_name == "ConflictEffect"

# 创建允许堆叠的基础效果
class StackableBaseEffect extends TestEffect:
	func can_stack_with(other_effect: Effect) -> bool:
		return other_effect.effect_name == "StackableEffect"

# 辅助函数：打印带颜色的测试结果
func print_result(test_name: String, passed: bool, details: String = "") -> bool:
	var color = "[color=green]" if passed else "[color=red]"
	var result = "PASSED" if passed else "FAILED"
	print_rich(color + test_name + ": " + result + "[/color]")
	if not passed and details != "":
		print_rich("[color=yellow]  → " + details + "[/color]")
	return passed

func _ready() -> void:
	run_tests()
	queue_free()

func run_tests() -> void:
	var all_passed = true
	
	print("\n===== 开始效果系统测试 =====")
	all_passed = test_basic_lifecycle() and all_passed
	all_passed = test_auto_removal() and all_passed
	all_passed = test_conflict_handling() and all_passed
	all_passed = test_state_transitions() and all_passed
	
	if all_passed:
		print_rich("[color=green]===== 所有测试通过! =====[/color]")
	else:
		print_rich("[color=red]===== 测试失败! =====[/color]")

func test_basic_lifecycle() -> bool:
	print("\n[测试基础生命周期]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	var effect = TestEffect.new()
	effect.effect_name = "TestEffect"
	
	# 测试添加效果
	passed = print_result("添加效果", container.add_effect(effect), "应成功添加效果") and passed
	passed = print_result("应用回调", effect.apply_count == 1, "应用回调未触发") and passed
	
	# 测试状态转换
	var runtime = container.get_runtime_effect(effect)
	passed = print_result("自动激活", runtime.state == RuntimeEffect.State.ACTIVE, "未自动激活") and passed
	passed = print_result("激活回调", effect.active_count == 1, "激活回调未触发") and passed
	
	# 测试tick处理
	runtime.handle_tick(0.5)
	passed = print_result("tick回调", effect.tick_count == 1, "tick回调未触发") and passed
	
	# 测试手动移除
	passed = print_result("移除效果", container.remove_effect(effect), "移除效果失败") and passed
	passed = print_result("移除回调", effect.remove_count == 1, "移除回调未触发") and passed
	passed = print_result("移除状态", runtime.state == RuntimeEffect.State.REMOVED, "状态未更新为REMOVED") and passed
	
	container.queue_free()
	return passed

func test_auto_removal() -> bool:
	print("\n[测试自动移除]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	var effect = TestEffect.new()
	effect.effect_name = "AutoRemoveEffect"
	
	container.add_effect(effect)
	var runtime = container.get_runtime_effect(effect)
	
	# 模拟时间流逝（超过持续时间）
	runtime.handle_tick(1.0)
	runtime.handle_tick(1.5)  # 应触发移除
	
	passed = print_result("自动移除状态", runtime.state == RuntimeEffect.State.REMOVED, "未自动移除") and passed
	passed = print_result("移除回调", effect.remove_count == 1, "移除回调未触发") and passed
	passed = print_result("tick次数", effect.tick_count == 1, "应为1次tick (实际: {0})".format([effect.tick_count])) and passed
	
	container.queue_free()
	return passed

func test_conflict_handling() -> bool:
	print("\n[测试冲突处理]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	# 添加基础效果
	var base_effect = ConflictBaseEffect.new()
	base_effect.effect_name = "BaseEffect"
	passed = print_result("添加基础效果", container.add_effect(base_effect), 
						 "应成功添加基础效果") and passed
	
	# 添加冲突效果
	var conflict_effect = TestEffect.new()
	conflict_effect.effect_name = "ConflictEffect"
	passed = print_result("冲突效果添加", !container.add_effect(conflict_effect), 
						 "冲突效果不应被添加") and passed
	
	# 添加不冲突的效果
	var non_conflict_effect = TestEffect.new()
	non_conflict_effect.effect_name = "NonConflictEffect"
	passed = print_result("不冲突效果添加", container.add_effect(non_conflict_effect), 
						 "不冲突效果应被添加") and passed
	
	# 替换基础效果为可堆叠版本
	container.remove_effect(base_effect)
	base_effect = StackableBaseEffect.new()
	base_effect.effect_name = "BaseEffect"
	container.add_effect(base_effect)
	
	# 添加堆叠效果
	var stackable_effect = TestEffect.new()
	stackable_effect.effect_name = "StackableEffect"
	container.add_effect(stackable_effect) # 成功叠加后依然返回false
	# 检查堆叠回调
	passed = print_result("堆叠回调", base_effect.stack_count == 1, 
						 "堆叠回调未触发 (实际: %d)" % base_effect.stack_count) and passed
	
	# 添加不可堆叠的效果
	var non_stackable_effect = TestEffect.new()
	non_stackable_effect.effect_name = "NonStackableEffect"
	passed = print_result("不可堆叠效果添加", container.add_effect(non_stackable_effect), 
						 "不可堆叠效果应作为新效果添加") and passed
	
	# 检查是否创建了新效果实例
	var runtime_effect = container.get_runtime_effect(non_stackable_effect)
	passed = print_result("新效果实例", runtime_effect != null, 
						 "应创建新效果实例") and passed
	
	container.queue_free()
	return passed
func test_state_transitions() -> bool:
	print("\n[测试状态转换]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	var effect = NonAutoActivateEffect.new()
	effect.effect_name = "StateEffect"
	
	container.add_effect(effect)
	var runtime = container.get_runtime_effect(effect)
	
	# 验证初始状态
	passed = print_result("初始状态", runtime.state == RuntimeEffect.State.APPLIED, "应保持在APPLIED状态") and passed
	
	# 测试激活
	runtime.activate()
	passed = print_result("激活状态", runtime.state == RuntimeEffect.State.ACTIVE, "激活失败") and passed
	passed = print_result("激活回调", effect.active_count == 1, "激活回调未触发") and passed
	
	# 测试无效状态转换
	runtime.activate()
	passed = print_result("重复激活", runtime.state == RuntimeEffect.State.ACTIVE, "重复激活不应改变状态") and passed
	
	# 测试直接移除
	runtime.remove()
	passed = print_result("移除状态", runtime.state == RuntimeEffect.State.REMOVED, "移除失败") and passed
	
	container.queue_free()
	return passed
