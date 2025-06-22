extends Node

# 自定义测试效果类 - 记录每个生命周期事件的触发次数
class Test_Buff extends GD_Buff:
	var awake_count := 0
	var start_count := 0
	var process_count := 0
	var remove_count := 0
	var refresh_count := 0
	var interval_count := 0
	
	func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		awake_count += 1
	
	func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		start_count += 1
	
	func _on_buff_process(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _delta: float) -> void:
		process_count += 1
	
	func _on_buff_refresh(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _new_buff: GD_Buff) -> void:
		refresh_count += 1
	
	func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		remove_count += 1
	
	func get_duration() -> float:
		return 2.0  # 2秒持续时间

# 冲突测试效果 - 与任何效果冲突
class Conflict_Buff extends Test_Buff:
	func conflicts_with(_other_buff: GD_Buff) -> bool:
		return true

# 创建基础效果（会与其他效果冲突）
class ConflictBase_Buff extends Test_Buff:
	func conflicts_with(other_buff: GD_Buff) -> bool:
		# 与特定类型的效果冲突
		return other_buff.buff_name == "Conflict_Buff"

# 堆叠测试效果 - 可与同类效果堆叠
class Stackable_Buff extends Test_Buff:
	func can_stack_with(other_buff: GD_Buff) -> bool:
		return other_buff.buff_name == self.buff_name

# 零持续时间效果 - 测试立即移除情况
class Instant_Buff extends Test_Buff:
	func get_duration() -> float:
		return 0.0
	
	func can_remove_buff(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> bool:
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
	
	print("\n===== 开始Buff系统测试 =====")
	all_passed = test_basic_lifecycle() and all_passed
	all_passed = test_duration_and_removal() and all_passed
	all_passed = test_conflict_handling() and all_passed
	all_passed = test_stack_handling() and all_passed
	all_passed = test_buff_awake_and_start() and all_passed
	
	if all_passed:
		print_rich("[color=green]===== 所有测试通过! =====[/color]")
	else:
		print_rich("[color=red]===== 测试失败! =====[/color]")

func test_basic_lifecycle() -> bool:
	print("\n[测试基础生命周期]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建测试buff
	var buff = Test_Buff.new()
	buff.buff_name = "LifecycleTest"
	
	# 测试添加buff
	passed = print_result("添加buff", container.add_buff(buff), "应成功添加buff") and passed
	
	# 模拟物理过程处理
	container._physics_process(0.0)
	
	# 获取并验证运行时buff实例
	var runtime = container.get_runtime_buff(buff)
	passed = print_result("运行时buff存在", runtime != null, "运行时buff实例应为非空") and passed
	passed = print_result("awake回调", buff.awake_count == 1, "awake回调未触发") and passed
	passed = print_result("start回调", buff.start_count == 1, "start回调未触发") and passed
	
	# 模拟过程调用
	container._physics_process(0.5)
	passed = print_result("process回调", buff.process_count >= 1, "process回调未触发") and passed
	
	# 测试移除buff
	passed = print_result("移除buff", container.remove_buff(buff), "移除buff失败") and passed
	passed = print_result("remove回调", buff.remove_count == 1, "remove回调未触发") and passed
	
	# 验证buff已被完全移除
	var removed_runtime = container.get_runtime_buff(buff)
	passed = print_result("移除后buff不存在", removed_runtime == null, "移除后运行时buff应为空") and passed
	
	container.queue_free()
	return passed

func test_duration_and_removal() -> bool:
	print("\n[测试持续时间与自动移除]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建带有持续时间的测试buff
	var buff = Test_Buff.new()
	buff.buff_name = "DurationTest"
	
	container.add_buff(buff)
	container._physics_process(0.0) # 处理添加
	
	# 模拟部分时间
	container._physics_process(1.0)
	
	# 验证buff仍在
	var runtime = container.get_runtime_buff(buff)
	passed = print_result("buff仍存在(1s)", runtime != null, "buff过早移除") and passed
	passed = print_result("持续时间更新(1s)", is_equal_approx(runtime.duration_time, 1.0), 
						 "持续时间更新错误") and passed
	
	# 模拟时间超过持续时间
	container._physics_process(1.5) 
	
	# 验证自动移除
	passed = print_result("自动触发移除", buff.remove_count == 1, "自动移除未触发") and passed
	passed = print_result("从容器移除", container.get_runtime_buff(buff) == null, "未从容器中移除") and passed
	
	container.queue_free()
	return passed

func test_conflict_handling() -> bool:
	print("\n[测试冲突处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 添加基础buff
	var base_buff = ConflictBase_Buff.new()
	base_buff.buff_name = "Base_Buff"
	passed = print_result("添加基础buff", container.add_buff(base_buff), "应成功添加基础buff") and passed
	container._physics_process(0.0)  # 处理添加
	
	# 添加冲突buff (应被基础buff拒绝)
	var conflict_buff = Test_Buff.new()
	conflict_buff.buff_name = "Conflict_Buff"
	passed = print_result("添加冲突buff", !container.add_buff(conflict_buff), 
						 "冲突buff应被基础buff拒绝") and passed
	
	# 添加非冲突buff (应被接受)
	var safe_buff = Test_Buff.new()
	safe_buff.buff_name = "Safe_Buff"
	passed = print_result("添加非冲突buff", container.add_buff(safe_buff), 
						 "非冲突buff应被添加") and passed
	
	# 验证非冲突buff已添加并激活
	container._physics_process(0.0)
	var safe_runtime = container.get_runtime_buff(safe_buff)
	passed = print_result("非冲突buff已激活", safe_runtime != null && safe_buff.start_count == 1, 
						 "非冲突buff未被激活") and passed
	
	container.queue_free()
	return passed

func test_stack_handling() -> bool:
	print("\n[测试堆叠处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 添加可堆叠buff
	var stackable_buff = Stackable_Buff.new()
	stackable_buff.buff_name = "Stackable"
	passed = print_result("添加堆叠buff", container.add_buff(stackable_buff), "应成功添加") and passed
	container._physics_process(0.0) # 处理添加
	
	# 添加相同类型的堆叠buff（应触发refresh）
	var same_buff = Stackable_Buff.new()
	same_buff.buff_name = "Stackable"
	passed = print_result("添加相同堆叠buff", !container.add_buff(same_buff), "堆叠buff应返回false") and passed
	passed = print_result("refresh回调", stackable_buff.refresh_count == 1, "refresh未触发") and passed
	
	# 验证原有效果未移除
	passed = print_result("原有效果未移除", container.get_runtime_buff(stackable_buff) != null, "不应移除原始效果") and passed
	
	container.queue_free()
	return passed

func test_buff_awake_and_start() -> bool:
	print("\n[测试awake/start分离]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建测试buff
	var buff = Test_Buff.new()
	buff.buff_name = "AwakeStartTest"
	
	# 添加buff（应在物理处理前只触发awake）
	container.add_buff(buff)
	passed = print_result("awake触发", buff.awake_count == 1, "awake应立刻触发") and passed
	passed = print_result("start未触发", buff.start_count == 0, "start应在物理处理时触发") and passed
	
	# 物理处理（应触发start）
	container._physics_process(0.0)
	passed = print_result("start触发", buff.start_count == 1, "start应在物理处理时触发") and passed
	
	container.queue_free()
	return passed
