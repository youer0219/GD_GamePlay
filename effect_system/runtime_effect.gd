class_name RuntimeEffect
extends RefCounted


# Signals for state changes


signal start(runtime_effect:RuntimeEffect)
signal refresh(runtime_effect:RuntimeEffect)
signal interval_trigger(runtime_effect:RuntimeEffect)
signal removed(runtime_effect:RuntimeEffect)

var effect: Effect = null
var container: EffectContainer = null
var duration_time: float = 0.0
var blackboard:Dictionary = {}

func _init(new_effect:Effect,new_container:EffectContainer) -> void:
	self.effect = new_effect
	self.container = new_container
	self.blackboard = new_effect.init_effect_blackboard


func effect_start():
	start.emit()

## effect的每帧执行方法：计时、触发间隔调用
## 间隔调用需要之后实现，因为可能让用户决定开关周期性触发
func effect_process(_delta:float)->void:
	
	pass

func effect_interval_trigger()->void:
	interval_trigger.emit()

func effect_refresh()->void:
	refresh.emit()

func effect_remove()->void:
	removed.emit()


func effect_stack(_new_effect:Effect):
	if not _is_base_check_pass():
		return
	
	effect._on_effect_stack(container,self)

# 检查与其他效果的堆叠/冲突关系
func can_stack_with(other_effect: Effect) -> bool:
	return effect.can_stack_with(other_effect)

func conflicts_with(other_effect: Effect) -> bool:
	return effect.conflicts_with(other_effect)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

# Base null check
func _is_base_check_pass() -> bool:
	if effect == null or container == null:
		push_error("Effect or Container is null!")
		return false
	return true
