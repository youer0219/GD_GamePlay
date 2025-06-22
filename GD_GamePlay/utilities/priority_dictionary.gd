extends RefCounted
class_name PriorityDictionary

var dictionary:Dictionary[float,Array]

func get_top_priority_array()->Array:
	if dictionary.is_empty():
		return []
	
	# 改为获取最大优先级 (数值大为高优先级)
	return dictionary[dictionary.keys().max()]

# 添加元素到指定优先级
func put(priority: float, element) -> void:
	if not dictionary.has(priority):
		dictionary[priority] = []
	dictionary[priority].append(element)

# 弹出最高优先级的元素（LIFO: 后进先出）
func pop():
	if dictionary.is_empty():
		return null
	
	# 改为获取最大优先级 (数值大为高优先级)
	var highest_priority = dictionary.keys().max()
	var array = dictionary[highest_priority]
	var element = array.pop_back()
	
	if array.is_empty():
		dictionary.erase(highest_priority)
	
	return element

# 检查字典是否为空
func is_empty() -> bool:
	return dictionary.is_empty()

# 清空字典
func clear() -> void:
	dictionary.clear()

# 获取所有优先级列表（降序排列）
func get_priorities() -> Array:
	var keys = dictionary.keys()
	keys.sort()
	keys.reverse()
	return keys

# 获取所有元素（按优先级降序排列）
func get_all_elements() -> Array:
	var result = []
	
	# 按优先级降序获取元素
	for priority in get_priorities():
		result += dictionary[priority]
	
	return result

# 统计元素总数
func size() -> int:
	var count = 0
	for array in dictionary.values():
		count += array.size()
	return count

# 更新优先级（元素不存在时添加）
func update_priority(element, new_priority: float) -> void:
	# 先移除旧元素（如果存在）
	remove_element(element)
	
	# 添加新优先级
	put(new_priority, element)

# 移除指定元素
func remove_element(element) -> bool:
	for priority in dictionary.keys():
		var array = dictionary[priority]
		var index = array.find(element)
		if index != -1:
			array.remove_at(index)
			
			# 清理空数组
			if array.is_empty():
				dictionary.erase(priority)
				
			return true
	
	return false

# 检查元素是否存在
func has_element(element) -> bool:
	for array in dictionary.values():
		if array.has(element):
			return true
	return false

# 检查并添加不重复元素
func put_unique(priority: float, element) -> bool:
	if has_element(element):
		return false
	put(priority, element)
	return true
