extends Node

# 自定义测试效果类 - 记录每个生命周期事件的触发次数
class Test_Buff extends GD_Buff:
	var awake_count := 0
	var start_count := 0
	var process_count := 0
	var remove_count := 0
	var stack_count := 0
	var layer_change_count := 0
	var interval_count := 0
	
	func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		awake_count += 1
	
	func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		start_count += 1
	
	func _on_buff_process(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _delta: float) -> void:
		process_count += 1
	
	func _on_buff_stack(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, new_buff: GD_Buff) -> void:
		super(container, runtime_buff, new_buff)
		stack_count += 1
	
	func _on_layer_change(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _new_buff: GD_Buff, _is_over: bool):
		layer_change_count += 1
	
	func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		remove_count += 1
	
	func get_duration() -> float:
		return default_duration

# 层叠测试效果
class Stack_Buff extends Test_Buff:
	func _init():
		stack_type = STACK_TYPE.STACK
		max_layers = 3

# 加时测试效果
class AddTime_Buff extends Test_Buff:
	func _init():
		stack_type = STACK_TYPE.ADD_TIME

# 刷新测试效果
class Refresh_Buff extends Test_Buff:
	func _init():
		stack_type = STACK_TYPE.REFRESH

# 唯一测试效果
class Unique_Buff extends Test_Buff:
	func _init():
		stack_type = STACK_TYPE.UNIQUE

# 优先级测试效果
class Priority_Buff extends Test_Buff:
	func _init():
		stack_type = STACK_TYPE.PRIORITY

# 冲突测试效果 - 与任何效果冲突
class Conflict_Buff extends Test_Buff:
	func conflicts_with(_other_buff: GD_Buff) -> bool:
		return true

# 创建基础效果（会与其他效果冲突）
class ConflictBase_Buff extends Test_Buff:
	func conflicts_with(other_buff: GD_Buff) -> bool:
		# 与特定类型的效果冲突
		return other_buff.buff_name == "Conflict_Buff"

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
	all_passed = test_stack_type_handling() and all_passed
	all_passed = test_buff_awake_and_start() and all_passed
	all_passed = test_layer_handling() and all_passed
	#all_passed = test_priority_handling() and all_passed
	all_passed = test_blackboard() and all_passed
	
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
	buff.default_duration = 2.0
	
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
	buff.default_duration = 2.0
	
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
	
	# 测试零持续时间buff
	var instant_buff = Instant_Buff.new()
	instant_buff.buff_name = "InstantTest"
	container.add_buff(instant_buff)
	container._physics_process(0.0)
	passed = print_result("零持续时间buff自动移除", instant_buff.remove_count == 1, "零持续时间buff未自动移除") and passed
	
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
	base_buff.default_duration = 2.0
	passed = print_result("添加基础buff", container.add_buff(base_buff), "应成功添加基础buff") and passed
	container._physics_process(0.0)  # 处理添加
	
	# 添加冲突buff (应被基础buff拒绝)
	var conflict_buff = Test_Buff.new()
	conflict_buff.buff_name = "Conflict_Buff"
	conflict_buff.default_duration = 2.0
	passed = print_result("添加冲突buff", !container.add_buff(conflict_buff), 
						 "冲突buff应被基础buff拒绝") and passed
	
	# 添加非冲突buff (应被接受)
	var safe_buff = Test_Buff.new()
	safe_buff.buff_name = "Safe_Buff"
	safe_buff.default_duration = 2.0
	passed = print_result("添加非冲突buff", container.add_buff(safe_buff), 
						 "非冲突buff应被添加") and passed
	
	# 验证非冲突buff已添加并激活
	container._physics_process(0.0)
	var safe_runtime = container.get_runtime_buff(safe_buff)
	passed = print_result("非冲突buff已激活", safe_runtime != null && safe_buff.start_count == 1, 
						 "非冲突buff未被激活") and passed
	
	container.queue_free()
	return passed

func test_stack_type_handling() -> bool:
	print("\n[测试堆叠类型处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 1. 测试REFRESH类型
	var refresh_buff = Refresh_Buff.new()
	refresh_buff.buff_name = "RefreshTest"
	refresh_buff.default_duration = 2.0
	passed = print_result("添加刷新buff", container.add_buff(refresh_buff), "应成功添加") and passed
	container._physics_process(0.0)
	
	var runtime = container.get_runtime_buff(refresh_buff)
	passed = print_result("初始持续时间", is_equal_approx(runtime.duration_time, 2.0), 
						 "初始持续时间应为2.0") and passed
	
	# 添加另一个刷新buff（应延长持续时间）
	var new_refresh_buff = Refresh_Buff.new()
	new_refresh_buff.buff_name = "RefreshTest"  # 相同名称才能刷新
	new_refresh_buff.default_duration = 3.0
	passed = print_result("添加另一个刷新buff", !container.add_buff(new_refresh_buff), "应返回false") and passed
	passed = print_result("stack回调", refresh_buff.stack_count == 1, "stack回调未触发") and passed
	passed = print_result("持续时间延长", is_equal_approx(runtime.duration_time, 3.0), 
						 "持续时间应延长至3.0") and passed
	
	container.remove_buff(refresh_buff)
	
	# 2. 测试ADD_TIME类型
	var addtime_buff = AddTime_Buff.new()
	addtime_buff.buff_name = "AddTimeTest"
	addtime_buff.default_duration = 1.0
	container.add_buff(addtime_buff)
	container._physics_process(0.0)
	runtime = container.get_runtime_buff(addtime_buff)
	
	# 添加另一个加时buff
	var new_addtime_buff = AddTime_Buff.new()
	new_addtime_buff.buff_name = "AddTimeTest"  # 相同名称才能加时
	new_addtime_buff.default_duration = 1.5
	container.add_buff(new_addtime_buff)
	container._physics_process(0.0)
	passed = print_result("加时持续时间", is_equal_approx(runtime.duration_time, 2.5), 
						 "持续时间应为1.0+1.5=2.5") and passed
	
	container.remove_buff(addtime_buff)
	
	# 3. 测试UNIQUE类型
	var unique_buff = Unique_Buff.new()
	unique_buff.buff_name = "UniqueTest"
	unique_buff.override_buff_name = "UniqueTest"
	unique_buff.default_duration = 2.0
	passed = print_result("添加唯一buff", container.add_buff(unique_buff), "应成功添加") and passed
	container._physics_process(0.0)
	
	var new_unique_buff = Unique_Buff.new()
	new_unique_buff.buff_name = "UniqueTest"
	new_unique_buff.override_buff_name = "UniqueTest"  # 修正变量名错误
	new_unique_buff.default_duration = 2.0
	passed = print_result("添加另一个唯一buff", !container.add_buff(new_unique_buff), "应返回false") and passed
	passed = print_result("唯一buff数量", container.runtime_buffs.size() == 1, "唯一buff应只有一个") and passed
	
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

func test_layer_handling() -> bool:
	print("\n[测试层数处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建层叠buff
	var stack_buff = Stack_Buff.new()
	stack_buff.buff_name = "LayerTest"
	stack_buff.default_duration = 5.0
	
	# 添加第一层
	passed = print_result("添加第一层", container.add_buff(stack_buff), "应成功添加") and passed
	container._physics_process(0.0)
	
	var runtime = container.get_runtime_buff(stack_buff)
	passed = print_result("初始层数", runtime.layer == 1, "初始层数应为1") and passed
	passed = print_result("层数变更回调", stack_buff.layer_change_count == 0, "初始添加不应触发层数变更") and passed
	
	# 添加第二层
	var stack_buff2 = Stack_Buff.new()
	stack_buff2.buff_name = "LayerTest"
	passed = print_result("添加第二层", !container.add_buff(stack_buff2), "应返回false") and passed
	container._physics_process(0.0)
	passed = print_result("层数增加", runtime.layer == 2, "层数应增加至2") and passed
	passed = print_result("层数变更回调触发", stack_buff.layer_change_count == 1, "层数变更回调未触发") and passed
	
	# 添加第三层（达到最大层数）
	var stack_buff3 = Stack_Buff.new()
	stack_buff3.buff_name = "LayerTest"
	container.add_buff(stack_buff3)
	container._physics_process(0.0)
	passed = print_result("最大层数", runtime.layer == 3, "层数应增加至3") and passed
	passed = print_result("层数变更回调", stack_buff.layer_change_count == 2, "层数变更回调未触发") and passed
	
	# 添加第四层（超过最大层数）
	var stack_buff4 = Stack_Buff.new()
	stack_buff4.buff_name = "LayerTest"
	container.add_buff(stack_buff4)
	container._physics_process(0.0)
	passed = print_result("超过最大层数", runtime.layer == 3, "层数不应超过3") and passed
	passed = print_result("层数变更回调(is_over)", stack_buff.layer_change_count == 3, "层数变更回调未触发") and passed
	
	container.queue_free()
	return passed

#func test_priority_handling() -> bool:
	#print("\n[测试优先级处理]")
	#var container = GD_BuffContainer.new()
	#add_child(container)
	#var passed = true
	#
	## 创建优先级buff
	#var priority_buff = Priority_Buff.new()
	#priority_buff.buff_name = "PriorityTest"
	#priority_buff.default_duration = 5.0
	#
	## 添加第一个
	#passed = print_result("添加第一个优先级buff", container.add_buff(priority_buff), "应成功添加") and passed
	#container._physics_process(0.0)
	#
	## 添加第二个（应该被添加）
	#var priority_buff2 = Priority_Buff.new()
	#priority_buff2.buff_name = "PriorityTest"
	#priority_buff2.default_duration = 3.0
	#passed = print_result("添加第二个优先级buff", container.add_buff(priority_buff2), "应成功添加") and passed
	#container._physics_process(0.0)
	#
	## 验证两个buff都存在
	#var buffs = container.get_runtime_buffs()
	#passed = print_result("两个优先级buff存在", buffs.size() == 2, "应存在两个优先级buff") and passed
	#passed = print_result("stack回调未触发", priority_buff.stack_count == 0, "优先级类型不应触发stack回调") and passed
	#
	#container.queue_free()
	#return passed

func test_blackboard() -> bool:
	print("\n[测试黑板功能]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建带黑板的buff
	var buff = Test_Buff.new()
	buff.buff_name = "BlackboardTest"
	buff.default_duration = 2.0
	buff.init_buff_blackboard = {"counter": 0, "message": "hello"}
	
	container.add_buff(buff)
	container._physics_process(0.0)
	
	var runtime = container.get_runtime_buff(buff)
	passed = print_result("黑板初始化", 
		runtime.blackboard.get("counter") == 0 and runtime.blackboard.get("message") == "hello",
		"黑板未正确初始化") and passed
	
	# 修改黑板值
	runtime.blackboard["counter"] = 5
	runtime.blackboard["message"] = "world"
	passed = print_result("黑板修改", 
		runtime.blackboard.get("counter") == 5 and runtime.blackboard.get("message") == "world",
		"黑板修改未保存") and passed
	
	container.queue_free()
	return passed
