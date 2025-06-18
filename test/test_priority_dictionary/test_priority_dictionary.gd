extends Node

# 测试用例计数器
var tests_passed = 0
var total_tests = 0

func _ready():
	run_all_tests()
	print("\n--- 测试结果 ---")
	print("所有测试完成: %d/%d 个测试通过" % [tests_passed, total_tests])

func run_all_tests():
	# 基础功能测试
	test("基本功能 - 创建实例", func():
		var pd = PriorityDictionary.new()
		return pd != null
	)
	
	test("边界条件 - 空字典操作", func():
		var pd = PriorityDictionary.new()
		var result = true
		result = result and pd.is_empty()
		result = result and (pd.pop() == null)
		result = result and (pd.get_top_priority_array().is_empty())
		result = result and (pd.size() == 0)
		result = result and (pd.get_priorities().is_empty())
		result = result and (pd.get_all_elements().is_empty())
		return result
	)
	
	# 添加操作测试
	test("添加元素 - 单个元素", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		return pd.size() == 1 and pd.has_element("A")
	)
	
	test("添加元素 - 多个优先级", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "Low")
		pd.put(3.0, "High")  # 数值大的为高优先级
		pd.put(2.0, "Medium")
		
		return pd.size() == 3 and pd.has_element("Low") and pd.has_element("Medium") and pd.has_element("High")
	)
	
	test("添加元素 - 同优先级多个元素", func():
		var pd = PriorityDictionary.new()
		pd.put(2.0, "A")
		pd.put(2.0, "B")
		pd.put(2.0, "C")
		
		return pd.size() == 3 and pd.has_element("A") and pd.has_element("B") and pd.has_element("C")
	)
	
	# 优先级排序测试
	test("优先级排序 - 多个优先级验证(降序)", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "Low")
		pd.put(3.0, "High")  # 数值大的为高优先级
		pd.put(2.0, "Medium")
		
		# 测试优先级顺序 (数值大为高优先级 -> 降序排列)
		var priorities = pd.get_priorities()
		return priorities == [3.0, 2.0, 1.0]
	)
	
	test("优先级排序 - 负值优先级", func():
		var pd = PriorityDictionary.new()
		pd.put(-1.0, "Low")
		pd.put(0.0, "Medium")
		pd.put(1.0, "High")
		
		var priorities = pd.get_priorities()
		return priorities == [1.0, 0.0, -1.0]
	)
	
	test("优先级排序 - 相同优先级处理", func():
		var pd = PriorityDictionary.new()
		pd.put(3.0, "A")
		pd.put(3.0, "B")
		pd.put(2.0, "C")
		pd.put(1.0, "D")
		
		var priorities = pd.get_priorities()
		return priorities == [3.0, 2.0, 1.0]
	)
	
	# 弹出操作测试
	test("弹出操作 - LIFO行为验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "First")
		pd.put(1.0, "Second")
		pd.put(1.0, "Third")
		
		# 后进先出 - LIFO
		var result = true
		result = result and (pd.pop() == "Third")
		result = result and (pd.pop() == "Second")
		result = result and (pd.pop() == "First")
		result = result and pd.is_empty()
		return result
	)
	
	test("弹出操作 - 最高优先级验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "Low")
		pd.put(3.0, "High")
		pd.put(2.0, "Medium")
		
		return pd.pop() == "High"
	)
	
	test("弹出操作 - 空字典处理", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.pop()  # 弹出元素
		return pd.pop() == null  # 再次弹出应为null
	)
	
	# 移除操作测试
	test("移除操作 - 各种场景验证", func():
		var pd = PriorityDictionary.new()
		pd.put(3.0, "Apple")  # 数值大的为高优先级
		pd.put(1.0, "Banana")
		pd.put(2.0, "Cherry")
		
		var result = true
		
		# 移除存在的元素
		result = result and pd.remove_element("Banana")
		result = result and pd.size() == 2
		result = result and not pd.has_element("Banana")
		
		# 移除不存在的元素
		result = result and not pd.remove_element("Nonexistent")
		
		# 移除后优先级列表应自动清理
		result = result and pd.get_priorities() == [3.0, 2.0]
		
		# 移除最后两个元素
		result = result and pd.remove_element("Cherry")
		result = result and pd.remove_element("Apple")
		result = result and pd.is_empty()
		
		return result
	)
	
	test("移除操作 - 优先级清理验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.put(1.0, "B")
		
		# 移除一个元素后优先级应保留
		pd.remove_element("A")
		var result = pd.has_element("B") and pd.get_priorities().size() == 1
		
		# 移除所有元素后优先级应清除
		pd.remove_element("B")
		result = result and pd.get_priorities().is_empty()
		
		return result
	)
	
	# 更新操作测试
	test("更新操作 - 提高优先级验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.put(3.0, "B")
		
		# 提高A的优先级
		pd.update_priority("A", 4.0)
		
		return pd.get_priorities() == [4.0, 3.0] and pd.pop() == "A"
	)
	
	test("更新操作 - 降低优先级验证", func():
		var pd = PriorityDictionary.new()
		pd.put(4.0, "A")
		pd.put(3.0, "B")
		
		# 降低A的优先级
		pd.update_priority("A", 1.0)
		
		return pd.get_priorities() == [3.0, 1.0] and pd.pop() == "B"
	)
	
	test("更新操作 - 不存在元素验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		
		# 更新不存在元素应添加新元素
		pd.update_priority("B", 2.0)
		
		return pd.has_element("B") and pd.size() == 2
	)
	
	test("更新操作 - 同优先级内部移动验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.put(1.0, "B")
		pd.put(1.0, "C")
		
		# 提升C在同优先级中的位置（在LIFO中应该后进先出）
		pd.update_priority("C", 1.0)
		
		# 弹出顺序应为C(最后进入)、B、A
		return pd.pop() == "C" and pd.pop() == "B" and pd.pop() == "A"
	)
	
	# 获取操作测试
	test("获取操作 - 降序排列验证", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "Dog")  # 数值小的为低优先级
		pd.put(3.0, "Cat")  # 数值大的为高优先级 -> 最前面
		pd.put(2.0, "Bird")
		pd.put(3.0, "Fish")  # 同优先级中最后添加的
		
		var all = pd.get_all_elements()
		return all[0] == "Cat" and all[1] == "Fish" and all[2] == "Bird" and all[3] == "Dog"
	)
	
	test("获取操作 - 空字典验证", func():
		var pd = PriorityDictionary.new()
		return pd.get_all_elements().is_empty() and pd.get_top_priority_array().is_empty()
	)
	
	# 唯一性操作测试
	test("唯一性操作 - put_unique验证", func():
		var pd = PriorityDictionary.new()
		var result = true
		
		# 第一次添加应成功
		result = result and pd.put_unique(1.0, "A")
		result = result and pd.size() == 1
		
		# 第二次添加相同元素应失败
		result = result and not pd.put_unique(2.0, "A")
		result = result and pd.size() == 1
		
		# 不同优先级添加相同元素也应失败
		result = result and not pd.put_unique(3.0, "A")
		result = result and pd.size() == 1
		
		# 添加不同元素应成功
		result = result and pd.put_unique(3.0, "B")  # 最高优先级
		result = result and pd.size() == 2
		
		return result
	)
	
	# 混合操作测试
	test("混合操作 - 复杂场景验证", func():
		var pd = PriorityDictionary.new()
		
		# 1. 添加初始元素
		pd.put(2.0, "Item1")
		pd.put(1.0, "Item2")
		pd.put(3.0, "Item3")
		
		# 2. 验证初始状态
		if not (pd.size() == 3 and pd.get_top_priority_array() == ["Item3"]):
			return false
		
		# 3. 弹出最高优先级
		if pd.pop() != "Item3":
			return false
		if pd.size() != 2:
			return false
		
		# 4. 添加新元素
		pd.put(1.0, "Item4")
		if not pd.has_element("Item4") or pd.size() != 3:
			return false
		
		# 5. 更新优先级
		pd.update_priority("Item1", 4.0)
		if pd.get_top_priority_array() != ["Item1"]:
			return false
		
		# 6. 移除元素
		if not pd.remove_element("Item2") or pd.size() != 2:
			return false
		
		# 7. 最终状态验证
		if pd.size() != 2:
			return false
		
		var priorities = pd.get_priorities()
		if not (priorities.size() == 2 and priorities[0] == 4.0 and priorities[1] == 1.0):
			return false
		
		var all = pd.get_all_elements()
		if not (all.size() == 2 and "Item1" in all and "Item4" in all):
			return false
		
		# 8. 清理验证
		pd.clear()
		if not pd.is_empty():
			return false
		
		return true
	)
	
	# 新增边界条件测试
	test("边界条件 - 相同优先级的大量元素", func():
		var pd = PriorityDictionary.new()
		var count = 1000
		
		# 添加1000个元素到相同优先级
		for i in range(count):
			pd.put(1.0, "Element%d" % i)
		
		# 验证数量
		if pd.size() != count:
			return false
		
		# 弹出所有元素
		for i in range(count):
			if pd.pop() == null:
				return false
		
		# 验证清空
		return pd.is_empty()
	)
	
	test("边界条件 - 频繁更新优先级", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "Item")
		
		# 多次更新优先级
		for i in range(50):
			pd.update_priority("Item", i)
		
		# 验证最终优先级
		return pd.get_priorities() == [49.0]
	)
	
	test("边界条件 - 添加后立即移除", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.put(2.0, "B")
		
		if not pd.remove_element("A") or pd.has_element("A"):
			return false
		
		if not pd.remove_element("B") or pd.has_element("B"):
			return false
		
		return pd.is_empty()
	)
	
	test("边界条件 - 元素不存在时的操作", func():
		var pd = PriorityDictionary.new()
		
		# 所有操作在空字典上应该是安全的
		var result = true
		result = result and (pd.pop() == null)
		result = result and not pd.remove_element("Nonexistent")
		result = result and not pd.has_element("Nonexistent")
		
		# 更新不存在元素 - 应该添加到字典中
		pd.update_priority("Nonexistent", 5.0)
		result = result and pd.has_element("Nonexistent")
		result = result and pd.get_priorities() == [5.0]
		
		result = result and pd.get_all_elements() == ["Nonexistent"]
		result = result and pd.size() == 1
		result = result and not pd.is_empty()
		
		# 清理状态
		pd.clear()
		result = result and pd.is_empty()
		
		return result
	)
	
	test("边界条件 - 优先级相等的情况", func():
		var pd = PriorityDictionary.new()
		pd.put(1.0, "A")
		pd.put(1.0, "B")
		pd.put(1.0, "C")
		
		# 相同优先级时应该按LIFO弹出
		var result = true
		result = result and (pd.pop() == "C")
		result = result and (pd.pop() == "B")
		result = result and (pd.pop() == "A")
		result = result and pd.is_empty()
		
		return result
	)
	
	test("边界条件 - 非常大的优先级值", func():
		var pd = PriorityDictionary.new()
		pd.put(1e10, "LargeHigh")
		pd.put(1e20, "VeryLargeHigh")
		pd.put(-1e10, "LargeLow")
		
		# 验证优先级顺序（数值大的优先级高）
		var priorities = pd.get_priorities()
		return priorities[0] == 1e20 and priorities[1] == 1e10 and priorities[2] == -1e10
	)

func test(test_name: String, test_func: Callable):
	total_tests += 1
	print("")
	print("----- 测试: ", test_name, " -----")
	
	var result = test_func.call()
	
	if result:
		tests_passed += 1
		print("✅ 成功")
	else:
		print("❌ 失败")
	
	return result
