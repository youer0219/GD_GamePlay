class_name EffectContainer
extends Node

enum ErrorType {
	NOT_FOUND,
	PARAMETER_IS_NULL
}

# Effect management signals
signal effect_awake(can_free_runtime_effect:RuntimeEffect)
signal effect_started(runtime_effect:RuntimeEffect)
signal effect_refreshed(runtime_effect:RuntimeEffect)
signal effect_interval_triggered(runtime_effect:RuntimeEffect)
signal effect_removed(runtime_effect:RuntimeEffect)

var initial_effects: Array[Effect] = []
## 待添加的效果字典。每帧开始时将其运行时效果实例化、添加到runtime_effects字典中并调用其start方法
var pending_add_effects:Dictionary = {}
var runtime_effects: Dictionary = {} # StringName: RuntimeEffect

func _ready() -> void:
	for effect in initial_effects:
		if effect:
			add_effect(effect)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for runtime_effect:RuntimeEffect in pending_add_effects.values():
		runtime_effects[runtime_effect.effect.effect_name] = runtime_effect
		_connect_runtime_effect(runtime_effect)
		runtime_effect.effect_start()
	
	if not pending_add_effects.is_empty():
		pending_add_effects.clear()
	
	var should_remove_effects:Array[RuntimeEffect] = []
	for runtime_effect:RuntimeEffect in runtime_effects.values():
		runtime_effect.effect_process(delta)
		if runtime_effect.can_remove_effect():
			should_remove_effects.append(runtime_effect)
	for should_remove_effect in should_remove_effects:
		_remove_runtime_effect(should_remove_effect)

func _on_effect_started(runtime_effect: RuntimeEffect) -> void:
	effect_started.emit(runtime_effect)

func _on_effect_refreshed(runtime_effect: RuntimeEffect) -> void:
	effect_refreshed.emit(runtime_effect)

func _on_interval_triggered(runtime_effect: RuntimeEffect) -> void:
	effect_interval_triggered.emit(runtime_effect)

func _on_effect_removed(runtime_effect: RuntimeEffect) -> void:
	effect_removed.emit(runtime_effect)

func add_effect(effect: Effect) -> bool:
	if not effect:
		push_error("The Effect cannot be null.")
		return false
	
	## 重叠和重复检查
	var conflict_runtime_effects: Array[RuntimeEffect] = []
	var stack_runtime_effects: Array[RuntimeEffect] = []
	
	for existing_runtime_effect:RuntimeEffect in get_runtime_effects():
		if existing_runtime_effect.conflicts_with(effect):
			conflict_runtime_effects.append(existing_runtime_effect)
		elif existing_runtime_effect.can_stack_with(effect):
			stack_runtime_effects.append(existing_runtime_effect)
	
	if not conflict_runtime_effects.is_empty():
		return false
	elif not stack_runtime_effects.is_empty():
		stack_runtime_effects[0].effect_stack(effect)
		return false
	
	if has_effect(effect):
		return false
	
	var runtime_effect = effect.get_runtime_instance(self)
	pending_add_effects[effect.effect_name] = runtime_effect
	effect_awake.emit(runtime_effect)
	if runtime_effect == null:
		pending_add_effects.erase(effect.effect_name)
		return false
	
	return true

func remove_effect(effect: Effect) -> bool:
	var runtime_effect:RuntimeEffect = get_runtime_effect(effect)
	return _remove_runtime_effect(runtime_effect)

func _remove_runtime_effect(runtime_effect:RuntimeEffect)->bool:
	if runtime_effect == null:
		push_error("Attempted to remove unexisting effect")
		return false
	
	runtime_effect.effect_remove()
	
	if pending_add_effects.has(runtime_effect.effect.effect_name): ## 通过不在pending_add_effects内判断其位置且 pending_add_effects 一般很小
		pending_add_effects.erase(runtime_effect.effect.effect_name)
	else:
		runtime_effects.erase(runtime_effect.effect.effect_name)
		_disconnect_runtime_effect(runtime_effect)
	
	return true

func has_effect(effect: Effect) -> bool:
	if pending_add_effects.has(effect.effect_name):
		return true
	return runtime_effects.has(effect.effect_name)

func get_runtime_effect(effect: Effect) -> RuntimeEffect:
	var runtime_effect = runtime_effects.get(effect.effect_name)
	return runtime_effect if runtime_effect != null else pending_add_effects.get(effect.effect_name)

func get_runtime_effects()->Array[RuntimeEffect]:
	var all_runtime_effects:Array[RuntimeEffect] = []
	all_runtime_effects.append_array(pending_add_effects.values())
	all_runtime_effects.append_array(runtime_effects.values())
	return all_runtime_effects

func get_initial_effects() -> Array[Effect]:
	return initial_effects

func _connect_runtime_effect(runtime_effect:RuntimeEffect):
	runtime_effect.started.connect(_on_effect_started.bind(runtime_effect))
	runtime_effect.refreshed.connect(_on_effect_refreshed.bind(runtime_effect))
	runtime_effect.interval_triggered.connect(_on_interval_triggered.bind(runtime_effect))
	runtime_effect.removed.connect(_on_effect_removed.bind(runtime_effect))

func _disconnect_runtime_effect(runtime_effect:RuntimeEffect):
	runtime_effect.started.disconnect(_on_effect_started)
	runtime_effect.refreshed.disconnect(_on_effect_refreshed)
	runtime_effect.interval_triggered.disconnect(_on_interval_triggered)
	runtime_effect.removed.disconnect(_on_effect_removed)
