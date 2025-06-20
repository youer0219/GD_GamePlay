extends Node
class_name BuffSystemTest

# 自定义测试 Buff
class TestBuff extends Buff:
	var test_activated: bool = false
	var test_ended: bool = false
	var test_granted: bool = false
	var test_revoked: bool = false
	var test_duration: float = 1.0
	var can_stack: bool = false
	var can_conflict: bool = true
	
	func _init():
		buff_name = "TestBuff"
	
	func _get_duration(_buff_container: BuffContainer) -> float:
		return test_duration
	
	func _on_activate(buff_container: BuffContainer, _runtime_buff: RuntimeBuff):
		test_activated = true
	
	func _on_end(buff_container: BuffContainer, _runtime_buff: RuntimeBuff):
		test_ended = true
		# 调用父类方法处理移除
		super._on_end(buff_container, _runtime_buff)
	
	func _on_grant(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff):
		test_granted = true
	
	func _on_revoke(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff):
		test_revoked = true
	
	# 重写冲突和堆叠方法
	func _can_conflict_with(_buff: Buff) -> bool:
		return can_conflict
	
	func _can_stack_with(_buff: Buff) -> bool:
		return can_stack

class BlockingBuff extends Buff:
	func _init():
		buff_name = "BlockingBuff"
	
	func _can_conflict_with(_buff:Buff)->bool:
		return true

func _ready() -> void:
	print_rich("[b]Starting Buff System Tests...[/b]")
	# 使用 call_deferred 避免在 _ready 中直接调用异步函数
	call_deferred("run_tests_async")

# 异步运行测试
func run_tests_async() -> void:
	var all_passed = true
	
	all_passed = test_buff_lifecycle() and all_passed
	all_passed = test_buff_blocking() and all_passed
	all_passed = test_buff_conflicts() and all_passed
	
	# 异步测试需要等待
	all_passed = await test_buff_duration() and all_passed
	all_passed = await test_buff_end_removal() and all_passed
	
	if all_passed:
		print_rich("[color=green][b]All tests PASSED![/b][/color]")
	else:
		print_rich("[color=red][b]Some tests FAILED![/b][/color]")
	
	get_tree().quit()

# 辅助函数：打印带颜色的测试结果
func print_result(test_name: String, passed: bool, details: String = ""):
	var color = "[color=green]" if passed else "[color=red]"
	var result = ": PASSED" if passed else ": FAILED"
	
	print_rich(color + test_name + result + "[/color]")
	if not passed and details != "":
		print_rich("[color=yellow]" + details + "[/color]")
	
	return passed

func test_buff_lifecycle() -> bool:
	print("\n=== Testing Buff Lifecycle ===")
	var passed = true
	var container = BuffContainer.new()
	add_child(container)
	
	var test_buff = TestBuff.new()
	
	# 生命周期测试
	passed = print_result("Add Buff", container.add_buff(test_buff), "Buff should be added")
	passed = print_result("Container Has Buff", container.has_buff(test_buff), "Container should have buff")
	passed = print_result("Buff Granted", container.is_buff_granted(test_buff), "Buff should be granted")
	passed = print_result("Buff Active", container.is_buff_active(test_buff), "Buff should be active")
	passed = print_result("Granted Callback", test_buff.test_granted, "Granted callback should be called")
	passed = print_result("Activated Callback", test_buff.test_activated, "Activated callback should be called")
	
	# 结束 Buff
	var end_result = container.try_end(test_buff)
	passed = print_result("End Buff", end_result == Buff.BuffEventType.ENDED, "Buff should end successfully. Result: " + str(end_result))
	passed = print_result("Buff Ended State", container.is_buff_ended(test_buff), "Buff should be ended")
	passed = print_result("Ended Callback", test_buff.test_ended, "Ended callback should be called")
	
	# 撤销 Buff
	var revoke_result = container.try_revoke(test_buff)
	passed = print_result("Revoke Buff", revoke_result == Buff.BuffEventType.REVOKED, "Buff should be revoked. Result: " + str(revoke_result))
	passed = print_result("Buff Removed", not container.has_buff(test_buff), "Buff should be removed")
	passed = print_result("Revoked Callback", test_buff.test_revoked, "Revoked callback should be called")
	
	container.queue_free()
	return passed

func test_buff_blocking() -> bool:
	print("\n=== Testing Buff Blocking ===")
	var passed = true
	var container = BuffContainer.new()
	add_child(container)
	
	var test_buff = TestBuff.new()
	container.add_buff(test_buff)
	
	# 阻塞测试
	var block_result = container.try_block(test_buff)
	passed = print_result("Block Buff", block_result == Buff.BuffEventType.BLOCKED, "Buff should be blocked. Result: " + str(block_result))
	passed = print_result("Buff Blocked State", container.is_buff_blocked(test_buff), "Buff should be blocked")
	passed = print_result("Buff Active After Block", not container.is_buff_active(test_buff), "Buff should not be active when blocked")
	
	# 尝试激活被阻塞的 Buff
	var activate_result = container.try_activate(test_buff)
	passed = print_result("Activate Blocked Buff", activate_result == Buff.BuffEventType.REFUSED_TO_ACTIVATE_IS_BLOCKED, "Should not activate blocked buff. Result: " + str(activate_result))
	
	# 解除阻塞
	var unblock_result = container.try_unblock(test_buff)
	passed = print_result("Unblock Buff", unblock_result == Buff.BuffEventType.UNBLOCKED, "Buff should be unblocked. Result: " + str(unblock_result))
	passed = print_result("Buff Unblocked State", not container.is_buff_blocked(test_buff), "Buff should not be blocked")
	
	container.queue_free()
	return passed

func test_buff_conflicts() -> bool:
	print("\n=== Testing Buff Conflicts ===")
	var passed = true
	var container = BuffContainer.new()
	add_child(container)
	
	# 添加第一个 Buff
	var buff1 = TestBuff.new()
	buff1.buff_name = "Buff1"
	passed = print_result("Add First Buff", container.add_buff(buff1), "First buff should be added")
	
	# 添加冲突的 Buff
	var conflict_buff = BlockingBuff.new()
	conflict_buff.buff_name = "ConflictBuff"
	passed = print_result("Add Conflicting Buff", not container.add_buff(conflict_buff), "Conflicting buff should not be added")
	
	# 添加可堆叠的 Buff
	var stackable_buff = TestBuff.new()
	stackable_buff.buff_name = "StackableBuff"
	
	# 修改堆叠和冲突属性
	stackable_buff.can_conflict = false
	stackable_buff.can_stack = true
	
	passed = print_result("Add Stackable Buff", container.add_buff(stackable_buff), "Stackable buff should be added")
	
	# 检查最终 Buff 数量
	passed = print_result("Buff Count", container.runtime_buffs.size() == 2, "Should have two buffs, found: " + str(container.runtime_buffs.size()))
	
	container.queue_free()
	return passed

func test_buff_duration() -> bool:
	print("\n=== Testing Buff Duration ===")
	var passed = true
	var container = BuffContainer.new()
	add_child(container)
	
	var test_buff = TestBuff.new()
	test_buff.test_duration = 0.5
	container.add_buff(test_buff)
	
	# 初始状态检查
	passed = print_result("Initial Active State", container.is_buff_active(test_buff), "Buff should be active initially")
	passed = print_result("Initial Duration State", container.get_runtime_buff(test_buff).is_duration_active(), "Duration should be active initially")
	
	# 模拟时间流逝 (小于持续时间)
	container._physics_process(0.3)
	passed = print_result("Active After Partial Duration", container.is_buff_active(test_buff), "Buff should still be active after partial duration")
	passed = print_result("Duration After Partial", container.get_runtime_buff(test_buff).duration_time > 0, "Duration should not be over after partial duration")
	
	# 模拟时间流逝 (超过持续时间)
	container._physics_process(0.3)
	
	# 等待一帧让 deferred 调用执行
	await get_tree().process_frame
	
	# 检查结果
	passed = print_result("Buff Removed After Duration", not container.has_buff(test_buff), "Buff should be removed after duration")
	passed = print_result("Ended Callback After Duration", test_buff.test_ended, "Ended callback should be called after duration")
	
	container.queue_free()
	return passed

func test_buff_end_removal() -> bool:
	print("\n=== Testing Buff End Removal ===")
	var passed = true
	var container = BuffContainer.new()
	add_child(container)
	
	# 创建自定义 Buff 并覆盖 _on_end 不移除
	var persistent_buff = TestBuff.new()
	persistent_buff.buff_name = "PersistentBuff"
	
	# 保存原始方法
	var original_end_method = persistent_buff._on_end
	
	# 覆盖 _on_end 方法
	persistent_buff._on_end = func(buff_container: BuffContainer, runtime_buff: RuntimeBuff):
		print("Persistent buff ended but not removed")
		# 不调用原始方法，不移除
		# 但需要设置状态
		persistent_buff.test_ended = true
	
	passed = print_result("Add Persistent Buff", container.add_buff(persistent_buff), "Persistent buff should be added")
	
	# 手动结束 Buff
	container.try_end(persistent_buff)
	
	# 等待一帧
	await get_tree().process_frame
	
	# 检查结果
	passed = print_result("Buff Present After End", container.has_buff(persistent_buff), "Persistent buff should still be present")
	passed = print_result("Buff Ended State", container.is_buff_ended(persistent_buff), "Persistent buff should be ended")
	passed = print_result("Ended Callback", persistent_buff.test_ended, "Ended callback should be called")
	
	# 恢复原始方法 (如果需要)
	persistent_buff._on_end = original_end_method
	
	container.queue_free()
	return passed
