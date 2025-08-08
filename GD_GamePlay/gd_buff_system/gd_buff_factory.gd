class_name GD_BuffFactory

## TODO:
## 此类暂时无用。未来打算添加buff类别属性。
## 修改了变量名称，导致字符串和原始变量名称不一致。未改。未来可能改变实现方式。

# 静态方法：验证buff数据字典是否有效
static func validate_buff_data(data: Dictionary) -> bool:
	# 1. 检查必需字段
	if not data.has("buff_name") or not data["buff_name"] is String:
		print("data[]: ",data["buff_name"])
		push_error("Buff validation failed: Missing or invalid 'buff_name'")
		return false
	
	# 2. 检查可选字段类型
	var optional_fields = {
		"override_buff_name": [TYPE_STRING],
		"init_buff_blackboard": [TYPE_DICTIONARY],
		"default_duration": [TYPE_FLOAT],
		"is_default_duration_inf": [TYPE_BOOL],
		"default_priority": [TYPE_FLOAT,TYPE_INT], ## 注意JSON中的数都被解析为浮点数，需要兼容
		"default_interval_time": [TYPE_FLOAT],
		"default_interval_num": [TYPE_FLOAT,TYPE_INT],
		"is_interval_num_inf": [TYPE_BOOL],
		"stack_type": [TYPE_STRING],
		"is_disable_override": [TYPE_BOOL],
		"max_layers": [TYPE_FLOAT,TYPE_INT],
		"is_layers_exhausted": [TYPE_BOOL]
	}
	
	for field in optional_fields:
		if data.has(field) and not typeof(data[field]) in optional_fields[field]:
			push_error("Buff validation failed: Invalid type for field '%s'" % field)
			return false
	
	# 3. 检查stack_type有效性
	if data.has("stack_type"):
		var valid_stack_types = GD_Buff.STACK_TYPE.keys()
		if not valid_stack_types.has(data["stack_type"]):
			push_error("Buff validation failed: Invalid stack_type '%s'" % data["stack_type"])
			return false
	
	# 4. 检查数值范围
	if data.has("max_layers") and data["max_layers"] < 1:
		push_error("Buff validation failed: max_layers must be at least 1")
		return false
	
	if data.has("default_priority") and data["default_priority"] < 0:
		push_error("Buff validation failed: default_priority cannot be negative")
		return false
	
	# 5. 检查无限持续时间和层数的逻辑冲突
	if data.get("is_default_duration_inf", false) and data.has("default_duration") and data["default_duration"] > 0:
		push_warning("Buff has infinite duration but also specifies duration value")
	
	return true

# 静态方法：从字典创建buff资源
static func create_buff_from_dict(data: Dictionary) -> GD_Buff:
	if not validate_buff_data(data):
		push_error("Cannot create buff from invalid data")
		return null
	
	var buff = GD_Buff.new()
	
	# 设置基础属性
	buff.buff_name = StringName(data["buff_name"])
	
	# 设置可选属性
	if data.has("override_buff_name"):
		buff.override_buff_name = StringName(data["override_buff_name"])
	
	if data.has("init_buff_blackboard"):
		buff.init_buff_blackboard = data["init_buff_blackboard"]
	
	if data.has("default_duration"):
		buff.default_duration = data["default_duration"]
	
	if data.has("is_default_duration_inf"):
		buff.is_default_duration_inf = data["is_default_duration_inf"]
	
	if data.has("default_priority"):
		buff.default_priority = data["default_priority"]
	
	if data.has("default_interval_time"):
		buff.default_interval_time = data["default_interval_time"]
	
	if data.has("default_interval_num"):
		buff.default_interval_trigger_num = data["default_interval_num"]
	
	if data.has("is_interval_num_inf"):
		buff.is_interval_num_inf = data["is_interval_num_inf"]
	
	if data.has("stack_type"):
		buff.stack_type = GD_Buff.STACK_TYPE[data["stack_type"]]
	
	if data.has("is_disable_override"):
		buff.is_disable_override = data["is_disable_override"]
	
	if data.has("max_layers"):
		buff.max_layers = data["max_layers"]
	
	if data.has("is_layers_exhausted"):
		buff.is_clear_layers_on_time_end = data["is_layers_exhausted"]
	
	return buff

# 静态方法：从JSON字符串创建buff资源
static func create_buff_from_json(json_str: String) -> GD_Buff:
	var json = JSON.new()
	var error = json.parse(json_str)
	
	if error != OK:
		push_error("JSON parse error: %s" % json.get_error_message())
		return null
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("JSON data is not a dictionary")
		return null
	
	return create_buff_from_dict(data)

# 静态方法：创建默认buff模板
static func create_default_buff_template() -> Dictionary:
	return {
		"buff_name": "new_buff",
		"override_buff_name": "",
		"init_buff_blackboard": {},
		"default_duration": 5.0,
		"is_default_duration_inf": false,
		"default_priority": 0,
		"default_interval_time": 1.0,
		"default_interval_num": 3,
		"is_interval_num_inf": false,
		"stack_type": "PRIORITY",
		"is_disable_override": false,
		"max_layers": 1,
		"is_layers_exhausted": false
	}

# 静态方法：转换buff资源为字典（用于序列化）
static func buff_to_dict(buff: GD_Buff) -> Dictionary:
	if not buff:
		return {}
	
	var dict = {}
	dict["buff_name"] = buff.buff_name
	
	# 添加所有可能存在的属性
	if buff.override_buff_name != &"":
		dict["override_buff_name"] = buff.override_buff_name
	
	if not buff.init_buff_blackboard.is_empty():
		dict["init_buff_blackboard"] = buff.init_buff_blackboard
	
	if buff.default_duration != 0.0:
		dict["default_duration"] = buff.default_duration
	
	if buff.is_default_duration_inf:
		dict["is_default_duration_inf"] = true
	
	if buff.default_priority != 0:
		dict["default_priority"] = buff.default_priority
	
	if buff.default_interval_time != 0.0:
		dict["default_interval_time"] = buff.default_interval_time
	
	if buff.default_interval_trigger_num != 0:
		dict["default_interval_num"] = buff.default_interval_trigger_num
	
	if buff.is_interval_num_inf:
		dict["is_interval_num_inf"] = true
	
	# 查找stack_type的字符串表示
	for stack_type in GD_Buff.STACK_TYPE:
		if GD_Buff.STACK_TYPE[stack_type] == buff.stack_type:
			dict["stack_type"] = stack_type
			break
	
	if buff.is_disable_override:
		dict["is_disable_override"] = true
	
	if buff.max_layers != 1:
		dict["max_layers"] = buff.max_layers
	
	if buff.is_clear_layers_on_time_end:
		dict["is_layers_exhausted"] = true
	
	return dict

# 静态方法：转换buff资源为JSON字符串
static func buff_to_json(buff: GD_Buff) -> String:
	var dict = buff_to_dict(buff)
	return JSON.stringify(dict)
