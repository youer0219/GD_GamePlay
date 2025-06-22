class_name Effect
extends Resource
## Effect

## Effect名称。查询唯一标识。
@export var effect_name: StringName = &""
@export var init_effect_blackboard:Dictionary = {}


func _on_effect_awake()->void:
	pass

func _on_effect_start(_container: EffectContainer, _runtime_effect: RuntimeEffect)->void:
	pass

func _on_effect_process(_container: EffectContainer, _runtime_effect: RuntimeEffect,_delta:float)->void:
	pass

func _on_effect_refresh(_container: EffectContainer, _runtime_effect: RuntimeEffect)->void:
	pass

func _on_effect_interval_trigger(_container: EffectContainer, _runtime_effect: RuntimeEffect)->void:
	pass

func _on_effect_remove(_container: EffectContainer, _runtime_effect: RuntimeEffect)->void:
	pass

func _on_effect_stack(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func get_duration()->float:
	return 0.0

## 方便使用重写的RuntimeEffect子类
func get_runtime_instance(container:EffectContainer)->RuntimeEffect:
	return RuntimeEffect.new(self,container)

## 检查与其他效果的堆叠关系
func can_stack_with(_other_effect: Effect) -> bool:
	return false

## 检查与其他效果的冲突关系
func conflicts_with(_other_effect: Effect) -> bool:
	return false
