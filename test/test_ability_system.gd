# test_ability_system.gd
extends Node

func _ready() -> void:
	# 运行所有测试
	test_ability()
	test_runtime_ability()
	test_ability_container()
	quit()

# 辅助函数：打印带颜色的测试结果
func print_result(test_name: String, passed: bool):
	var color = "[color=green]" if passed else "[color=red]"
	print_rich(color + test_name + (": PASSED" if passed else ": FAILED") + "[/color]")

## 1. Ability 测试用例 (修正版)
func test_ability():
	print("\n=== Testing Ability ===")
	
	# 测试基础能力创建
	var ability = Ability.new()
	ability.ability_name = "TestAbility"
	print_result("Ability creation", ability != null and ability.ability_name == "TestAbility")
	
	# 测试默认值
	print_result("Default cooldown", ability._get_cooldown(null) == 0.0)
	print_result("Default duration", ability._get_duration(null) == 0.0)
	
	# 测试默认行为
	var test_node = AbilityContainer.new()
	var runtime_ability = RuntimeAbility.new()
	runtime_ability.set_ability(ability)
	runtime_ability.set_container(test_node)
	
	print_result("Default can_be_activated", ability._can_be_activated(test_node, runtime_ability) == true)
	print_result("Default should_be_activated", ability._should_be_activated(test_node) == false)
	
	# 测试自定义能力
	var custom_ability = CustomAbility.new()
	custom_ability.cooldown = 5.0
	custom_ability.duration = 2.0
	print_result("Custom cooldown", custom_ability._get_cooldown(null) == 5.0)
	print_result("Custom duration", custom_ability._get_duration(null) == 2.0)
	
	test_node.free()

## 2. RuntimeAbility 测试用例 (修正版)
func test_runtime_ability():
	print("\n=== Testing RuntimeAbility ===")
	
	var container = AbilityContainer.new()
	var ability = Ability.new()
	ability.ability_name = "TestAbility"
	
	var runtime_ability = RuntimeAbility.new()
	runtime_ability.set_ability(ability)
	runtime_ability.set_container(container)
	
	# 测试初始状态
	print_result("Initial is_granted", runtime_ability.is_granted() == false)
	print_result("Initial is_active", runtime_ability.is_active() == false)
	print_result("Initial is_blocked", runtime_ability.is_blocked() == false)
	
	# 测试授权
	var grant_result = runtime_ability.grant()
	print_result("Grant result", grant_result == Ability.AbilityEventType.GRANTED)
	print_result("After grant is_granted", runtime_ability.is_granted() == true)
	
	# 测试激活
	var activate_result = runtime_ability.activate()
	print_result("Activate result", activate_result == Ability.AbilityEventType.ACTIVATED)
	print_result("After activate is_active", runtime_ability.is_active() == true)
	
	# 测试冷却时间
	var cooldown_ability = CustomAbility.new()
	cooldown_ability.cooldown = 3.0
	runtime_ability.set_ability(cooldown_ability)
	
	runtime_ability.handle_tick(4.0)
	print_result("Cooldown after tick", runtime_ability.is_cooldown_active() == false)
	
	#runtime_ability.end()
	#print_result("Cooldown after end", runtime_ability.is_cooldown_active() == true)
	#print_result("Cooldown time set", is_equal_approx(runtime_ability.cooldown_time, 3.0))
	
	# 测试阻塞
	var block_result = runtime_ability.block()
	print_result("Block result", block_result == Ability.AbilityEventType.REFUSED_TO_BLOCK)
	print_result("After block is_blocked", runtime_ability.is_blocked() == true)
	print_result("Block resets active", runtime_ability.is_active() == false)
	
	# 测试解除阻塞
	var unblock_result = runtime_ability.unblock()
	print_result("Unblock result", unblock_result == Ability.AbilityEventType.UNBLOCKED)
	print_result("After unblock is_blocked", runtime_ability.is_blocked() == false)
	
	# 测试撤销
	var revoke_result = runtime_ability.revoke()
	print_result("Revoke result", revoke_result == Ability.AbilityEventType.REFUSED_TO_REVOKE)
	print_result("After revoke is_granted", runtime_ability.is_granted() == false)
	
	container.free()

## 3. AbilityContainer 测试用例 (修正版)
func test_ability_container():
	print("\n=== Testing AbilityContainer ===")
	
	var container = AbilityContainer.new()
	add_child(container)  # 需要添加到场景树才能正确处理信号
	
	var ability1 = Ability.new()
	ability1.ability_name = "Ability1"
	
	var ability2 = CustomAbility.new()
	ability2.ability_name = "Ability2"
	ability2.cooldown = 2.0
	
	# 测试添加能力
	container.add_ability(ability1)
	# add_ability 的返回值只在可以成功添加并直接激活时返回true
	#print_result("Add first ability", add_result == true)
	print_result("Has ability after add", container.has_ability(ability1) == true)
	
	# 测试重复添加
	var duplicate_add = container.add_ability(ability1)
	print_result("Duplicate add", duplicate_add == false)
	
	# 测试获取运行时能力
	var runtime_ability = container.get_runtime_ability("Ability1")
	print_result("Get runtime ability", runtime_ability != null)
	
	# 测试激活能力
	var activate_result = container.try_activate("Ability1")
	print_result("Activate ability", activate_result == Ability.AbilityEventType.ACTIVATED)
	print_result("Is active after activate", container.is_ability_active("Ability1") == true)
	
	# 测试冷却时间
	container.add_ability(ability2)
	container.try_activate("Ability2")
	container.try_end("Ability2")
	print_result("Cooldown after end", container.is_ability_cooldown_active("Ability2") == true)
	
	# 测试移除能力
	var remove_result = container.remove_ability(ability1)
	print_result("Remove ability", remove_result == true)
	print_result("Has ability after remove", container.has_ability(ability1) == false)
	
	# 测试信号 (使用数组包装解决捕获问题)
	var signal_data = [false]
	container.ability_activated.connect(func(_a): signal_data[0] = true)
	container.add_ability(ability1)
	container.try_activate("Ability1")
	print_result("Signal received", signal_data[0] == true)
	
	container.free()
	
	# 测试初始能力
	var new_container = AbilityContainer.new()
	new_container.set_initial_abilities([ability1, ability2])
	add_child(new_container)
	
	new_container.free()

func quit():
	print("Test end!")
	self.queue_free()

class CustomAbility extends Ability:
	var cooldown: float = 0.0
	var duration: float = 0.0

	func _get_cooldown(_ability_container: Node) -> float:
		return cooldown

	func _get_duration(_ability_container: Node) -> float:
		return duration

	func _should_be_activated(_ability_container: Node) -> bool:
		return true

## TODO: 重写RunAbility的测试用例
