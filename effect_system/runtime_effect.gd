class_name RuntimeEffect
extends RefCounted

# Signals for state changes
signal started(runtime_effect: RuntimeEffect)  # 重命名为started以保持一致性
signal refreshed(runtime_effect: RuntimeEffect)
signal interval_triggered(runtime_effect: RuntimeEffect)  # 重命名为interval_triggered
signal removed(runtime_effect: RuntimeEffect)

var effect: Effect = null
var container: EffectContainer = null
var duration_time: float = 0.0
var blackboard: Dictionary = {}
#var _interval_timer: float = 0.0  # 添加间隔计时器

func _init(new_effect: Effect, new_container: EffectContainer) -> void:
	if not new_effect or not new_container:
		push_error("Effect or Container cannot be null!")
		return
		
	self.effect = new_effect
	self.container = new_container
	self.blackboard = new_effect.init_effect_blackboard.duplicate(true)
	#self._interval_timer = 0.0
	self.duration_time = effect.get_duration()

func effect_start() -> void:
	if not _is_base_check_pass():
		return
		
	effect._on_effect_start(container, self)
	started.emit(self)

func effect_process(delta: float) -> void:
	if not _is_base_check_pass():
		return
	
	# 处理持续时间
	duration_time = max(0.0, duration_time - delta)
	
	## 处理间隔触发
	#var interval = effect.get_interval()
	#if interval > 0.0:
		#_interval_timer += delta
		#if _interval_timer >= interval:
			#_interval_timer = 0.0
			#effect_interval_trigger()
	
	effect._on_effect_process(container, self, delta)

func effect_interval_trigger() -> void:
	if not _is_base_check_pass():
		return
		
	effect._on_effect_interval_trigger(container, self)
	interval_triggered.emit()

func effect_refresh() -> void:
	if not _is_base_check_pass():
		return
		
	effect._on_effect_refresh(container, self)
	refreshed.emit()

func effect_remove() -> void:
	if not _is_base_check_pass():
		return
	
	effect._on_effect_remove(container, self)
	removed.emit()

func effect_stack(new_effect: Effect) -> void:
	if not _is_base_check_pass() or not new_effect:
		return
		
	effect._on_effect_stack(container, self , new_effect)

func can_stack_with(other_effect: Effect) -> bool:
	return effect.can_stack_with(other_effect)

func conflicts_with(other_effect: Effect) -> bool:
	return effect.conflicts_with(other_effect)

func can_remove_effect()->bool:
	return effect.can_remove_effect(container,self)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func _is_base_check_pass() -> bool:
	if effect == null or container == null:
		push_error("Effect or Container is null!")
		return false
	return true
