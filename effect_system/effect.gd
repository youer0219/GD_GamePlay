class_name Effect
extends Resource

# 效果名称
@export var effect_name: StringName = &""
@export var init_effect_blackboard:Dictionary = {}

# 生命周期回调 - 子类可重写这些方法
func _on_apply(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_active(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_stack(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_remove(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_tick(_container: EffectContainer, _runtime_effect: RuntimeEffect, _delta: float) -> void:
	pass

func get_duration()->float:
	return 0.0

func get_runtime_instance(container:EffectContainer)->RuntimeEffect:
	return RuntimeEffect.new(self,container)

# 检查与其他效果的堆叠/冲突关系
func can_stack_with(_other_effect: Effect) -> bool:
	return false

func conflicts_with(_other_effect: Effect) -> bool:
	return false

func should_active_in_addition()->bool:
	return true
