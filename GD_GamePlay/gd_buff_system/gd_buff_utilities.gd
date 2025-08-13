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

## 公共方法：根据全局类名实例化对象（可选参数）
static func instantiate_global_class(global_class_name: StringName, args: Array = []) -> Object:
	# 先查缓存
	if _global_class_cache.has(global_class_name):
		return _global_class_cache[global_class_name].new.callv(args)
	
	# 没缓存就加载脚本
	var script := _get_global_class_script(global_class_name)
	if script == null:
		return null
	
	_global_class_cache[global_class_name] = script
	return script.new.callv(args)

## 私有方法：查找并加载全局类脚本
static func _get_global_class_script(global_class_name: StringName) -> Script:
	for class_info in ProjectSettings.get_global_class_list():
		if class_info.get("class") == global_class_name:
			var path = class_info.get("path", "")
			if path == "":
				push_warning("Global class '%s' has no script path." % global_class_name)
				return null
			
			var script: Script = load(path)
			if script == null:
				push_warning("Failed to load script for global class '%s'." % global_class_name)
				return null
			
			return script
	
	push_warning("Global class '%s' does not exist." % global_class_name)
	return null
