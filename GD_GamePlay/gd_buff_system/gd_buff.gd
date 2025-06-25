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
@export var stack_type:STACK_TYPE = STACK_TYPE.PRIORITY
@export var max_layers:int = 1

func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_process(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _delta: float) -> void:
	pass

func _on_buff_stack(container: GD_BuffContainer, runtime_buff: GD_RuntimeBuff, new_buff: GD_Buff) -> void:
	match stack_type:
		STACK_TYPE.STACK:
			## 层数叠加
			var is_over:bool = runtime_buff.layer == max_layers
			if not is_over:
				runtime_buff.layer += 1
			_on_layer_change(container,runtime_buff,new_buff,is_over)
		STACK_TYPE.REFRESH:
			## 延长持续时间至MAX(已存在Buff剩余持续时间，新Buff持续时间)
			## TODO: 未来get_duration可能加入容器参数。请谨慎考虑。
			runtime_buff.duration_time = max(runtime_buff.duration_time,new_buff.get_duration())
		STACK_TYPE.ADD_TIME:
			## 加时
			runtime_buff.duration_time = runtime_buff.duration_time + new_buff.get_duration()
		STACK_TYPE.UNIQUE:
			## 仅保留最早一个同覆写名的Buff。不需要做任何事情。
			pass
		STACK_TYPE.PRIORITY:
			## 默认优先级机制；暂未实现;
			pass

func _on_layer_change(_container: GD_BuffContainer,_runtime_buff: GD_RuntimeBuff,_new_buff: GD_Buff,_is_over:bool):
	pass

# 暂时不实现
#func _on_buff_interval_trigger(_container: BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	#pass

func _on_buff_remove(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func get_duration() -> float:
	return default_duration

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
