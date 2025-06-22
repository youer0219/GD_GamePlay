class_name Effect
extends Resource

@export var effect_name: StringName = &""
@export var init_effect_blackboard: Dictionary = {}
@export var duration: float = 0.0
@export var interval: float = 0.0

func _on_effect_awake() -> void:
	pass

func _on_effect_start(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_effect_process(_container: EffectContainer, _runtime_effect: RuntimeEffect, _delta: float) -> void:
	pass

func _on_effect_refresh(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_effect_interval_trigger(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_effect_remove(_container: EffectContainer, _runtime_effect: RuntimeEffect) -> void:
	pass

func _on_effect_stack(_container: EffectContainer, _runtime_effect: RuntimeEffect, _new_effect:Effect) -> void:
	pass

func get_duration() -> float:
	return duration

func get_interval() -> float:
	return interval

func get_runtime_instance(container: EffectContainer) -> RuntimeEffect:
	return RuntimeEffect.new(self, container)

func can_stack_with(_other_effect: Effect) -> bool:
	return false

func conflicts_with(_other_effect: Effect) -> bool:
	return false

func can_remove_effect(_container: EffectContainer, runtime_effect: RuntimeEffect)->bool:
	return not runtime_effect.is_duration_active()
