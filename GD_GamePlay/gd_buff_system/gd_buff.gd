class_name GD_Buff
extends Resource

enum STACK_TYPE {
	PRIORITY,
	STACK,
	UNIQUE,
	REFRESH,
	ADD_TIME,
}

@export var buff_name: StringName = &""
@export var override_buff_name:StringName = &"":
	get():
		return buff_name if override_buff_name == &"" else override_buff_name
@export var init_buff_blackboard: Dictionary = {}
@export var default_duration: float = 0.0
@export var is_default_duration_inf:bool = false
@export var default_priority: int = 0
@export var default_interval_time:float = 0.0
@export var default_interval_num:int = 0
@export var is_interval_num_inf:bool = false
@export var stack_type:STACK_TYPE = STACK_TYPE.PRIORITY
@export var is_disable_override:bool = false
@export var max_layers:int = 1
@export var is_layers_exhausted:bool = false

func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_process(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, delta: float) -> void:
	if runtime_buff.enable and (runtime_buff.curr_interval_num > 0 or is_interval_num_inf):
		runtime_buff.curr_interval_time += delta
		if runtime_buff.curr_interval_time >= get_interval_time():
			runtime_buff.curr_interval_num = max(0,runtime_buff.curr_interval_num - 1)
			runtime_buff.curr_interval_time = 0.0
			_on_buff_interval_trigger(container,runtime_buff)
	
	runtime_buff.duration_time -= delta * runtime_buff.duration_time_flow_rate
	
	if not runtime_buff.is_duration_active():
		_on_buff_time_end(container,runtime_buff)

func _on_buff_stack(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, new_runtime_buff: GD_RuntimeBuff) -> void:
	match stack_type:
		STACK_TYPE.STACK:
			## 层数叠加
			var is_over:bool = runtime_buff.layer == max_layers
			runtime_buff.layer += 1 if not is_over else 0
			_on_stack_layer_change(container,runtime_buff,new_runtime_buff,is_over)
		STACK_TYPE.REFRESH:
			## 延长持续时间至MAX(已存在Buff剩余持续时间，新Buff持续时间)
			runtime_buff.duration_time = max(runtime_buff.duration_time,new_runtime_buff.get_duration())
		STACK_TYPE.ADD_TIME:
			## 加时
			runtime_buff.duration_time = runtime_buff.duration_time + new_runtime_buff.get_duration()
		STACK_TYPE.UNIQUE:
			## 仅保留最早一个同覆写名的Buff。不需要做任何事情。
			pass
		STACK_TYPE.PRIORITY:
			## 优先级机制：同级不操作。低级buff失效、更新higher-buff数量、订阅高级buff的移除信号。
			_stack_priority_handler(runtime_buff,new_runtime_buff)

func _on_stack_layer_change(_container: GD_BuffContainer,_runtime_buff: GD_RuntimeBuff,_new_runtime_buff: GD_RuntimeBuff,_is_over:bool):
	pass

func _on_buff_interval_trigger(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_time_end(_container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff):
	if stack_type == STACK_TYPE.STACK:
		if is_layers_exhausted:
			runtime_buff.layer = 0
		else:
			runtime_buff.layer -= 1
			if runtime_buff.layer > 0:
				runtime_buff.duration_time = runtime_buff.get_duration()

func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_exist_buff_enable(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff)->void:
	pass

func _on_exist_buff_disenable(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff)->void:
	pass

func get_duration(_container:GD_BuffContainer)->float:
	return default_duration if not is_default_duration_inf else INF

func get_priority()->int:
	return default_priority 

func get_interval_time()->float:
	return default_interval_time

## int类型不支持INF。如有需求，请检查其is_interval_num_inf属性。
func get_default_interval_num()->int:
	return default_interval_num

func get_runtime_instance(container: GD_BuffContainer) -> GD_RuntimeBuff:
	return GD_RuntimeBuff.new(self, container)

func can_stack_with(other_buff: GD_Buff) -> bool:
	return (override_buff_name == other_buff.override_buff_name) and !is_disable_override

func conflicts_with(_other_buff: GD_Buff) -> bool:
	return false

func should_remove_buff_after_process(_container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff)->bool:
	return not runtime_buff.is_duration_active()

func should_remove_after_stack()->bool:
	return stack_type != STACK_TYPE.PRIORITY

func _stack_priority_handler(runtime_buff:GD_RuntimeBuff,new_runtime_buff:GD_RuntimeBuff):
	if new_runtime_buff.buff.get_priority() == get_priority():
		return
	var low_priority_runtimebuff:GD_RuntimeBuff = runtime_buff if new_runtime_buff.buff.get_priority() > get_priority() else new_runtime_buff
	var higher_priority_runtimebuff:GD_RuntimeBuff = runtime_buff if new_runtime_buff.buff.get_priority() < get_priority() else new_runtime_buff
	low_priority_runtimebuff.higher_buff_num += 1
	low_priority_runtimebuff.enable = false
	var weak_runtime_buff = weakref(low_priority_runtimebuff)
	higher_priority_runtimebuff.removed.connect(
		func():
			var target = weak_runtime_buff.get_ref()
			if target:
				target.higher_buff_num -= 1
	, CONNECT_ONE_SHOT | CONNECT_REFERENCE_COUNTED)
