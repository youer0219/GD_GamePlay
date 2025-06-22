extends Node

# 自定义测试效果类 - 记录每个生命周期事件的触发次数
class TestEffect extends Effect:
	var awake_count := 0
	var start_count := 0
	var process_count := 0
	var remove_count := 0
	var refresh_count := 0
	var interval_count := 0
	
	func _on_effect_awake(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
		awake_count += 1
	
	func _on_effect_start(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
		start_count += 1
	
	func _on_effect_process(_container: EffectContainer, _runtime_effect: RuntimeEffect, _delta: float) -> void:
		process_count += 1
	
	func _on_effect_refresh(_container: EffectContainer, _runtime_effect: RuntimeEffect, _new_effect:Effect) -> void:
		refresh_count += 1
	
	func _on_effect_remove(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
		remove_count += 1
	
	func get_duration() -> float:
		return 2.0  # 2秒持续时间

# 冲突测试效果 - 与任何效果冲突
class ConflictEffect extends TestEffect:
	func conflicts_with(_other_effect: Effect) -> bool:
		return true

# 创建基础效果（会与其他效果冲突）
class ConflictBaseEffect extends TestEffect:
	func conflicts_with(other_effect: Effect) -> bool:
		# 与特定类型的效果冲突
		return other_effect.effect_name == "ConflictEffect"

# 堆叠测试效果 - 可与同类效果堆叠
class StackableEffect extends TestEffect:
	func can_stack_with(other_effect: Effect) -> bool:
		return other_effect.effect_name == self.effect_name

# 零持续时间效果 - 测试立即移除情况
class InstantEffect extends TestEffect:
	func get_duration() -> float:
		return 0.0
	
	func can_remove_effect(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> bool:
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
	run_tests()
	queue_free()

func run_tests() -> void:
	var all_passed = true
	
	print("\n===== 开始效果系统测试 =====")
	all_passed = test_basic_lifecycle() and all_passed
	all_passed = test_duration_and_removal() and all_passed
	all_passed = test_conflict_handling() and all_passed
	all_passed = test_stack_handling() and all_passed
	all_passed = test_effect_awake_and_start() and all_passed
	
	if all_passed:
		print_rich("[color=green]===== 所有测试通过! =====[/color]")
	else:
		print_rich("[color=red]===== 测试失败! =====[/color]")

func test_basic_lifecycle() -> bool:
	print("\n[测试基础生命周期]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	# 创建测试效果
	var effect = TestEffect.new()
	effect.effect_name = "LifecycleTest"
	
	# 测试添加效果
	passed = print_result("添加效果", container.add_effect(effect), "应成功添加效果") and passed
	
	# 模拟物理过程处理
	container._physics_process(0.0)
	
	# 获取并验证运行时效果实例
	var runtime = container.get_runtime_effect(effect)
	passed = print_result("运行时效果存在", runtime != null, "运行时效果实例应为非空") and passed
	passed = print_result("awake回调", effect.awake_count == 1, "awake回调未触发") and passed
	passed = print_result("start回调", effect.start_count == 1, "start回调未触发") and passed
	
	# 模拟过程调用
	container._physics_process(0.5)
	passed = print_result("process回调", effect.process_count >= 1, "process回调未触发") and passed
	
	# 测试移除效果
	passed = print_result("移除效果", container.remove_effect(effect), "移除效果失败") and passed
	passed = print_result("remove回调", effect.remove_count == 1, "remove回调未触发") and passed
	
	# 验证效果已被完全移除
	var removed_runtime = container.get_runtime_effect(effect)
	passed = print_result("移除后效果不存在", removed_runtime == null, "移除后运行时效果应为空") and passed
	
	container.queue_free()
	return passed

func test_duration_and_removal() -> bool:
	print("\n[测试持续时间与自动移除]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	# 创建带有持续时间的测试效果
	var effect = TestEffect.new()
	effect.effect_name = "DurationTest"
	
	container.add_effect(effect)
	container._physics_process(0.0) # 处理添加
	
	# 模拟部分时间
	container._physics_process(1.0)
	
	# 验证效果仍在
	var runtime = container.get_runtime_effect(effect)
	passed = print_result("效果仍存在(1s)", runtime != null, "效果过早移除") and passed
	passed = print_result("持续时间更新(1s)", is_equal_approx(runtime.duration_time, 1.0), 
						 "持续时间更新错误") and passed
	
	# 模拟时间超过持续时间
	container._physics_process(1.5) 
	
	# 验证自动移除
	passed = print_result("自动触发移除", effect.remove_count == 1, "自动移除未触发") and passed
	passed = print_result("从容器移除", container.get_runtime_effect(effect) == null, "未从容器中移除") and passed
	
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
	passed = print_result("添加基础效果", container.add_effect(base_effect), "应成功添加基础效果") and passed
	container._physics_process(0.0)  # 处理添加
	
	# 添加冲突效果 (应被基础效果拒绝)
	var conflict_effect = TestEffect.new()
	conflict_effect.effect_name = "ConflictEffect"
	passed = print_result("添加冲突效果", !container.add_effect(conflict_effect), 
						 "冲突效果应被基础效果拒绝") and passed
	
	# 添加非冲突效果 (应被接受)
	var safe_effect = TestEffect.new()
	safe_effect.effect_name = "SafeEffect"
	passed = print_result("添加非冲突效果", container.add_effect(safe_effect), 
						 "非冲突效果应被添加") and passed
	
	# 验证非冲突效果已添加并激活
	container._physics_process(0.0)
	var safe_runtime = container.get_runtime_effect(safe_effect)
	passed = print_result("非冲突效果已激活", safe_runtime != null && safe_effect.start_count == 1, 
						 "非冲突效果未被激活") and passed
	
	container.queue_free()
	return passed

func test_stack_handling() -> bool:
	print("\n[测试堆叠处理]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	# 添加可堆叠效果
	var stackable_effect = StackableEffect.new()
	stackable_effect.effect_name = "Stackable"
	passed = print_result("添加堆叠效果", container.add_effect(stackable_effect), "应成功添加") and passed
	container._physics_process(0.0) # 处理添加
	
	# 添加相同类型的堆叠效果（应触发refresh）
	var same_effect = StackableEffect.new()
	same_effect.effect_name = "Stackable"
	passed = print_result("添加相同堆叠效果", !container.add_effect(same_effect), "堆叠效果应返回false") and passed
	passed = print_result("refresh回调", stackable_effect.refresh_count == 1, "refresh未触发") and passed
	
	# 验证原有效果未移除
	passed = print_result("原有效果未移除", container.get_runtime_effect(stackable_effect) != null, "不应移除原始效果") and passed
	
	container.queue_free()
	return passed

func test_effect_awake_and_start() -> bool:
	print("\n[测试awake/start分离]")
	var container = EffectContainer.new()
	add_child(container)
	var passed = true
	
	# 创建测试效果
	var effect = TestEffect.new()
	effect.effect_name = "AwakeStartTest"
	
	# 添加效果（应在物理处理前只触发awake）
	container.add_effect(effect)
	passed = print_result("awake触发", effect.awake_count == 1, "awake应立刻触发") and passed
	passed = print_result("start未触发", effect.start_count == 0, "start应在物理处理时触发") and passed
	
	# 物理处理（应触发start）
	container._physics_process(0.0)
	passed = print_result("start触发", effect.start_count == 1, "start应在物理处理时触发") and passed
	
	container.queue_free()
	return passed
