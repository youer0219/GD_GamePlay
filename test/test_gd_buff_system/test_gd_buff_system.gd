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
	
	func _on_buff_start(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff) -> void:
		super(container,runtime_buff)
		start_count += 1
	
	func _on_buff_process(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, delta: float) -> void:
		super(container,runtime_buff,delta)
		process_count += 1
	
	func _on_buff_stack(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, new_runtime_buff: GD_RuntimeBuff) -> void:
		super(container, runtime_buff, new_runtime_buff)
		stack_count += 1
	
	func _on_stack_layer_change(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _new_runtime_buff: GD_RuntimeBuff, _is_over: bool):
		layer_change_count += 1
	
	func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		remove_count += 1
	
	func _on_buff_interval_trigger(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
		interval_count += 1

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
	func get_duration(_container) -> float:
		return 0.0

	func can_remove_buff(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> bool:
		return true

class ManualInitBuff extends Test_Buff:
	func _on_buff_awake(_container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff) -> void:
		super(_container, runtime_buff)
		#// 在awake阶段手动初始化黑板
		runtime_buff.blackboard["manual_init_key"] = "manual_init_value"
		runtime_buff.blackboard["counter"] = 42 # 甚至可以覆盖Context


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
	all_passed = test_blackboard() and all_passed
	all_passed = test_priority_handling() and all_passed
	all_passed = test_interval_processing() and all_passed
	all_passed = test_buff_factory() and all_passed
	all_passed = test_instantiate_global_class() and all_passed
	
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
	var runtime = container.get_runtime_buff(buff)
	passed = print_result("验证buff成功添加后本帧内状态", runtime.state == GD_RuntimeBuff.BUFF_STATE.AWAKE, "应该为AWAKE状态") and passed
	passed = print_result("buff添加后本帧内状态默认不生效", !runtime.enable, "不应生效") and passed
	# 模拟物理过程处理
	container._physics_process(0.0)
	
	# 验证运行时buff实例
	passed = print_result("运行时buff存在", runtime != null, "运行时buff实例应为非空") and passed
	passed = print_result("awake回调", buff.awake_count == 1, "awake回调未触发") and passed
	passed = print_result("start回调", buff.start_count == 1, "start回调未触发") and passed
	passed = print_result("验证buff添加后状态", runtime.state == GD_RuntimeBuff.BUFF_STATE.EXIST, "应该为EXIST状态") and passed
	passed = print_result("buff添加后状态自动生效", runtime.enable, "应生效") and passed
	# 模拟过程调用
	container._physics_process(0.5)
	passed = print_result("process回调", buff.process_count >= 1, "process回调未触发") and passed
	
	# 测试移除buff
	passed = print_result("移除buff", container.remove_buff(buff), "移除buff失败") and passed
	passed = print_result("remove回调", buff.remove_count == 1, "remove回调未触发") and passed
	
	# 验证buff已被完全移除
	var removed_runtime = container.get_runtime_buff(buff)
	passed = print_result("移除后buff不存在", removed_runtime == null, "移除后运行时buff应为空") and passed
	passed = print_result("移除buff后buff自动失效", !runtime.enable, "应失效") and passed
	passed = print_result("验证buff添加后状态", runtime.state == GD_RuntimeBuff.BUFF_STATE.REMOVE, "应该为REMOVE状态") and passed
	
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
	
	# 测试持续时间流速机制
	var new_buff = Test_Buff.new()
	buff.buff_name = "RateDurationTest"
	buff.default_duration = 2.0
	container.add_buff(new_buff)
	runtime = container.get_runtime_buff(new_buff)
	runtime.duration_time_flow_rate = 2.0
	container._physics_process(1.0)
	passed = print_result("持续时间流速翻倍，2sbuff在1s后被移除", container.get_runtime_buff(new_buff) == null, "未从容器中移除") and passed
	
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
	new_addtime_buff.buff_name = "AddTimeTest"
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
	new_unique_buff.override_buff_name = "UniqueTest" 
	new_unique_buff.default_duration = 2.0
	passed = print_result("添加另一个唯一buff", !container.add_buff(new_unique_buff), "应返回false") and passed
	passed = print_result("唯一buff数量", container.runtime_buffs.size() == 1, "唯一buff应只有一个") and passed
	
	container.remove_buff(unique_buff)
	
	# 4. 测试is_disable_override功能
	var stake_buff = Stack_Buff.new()
	stake_buff.buff_name = "AAAA"
	stake_buff.default_duration = 1.0
	stake_buff.is_disable_override = true
	container.add_buff(stake_buff)
	var new_stake_buff = Stack_Buff.new()
	new_stake_buff.buff_name = "XXXX"
	new_stake_buff.override_buff_name = stake_buff.buff_name
	new_stake_buff.default_duration = 1.0
	container.add_buff(new_stake_buff) 
	container._physics_process(0.0) # 不进行这一步，就要改为检查pending-add-buffs了
	passed = print_result("buff数量应该是两个", container.runtime_buffs.size() == 2, "两个buff无法叠加应该都会存在") and passed
	
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
	
	# 测试时间耗尽时消耗层数刷新时间
	print("[测试时间耗尽层数刷新]")
	# 添加三层buff
	container.add_buff(stack_buff)
	container.add_buff(stack_buff2)
	container.add_buff(stack_buff3)
	container._physics_process(0.0)
	
	# 初始层数应为3
	runtime = container.get_runtime_buff(stack_buff)
	passed = print_result("初始层数(3)", runtime.layer == 3, "初始层数应为3") and passed
	
	# 模拟时间耗尽
	container._physics_process(5.1)  # 超过持续时间
	
	# 验证层数减少和时间重置
	passed = print_result("时间耗尽后层数减少", runtime.layer == 2, "层数应减少至2") and passed
	passed = print_result("持续时间重置", is_equal_approx(runtime.duration_time, 5.0), 
						 "持续时间应重置为5.0") and passed
	
	# 再次耗尽时间
	container._physics_process(5.1)
	passed = print_result("第二次时间耗尽层数减少", runtime.layer == 1, "层数应减少至1") and passed
	
	# 最后一次耗尽时间
	container._physics_process(5.1)
	passed = print_result("层数耗尽后buff移除", container.get_runtime_buff(stack_buff) == null, 
						 "层数耗尽后buff应被移除") and passed
	
	container.queue_free()
	return passed

func test_priority_handling() -> bool:
	print("\n[测试优先级处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 创建不同优先级的buff
	var high_priority = Priority_Buff.new()
	high_priority.buff_name = "HighPriority"
	high_priority.override_buff_name = "PriorityBuff"
	high_priority.default_priority = 10
	high_priority.default_duration = 5.0
	
	var medium_priority = Priority_Buff.new()
	medium_priority.buff_name = "MediumPriority"
	medium_priority.override_buff_name = "PriorityBuff"
	medium_priority.default_priority = 5
	medium_priority.default_duration = 5.0
	
	var low_priority = Priority_Buff.new()
	low_priority.buff_name = "LowPriority"
	low_priority.override_buff_name = "PriorityBuff"
	low_priority.default_priority = 1
	low_priority.default_duration = 5.0
	
	# 1. 添加低优先级buff
	passed = print_result("添加低优先级buff", container.add_buff(low_priority), "应成功添加") and passed
	container._physics_process(0.0)
	var low_runtime = container.get_runtime_buff(low_priority)
	passed = print_result("低优先级启用状态", low_runtime.enable, "初始应启用") and passed
	
	# 2. 添加高优先级buff
	passed = print_result("添加高优先级buff", container.add_buff(high_priority), "应成功添加") and passed
	container._physics_process(0.0)
	var high_runtime = container.get_runtime_buff(high_priority)
	
	# 验证状态变化
	passed = print_result("高优先级启用", high_runtime.enable, "高优先级应启用") and passed
	passed = print_result("低优先级禁用", !low_runtime.enable, "低优先级应禁用") and passed
	passed = print_result("低优先级higher_buff_num", low_runtime.higher_buff_num == 1, "应有1个更高优先级buff") and passed
	
	# 3. 添加中优先级buff
	passed = print_result("添加中优先级buff", container.add_buff(medium_priority), "应成功添加") and passed
	container._physics_process(0.0)
	var medium_runtime = container.get_runtime_buff(medium_priority)
	
	# 验证状态变化
	passed = print_result("中优先级禁用", !medium_runtime.enable, "中优先级应禁用") and passed
	passed = print_result("高优先级higher_buff_num", high_runtime.higher_buff_num == 0, "应无更高优先级buff") and passed
	passed = print_result("中优先级higher_buff_num", medium_runtime.higher_buff_num == 1, "应有1个更高优先级buff") and passed
	
	# 4. 移除高优先级buff
	passed = print_result("移除高优先级", container.remove_buff(high_priority), "应成功移除") and passed
	container._physics_process(0.0)
	
	# 验证状态变化
	passed = print_result("中优先级启用", medium_runtime.enable, "中优先级应启用") and passed
	passed = print_result("低优先级仍禁用", !low_runtime.enable, "低优先级应仍禁用") and passed
	passed = print_result("低优先级higher_buff_num更新", low_runtime.higher_buff_num == 1, "应有1个更高优先级buff") and passed
	
	# 5. 测试优先级相等的情况
	var equal_priority1 = Priority_Buff.new()
	equal_priority1.buff_name = "EqualPriority1"
	equal_priority1.override_buff_name = "EqualPriority"
	equal_priority1.default_priority = 7
	equal_priority1.default_duration = 5.0
	
	var equal_priority2 = Priority_Buff.new()
	equal_priority2.buff_name = "EqualPriority2"
	equal_priority2.override_buff_name = "EqualPriority"
	equal_priority2.default_priority = 7
	equal_priority2.default_duration = 5.0
	
	# 添加相同优先级的buff
	container.add_buff(equal_priority1)
	container.add_buff(equal_priority2)
	container._physics_process(0.0)
	
	var equal_runtime1 = container.get_runtime_buff(equal_priority1)
	var equal_runtime2 = container.get_runtime_buff(equal_priority2)
	
	# 验证相同优先级互不影响
	passed = print_result("相同优先级1启用", equal_runtime1.enable, "应启用") and passed
	passed = print_result("相同优先级2启用", equal_runtime2.enable, "应启用") and passed
	passed = print_result("相同优先级higher_buff_num", 
		equal_runtime1.higher_buff_num == 0 && equal_runtime2.higher_buff_num == 0, 
		"应无更高优先级buff") and passed
	
	container.queue_free()
	return passed

func test_blackboard() -> bool:
	print("\n[测试黑板功能]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true

	# 1. 测试新的黑板初始化行为：运行时黑板初始应为空
	var buff = Test_Buff.new()
	buff.buff_name = "BlackboardTest"
	buff.default_duration = 2.0
	# 注意：buff.init_buff_blackboard 不再被自动复制到运行时黑板
	buff.init_buff_blackboard = {"from_resource": 100, "resource_message": "hello_from_resource"} 

	# 方法A: 通过 add_buff 的 context 参数初始化运行时黑板
	var initialContext = {"counter": 0, "message": "hello"}
	passed = print_result("通过Context添加Buff", container.add_buff(buff, initialContext), "应成功通过Context添加Buff") and passed
	container._physics_process(0.0)

	var runtime = container.get_runtime_buff(buff)
	# 关键断言：运行时黑板不应包含资源中的初始化字典，但应包含传入的context
	passed = print_result("运行时黑板初始状态(应不含资源数据)", 
		!runtime.blackboard.has("from_resource") && !runtime.blackboard.has("resource_message"),
		"运行时黑板错误地包含了资源init_buff_blackboard的数据") and passed
	passed = print_result("运行时黑板初始化(应包含Context数据)", 
		runtime.blackboard.get("counter") == 0 and runtime.blackboard.get("message") == "hello",
		"运行时黑板未正确初始化Context数据") and passed

	# 方法B: 也可以在Buff的 _on_buff_awake 或 _on_buff_start 中初始化
	# 创建一个新的Buff来测试这种方法
	var manualBuff = ManualInitBuff.new()
	manualBuff.buff_name = "ManualBlackboardTest"
	manualBuff.default_duration = 2.0

	passed = print_result("添加手动初始化Buff", container.add_buff(manualBuff, initialContext), "应成功添加手动初始化Buff") and passed
	container._physics_process(0.0)
	var manualRuntime = container.get_runtime_buff(manualBuff)

	# 检查手动初始化的值
	passed = print_result("手动初始化值存在", manualRuntime.blackboard.get("manual_init_key") == "manual_init_value", "手动初始化值未设置") and passed
	# 检查Context值是否被覆盖（取决于ManualInitBuff的逻辑）
	# 此例中 manualInitBuff 的 awake 方法覆盖了 counter
	passed = print_result("手动初始化覆盖Context", manualRuntime.blackboard.get("counter") == 42, "手动初始化未覆盖Context值") and passed
	# 检查未覆盖的Context值
	passed = print_result("未覆盖的Context值存在", manualRuntime.blackboard.get("message") == "hello", "未覆盖的Context值丢失") and passed

	# 2. 测试黑板修改功能 (保持不变，测试的是读写操作本身)
	runtime.blackboard["counter"] = 5
	runtime.blackboard["message"] = "world"
	passed = print_result("黑板修改持久化", 
		runtime.blackboard.get("counter") == 5 and runtime.blackboard.get("message") == "world",
		"黑板修改未正确保存") and passed

	# 3. 清理
	container.queue_free()
	return passed




func test_interval_processing() -> bool:
	print("\n[测试间隔处理]")
	var container = GD_BuffContainer.new()
	add_child(container)
	var passed = true
	
	# 1. 测试有限间隔次数
	var finite_buff = Test_Buff.new()
	finite_buff.buff_name = "FiniteIntervalTest"
	finite_buff.default_duration = 3.0
	finite_buff.default_interval_time = 1.0  # 每秒触发一次
	finite_buff.default_interval_trigger_num = 2      # 最多触发2次
	finite_buff.is_interval_num_inf = false   # 明确设置有限次数
	
	container.add_buff(finite_buff)
	container._physics_process(0.0)  # 处理添加
	
	var runtime = container.get_runtime_buff(finite_buff)
	
	# 验证初始状态
	passed = print_result("有限间隔-初始间隔计时", is_equal_approx(runtime.curr_interval_time, 0.0), 
						 "初始间隔时间应为0.0") and passed
	passed = print_result("有限间隔-初始间隔计数", runtime.curr_interval_num == 2, 
						 "初始间隔计数应为2") and passed
	
	# 模拟0.5秒 - 不应触发
	container._physics_process(0.5)
	passed = print_result("有限间隔-0.5秒后间隔未触发", finite_buff.interval_count == 0, 
						 "间隔触发过早") and passed
	
	# 模拟1.0秒 - 应触发第一次
	container._physics_process(0.5)  # 累计1.0秒
	passed = print_result("有限间隔-1.0秒后触发第一次", finite_buff.interval_count == 1, 
						 "第一次间隔未触发") and passed
	passed = print_result("有限间隔-间隔计数减少", runtime.curr_interval_num == 1, 
						 "间隔计数应减少至1") and passed
	passed = print_result("有限间隔-间隔计时器重置", is_equal_approx(runtime.curr_interval_time, 0.0), 
						 "间隔计时器未重置") and passed
	
	# 模拟1.5秒 - 不应触发
	container._physics_process(0.5)  # 累计1.5秒
	passed = print_result("有限间隔-1.5秒后无触发", finite_buff.interval_count == 1, 
						 "额外触发") and passed
	
	# 模拟2.0秒 - 应触发第二次
	container._physics_process(0.5)  # 累计2.0秒
	passed = print_result("有限间隔-2.0秒后触发第二次", finite_buff.interval_count == 2, 
						 "第二次间隔未触发") and passed
	passed = print_result("有限间隔-间隔计数减少", runtime.curr_interval_num == 0, 
						 "间隔计数应减少至0") and passed
	
	# 模拟2.5秒 - 不应触发（达到最大间隔次数）
	container._physics_process(0.5)  # 累计2.5秒
	passed = print_result("有限间隔-2.5秒后无触发（达到上限）", finite_buff.interval_count == 2, 
						 "超过最大间隔次数触发") and passed
	
	# 模拟3.0秒 - buff应自动移除
	container._physics_process(0.5)  # 累计3.0秒
	passed = print_result("有限间隔-3.0秒后buff移除", container.get_runtime_buff(finite_buff) == null, 
						 "未自动移除") and passed
	passed = print_result("有限间隔-移除回调", finite_buff.remove_count == 1, 
						 "移除回调未触发") and passed
	
	# 2. 测试无限间隔次数
	var infinite_buff = Test_Buff.new()
	infinite_buff.buff_name = "InfiniteIntervalTest"
	infinite_buff.default_duration = 3.0
	infinite_buff.default_interval_time = 0.5  # 每0.5秒触发一次
	infinite_buff.is_interval_num_inf = true   # 无限次数
	
	container.add_buff(infinite_buff)
	container._physics_process(0.0)  # 处理添加
	
	runtime = container.get_runtime_buff(infinite_buff)
	
	# 验证初始状态
	passed = print_result("无限间隔-初始间隔计数", runtime.curr_interval_num == 0, 
						 "初始间隔计数应为0") and passed
	
	# 模拟0.5秒 - 应触发第一次
	container._physics_process(0.5)
	passed = print_result("无限间隔-0.5秒后触发第一次", infinite_buff.interval_count == 1, 
						 "第一次间隔未触发") and passed
	
	# 模拟1.0秒 - 应触发第二次
	container._physics_process(0.5)  # 累计1.0秒
	passed = print_result("无限间隔-1.0秒后触发第二次", infinite_buff.interval_count == 2, 
						 "第二次间隔未触发") and passed
	
	# 模拟1.5秒 - 应触发第三次
	container._physics_process(0.5)  # 累计1.5秒
	passed = print_result("无限间隔-1.5秒后触发第三次", infinite_buff.interval_count == 3, 
						 "第三次间隔未触发") and passed
	
	# 模拟3.0秒 - buff应自动移除
	container._physics_process(1.5)  # 累计3.0秒
	passed = print_result("无限间隔-3.0秒后buff移除", container.get_runtime_buff(infinite_buff) == null, 
						 "未自动移除") and passed
	passed = print_result("无限间隔-移除回调", infinite_buff.remove_count == 1, 
						 "移除回调未触发") and passed
	
	# 3. 测试间隔时间小于delta的情况
	var small_interval_buff = Test_Buff.new()
	small_interval_buff.buff_name = "SmallIntervalTest"
	small_interval_buff.default_duration = 1.0
	small_interval_buff.default_interval_time = 0.1  # 间隔时间小于delta
	small_interval_buff.default_interval_trigger_num = 10
	small_interval_buff.is_interval_num_inf = false
	
	container.add_buff(small_interval_buff)
	container._physics_process(0.0)  # 处理添加
	
	# 模拟一次物理过程（delta=0.5秒），最多触发一次
	container._physics_process(0.5)
	var small_runtime = container.get_runtime_buff(small_interval_buff)
	passed = print_result("小间隔-0.5秒后触发次数", small_interval_buff.interval_count == 1, 
						 "应为%d次，实际%d次" % [1, small_interval_buff.interval_count]) and passed
	passed = print_result("小间隔-剩余间隔次数", small_runtime.curr_interval_num == (10 - 1), 
						 "应为%d次，实际%d次" % [10 - 1, small_runtime.curr_interval_num]) and passed
	
	container.queue_free()
	return passed

func test_buff_factory() -> bool:
	print("\n[测试Buff工厂功能]")
	var passed = true
	
	# 1. 测试数据验证功能
	print("[测试数据验证]")
	var invalid_data = {
		"buff_name": 123, # 错误类型
		"max_layers": 0   # 无效值
	}
	passed = print_result("验证无效数据", !GD_BuffFactory.validate_buff_data(invalid_data), "应拒绝无效数据") and passed
	
	var valid_data = {
		"buff_name": "TestBuff",
		"stack_type": "STACK",
		"max_layers": 3
	}
	passed = print_result("验证有效数据", GD_BuffFactory.validate_buff_data(valid_data), "应接受有效数据") and passed
	
	# 测试无效的stack_type
	var invalid_stack = valid_data.duplicate()
	invalid_stack["stack_type"] = "INVALID_TYPE"
	passed = print_result("验证无效stack_type", !GD_BuffFactory.validate_buff_data(invalid_stack), "应拒绝无效stack_type") and passed
	
	# 2. 测试从字典创建buff
	print("[测试字典创建]")
	var buff = GD_BuffFactory.create_buff_from_dict(valid_data)
	passed = print_result("创建有效buff", buff != null, "应成功创建buff") and passed
	if buff:
		passed = print_result("buff名称", buff.buff_name == "TestBuff", "名称应为TestBuff") and passed
		passed = print_result("stack类型", buff.stack_type == GD_Buff.STACK_TYPE.STACK, "应为STACK类型") and passed
		passed = print_result("最大层数", buff.max_layers == 3, "最大层数应为3") and passed
	
	# 3. 测试JSON创建和序列化
	print("[测试JSON处理]")
	var json_str = """
	{
		"buff_name": "PoisonBuff",
		"default_duration": 10.0,
		"default_interval_time": 1.0,
		"default_interval_num": 5,
		"stack_type": "STACK",
		"max_layers": 3
	}
	"""
	
	# 从JSON创建
	var poison_buff = GD_BuffFactory.create_buff_from_json(json_str)
	passed = print_result("JSON创建buff", poison_buff != null, "应成功从JSON创建") and passed
	if poison_buff:
		passed = print_result("JSON名称", poison_buff.buff_name == "PoisonBuff", "名称应为PoisonBuff") and passed
		passed = print_result("JSON持续时间", poison_buff.default_duration == 10.0, "持续时间应为10.0") and passed
		passed = print_result("JSON间隔时间", poison_buff.default_interval_time == 1.0, "间隔时间应为1.0") and passed
		passed = print_result("JSON间隔次数", poison_buff.default_interval_trigger_num == 5, "间隔次数应为5") and passed
		
		# 序列化测试
		var serialized_dict = GD_BuffFactory.buff_to_dict(poison_buff)
		passed = print_result("序列化为字典", serialized_dict != null and serialized_dict.size() > 0, "应成功序列化") and passed
		
		# 检查序列化结果
		if serialized_dict:
			passed = print_result("序列化名称", serialized_dict["buff_name"] == "PoisonBuff", "名称应为PoisonBuff") and passed
			passed = print_result("序列化stack类型", serialized_dict["stack_type"] == "STACK", "应为STACK类型") and passed
			passed = print_result("序列化层数", serialized_dict["max_layers"] == 3, "最大层数应为3") and passed
		
		# 测试JSON序列化
		var serialized_json = GD_BuffFactory.buff_to_json(poison_buff)
		passed = print_result("序列化为JSON", serialized_json != null and serialized_json.length() > 0, "应生成JSON字符串") and passed
		
		# 验证JSON可被重新解析
		if serialized_json:
			var reparsed_buff = GD_BuffFactory.create_buff_from_json(serialized_json)
			passed = print_result("重新解析JSON", reparsed_buff != null, "应成功重新解析") and passed
			if reparsed_buff:
				passed = print_result("重新解析名称", reparsed_buff.buff_name == "PoisonBuff", "名称应为PoisonBuff") and passed
				passed = print_result("重新解析持续时间", reparsed_buff.default_duration == 10.0, "持续时间应为10.0") and passed
	
	# 4. 测试默认模板
	print("[测试默认模板]")
	var default_template = GD_BuffFactory.create_default_buff_template()
	passed = print_result("默认模板存在", default_template != null, "应创建默认模板") and passed
	if default_template:
		passed = print_result("默认名称", default_template["buff_name"] == "new_buff", "名称应为new_buff") and passed
		passed = print_result("默认stack类型", default_template["stack_type"] == "PRIORITY", "应为PRIORITY") and passed
		
		# 使用模板创建buff
		var default_buff = GD_BuffFactory.create_buff_from_dict(default_template)
		passed = print_result("从模板创建buff", default_buff != null, "应成功创建") and passed
	
	# 5. 测试复杂场景
	print("[测试复杂场景]")
	var complex_data = {
		"buff_name": "ComplexBuff",
		"override_buff_name": "OverrideName",
		"init_buff_blackboard": {"key1": "value1", "key2": 42},
		"is_default_duration_inf": true,
		"default_priority": 5,
		"is_interval_num_inf": true,
		"is_disable_override": true,
		"is_layers_exhausted": true
	}
	
	var complex_buff = GD_BuffFactory.create_buff_from_dict(complex_data)
	passed = print_result("创建复杂buff", complex_buff != null, "应成功创建") and passed
	if complex_buff:
		passed = print_result("复杂名称", complex_buff.buff_name == "ComplexBuff", "名称应为ComplexBuff") and passed
		passed = print_result("覆写名称", complex_buff.override_buff_name == "OverrideName", "覆写名称应为OverrideName") and passed
		passed = print_result("黑板内容", 
			complex_buff.init_buff_blackboard["key1"] == "value1" and complex_buff.init_buff_blackboard["key2"] == 42,
			"黑板内容不匹配") and passed
		passed = print_result("无限持续时间", complex_buff.is_default_duration_inf, "应为无限持续时间") and passed
		passed = print_result("优先级", complex_buff.default_priority == 5, "优先级应为5") and passed
		passed = print_result("无限间隔次数", complex_buff.is_interval_num_inf, "应为无限间隔次数") and passed
		passed = print_result("禁用覆写", complex_buff.is_disable_override, "应禁用覆写") and passed
		passed = print_result("层数耗尽", complex_buff.is_clear_layers_on_time_end, "应启用层数耗尽") and passed
	
	return passed

func test_instantiate_global_class() -> bool:
	print("\n[测试全局类实例化]")
	var passed: bool = true
	
	# 1. 无参数构造
	var instance = GD_BuffUtilities.instantiate_global_class("MyBuff")
	passed = print_result("创建MyBuff", instance is MyBuff, "实例化后的对象不是指定类型") and passed
	
	# 2. 缓存命中
	var second_instance = GD_BuffUtilities.instantiate_global_class("MyBuff")
	passed = print_result("再次创建MyBuff（缓存）", second_instance is MyBuff, "缓存实例化后的对象不是指定类型") and passed
	
	# 3. 带参数构造
	var arg_instance = GD_BuffUtilities.instantiate_global_class("MyBuff", ["param1", 42])
	var init_ok = arg_instance and arg_instance.has_method("get_init_data") and arg_instance.get_init_data() == ["param1", 42]
	passed = print_result("带参数构造MyBuff", init_ok, "带参数构造未正确传入参数") and passed
	
	# 4. 不存在的类
	var bad_instance = GD_BuffUtilities.instantiate_global_class("NoMyBuff")
	passed = print_result("测试不存在的类", bad_instance == null, "不存在的类返回了非null值") and passed
	
	return passed
