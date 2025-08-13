extends Node
class_name MyBuff

var _init_data: Array

func _init(param1 = null, param2 = null):
	_init_data = [param1, param2]

func get_init_data() -> Array:
	return _init_data
