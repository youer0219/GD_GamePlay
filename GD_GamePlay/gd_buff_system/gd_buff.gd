class_name GD_Buff
extends Resource

enum STACK_TYPE {
	DEFAULT,
	STACK,
	UNIQUE,
	EXTEND,
	EXTEND_TIME,
}

@export var buff_name: StringName = &""
@export var override_buff_name:StringName = buff_name
@export var init_buff_blackboard: Dictionary = {}
@export var default_duration: float = 0.0
@export var stack_type:STACK_TYPE = STACK_TYPE.DEFAULT
@export var max_layers:int = 1


func _on_buff_awake(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_start(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff) -> void:
	pass

func _on_buff_process(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _delta: float) -> void:
	pass

func _on_buff_refresh(_container: GD_BuffContainer, _runtime_buff: GD_RuntimeBuff, _new_buff:GD_Buff) -> void:
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
	return stack_type != STACK_TYPE.DEFAULT
