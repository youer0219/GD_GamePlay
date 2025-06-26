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
@export var override_buff_name:StringName
@export var init_buff_blackboard: Dictionary = {}
@export var default_duration: float = 0.0
@export var is_default_duration_inf:bool = false
@export var default_priority: int = 0
@export var default_interval_time:float = 0.0
@export var default_interval_num:int = 0
@export var is_interval_num_inf:bool = false
@export var stack_type:STACK_TYPE = STACK_TYPE.PRIORITY
@export var max_layers:int = 1

func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_process(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, delta: float) -> void:
	
	runtime_buff.duration_time -= delta
	
	if runtime_buff.enable and (runtime_buff.curr_interval_num > 0 or is_interval_num_inf):
		runtime_buff.curr_interval_time += delta
		if runtime_buff.curr_interval_time >= get_interval_time():
			runtime_buff.curr_interval_num = max(0,runtime_buff.curr_interval_num - 1)
			runtime_buff.curr_interval_time = 0.0
			_on_buff_interval_trigger(container,runtime_buff)

func _on_buff_stack(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, new_runtime_buff: GD_RuntimeBuff) -> void:
	match stack_type:
		STACK_TYPE.STACK:
			## 层数叠加
			var is_over:bool = runtime_buff.layer == max_layers
			runtime_buff.layer += 1 if not is_over else 0
			_on_layer_change(container,runtime_buff,new_runtime_buff,is_over)
		STACK_TYPE.REFRESH:
			## 延长持续时间至MAX(已存在Buff剩余持续时间，新Buff持续时间)
			## TODO: 未来get_duration可能加入容器参数。请谨慎考虑。
			runtime_buff.duration_time = max(runtime_buff.duration_time,new_runtime_buff.buff.get_duration())
		STACK_TYPE.ADD_TIME:
			## 加时
			runtime_buff.duration_time = runtime_buff.duration_time + new_runtime_buff.buff.get_duration()
		STACK_TYPE.UNIQUE:
			## 仅保留最早一个同覆写名的Buff。不需要做任何事情。
			pass
		STACK_TYPE.PRIORITY:
			## 默认优先级机制
			## 如果新buff优先级比自己高，执行以下操作：
			## 1.使自己失效；2.更新higher-buff数量；3.订阅buff的移除信号
			## 如果新buff优先级比自己低，对新buff做上面的操作
			var new_runtime_buff_priority := new_runtime_buff.buff.get_priority()
			if new_runtime_buff_priority > get_priority():
				runtime_buff.higher_buff_num += 1
				runtime_buff.enable = false
				var weak_runtime_buff = weakref(runtime_buff)
				new_runtime_buff.removed.connect(
					func():
						var target = weak_runtime_buff.get_ref()
						if target:
							target.higher_buff_num -= 1
				, CONNECT_ONE_SHOT | CONNECT_REFERENCE_COUNTED)
			elif new_runtime_buff_priority < get_priority():
				new_runtime_buff.higher_buff_num += 1
				new_runtime_buff.enable = false
				var weak_runtime_buff = weakref(new_runtime_buff)
				runtime_buff.removed.connect(
					func():
						var target = weak_runtime_buff.get_ref()
						if target:
							target.higher_buff_num -= 1
				, CONNECT_ONE_SHOT | CONNECT_REFERENCE_COUNTED)

func _on_layer_change(_container: GD_BuffContainer,_runtime_buff: GD_RuntimeBuff,_new_runtime_buff: GD_RuntimeBuff,_is_over:bool):
	pass

func _on_buff_interval_trigger(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_exist_buff_enable(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff)->void:
	pass

func _on_exist_buff_disenable(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff)->void:
	pass

func get_duration()->float:
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
	return override_buff_name == other_buff.override_buff_name

func conflicts_with(_other_buff: GD_Buff) -> bool:
	return false

func can_remove_buff(_container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff)->bool:
	return not runtime_buff.is_duration_active()

func should_remove_after_stack()->bool:
	return stack_type != STACK_TYPE.PRIORITY
