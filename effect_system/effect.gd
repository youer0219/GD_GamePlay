class_name Effect
extends Resource

# 效果名称
@export var effect_name: StringName = &""


# 生命周期回调 - 子类可重写这些方法
func _on_apply(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_active(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_stack(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_remove(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_pause(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_resume(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

#func _on_higher_buff_covered(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	#pass
#
#func _on_higher_buff_uncover(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	#pass

func _on_tick(_container: EffectContainer, _runtime_effect: RuntimeEffect, _delta: float) -> void:
	pass

func get_duration()->float:
	return 0.0

func get_runtime_instance()->RuntimeEffect:
	return RuntimeEffect.new()

# 检查与其他效果的堆叠/冲突关系
func can_stack_with(_other_effect: Effect) -> bool:
	return true

func conflicts_with(_other_effect: Effect) -> bool:
	return true
