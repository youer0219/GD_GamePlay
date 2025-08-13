class_name GD_BuffUtilities

static var _global_class_cache: Dictionary = {}

static func get_dic_array(size:int,dic:Dictionary = {})->Array[Dictionary]:
	var dic_array :Array[Dictionary] = []
	for i in size:
		dic_array.append(dic)
	return dic_array

static func merge_dic_array(dic_array:Array[Dictionary],new_dic_array:Array[Dictionary])->void:
	for i in dic_array.size():
		dic_array[i].merge(new_dic_array[i],true)

## 静态方法：根据全局类名实例化对象
## 如果不存在则警告并返回 null
static func instantiate_global_class(global_class_name: StringName) -> Object:
	if _global_class_cache.has(global_class_name):
		return _global_class_cache[global_class_name].new()
	
	var global_class_list:Array[Dictionary] = ProjectSettings.get_global_class_list()
	
	# 遍历全局类列表，查找匹配
	for class_info in global_class_list:
		if class_info.get("class") == global_class_name:
			var path = class_info.get("path", "")
			if path == "":
				push_warning("Global class '%s' has no script path." % global_class_name)
				return null
			
			var script: Script = load(path)
			if script == null:
				push_warning("Failed to load script for global class '%s'." % global_class_name)
				return null
			
			# 加入缓存
			_global_class_cache[global_class_name] = script
			return script.new()
	
	# 如果没有找到
	push_warning("Global class '%s' does not exist." % global_class_name)
	return null
