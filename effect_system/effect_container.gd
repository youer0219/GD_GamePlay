class_name EffectContainer
extends Node

enum ErrorType {
	NOT_FOUND,
	PARAMETER_IS_NULL
}

# Effect management signals
signal effect_applied(runtime_effect:RuntimeEffect)
signal effect_activated(runtime_effect:RuntimeEffect)
signal effect_removed(runtime_effect:RuntimeEffect)
signal effect_ended(runtime_effect:RuntimeEffect)

var initial_effects: Array[Effect] = []
var runtime_effects: Dictionary = {} # StringName: RuntimeEffect

func _ready() -> void:
	for effect in initial_effects:
		if effect:
			add_effect(effect)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	# Process all effect ticks
	for runtime_effect in runtime_effects.values():
		if runtime_effect and runtime_effect.state == RuntimeEffect.State.ACTIVE:
			runtime_effect.handle_tick(delta)

func _on_effect_applied(runtime_effect: RuntimeEffect) -> void:
	emit_signal("effect_applied", runtime_effect)

func _on_effect_activated(runtime_effect: RuntimeEffect) -> void:
	emit_signal("effect_activated", runtime_effect)

func _on_effect_removed(runtime_effect: RuntimeEffect) -> void:
	emit_signal("effect_removed", runtime_effect)

func _on_effect_ended(runtime_effect: RuntimeEffect) -> void:
	emit_signal("effect_ended", runtime_effect)

func add_effect(effect: Effect) -> bool:
	if not effect:
		push_error("The Effect cannot be null.")
		return false
	
	# Check for conflicts and stacking
	var conflict_runtime_effects: Array[RuntimeEffect] = []
	var stack_runtime_effects: Array[RuntimeEffect] = []
	
	for existing_runtime_effect:RuntimeEffect in runtime_effects.values():
		if existing_runtime_effect.conflicts_with(effect):
			conflict_runtime_effects.append(existing_runtime_effect)
		elif existing_runtime_effect.can_stack_with(effect):
			stack_runtime_effects.append(existing_runtime_effect)
	
	if not conflict_runtime_effects.is_empty():
		return false
	elif not stack_runtime_effects.is_empty():
		stack_runtime_effects[0].stack(effect)
		return false
	
	# Add new effect if no conflicts and no stacking
	if not has_effect(effect):
		var runtime_effect = effect.get_runtime_instance()
		runtime_effect.effect = effect
		runtime_effect.container = self
		
		runtime_effects[effect.effect_name] = runtime_effect
		
		# Connect signals
		runtime_effect.connect("applied", _on_effect_applied.bind(runtime_effect))
		runtime_effect.connect("activated", _on_effect_activated.bind(runtime_effect))
		runtime_effect.connect("removed", _on_effect_removed.bind(runtime_effect))
		
		# Apply and activate the effect
		runtime_effect.apply()
		if runtime_effect.state == RuntimeEffect.State.APPLIED and runtime_effect.should_active_in_addition():
			runtime_effect.activate()
		
		return true
	
	return false

func get_runtime_effect(effect: Effect) -> RuntimeEffect:
	return runtime_effects.get(effect.effect_name)

func get_runtime_effects() -> Array[RuntimeEffect]:
	return Array(runtime_effects.values(), TYPE_OBJECT, "RefCounted", RuntimeEffect)

func get_initial_effects() -> Array[Effect]:
	return initial_effects

func has_effect(effect: Effect) -> bool:
	return runtime_effects.has(effect.effect_name)

func is_effect_active(effect: Effect) -> bool:
	var runtime_effect = get_runtime_effect(effect)
	return runtime_effect and runtime_effect.state == RuntimeEffect.State.ACTIVE

func is_effect_applied(effect: Effect) -> bool:
	var runtime_effect = get_runtime_effect(effect)
	return runtime_effect and runtime_effect.state == RuntimeEffect.State.APPLIED

func remove_effect(effect: Effect) -> bool:
	if has_effect(effect):
		var runtime_effect = runtime_effects[effect.effect_name]
		
		if runtime_effect.state != RuntimeEffect.State.REMOVED:
			runtime_effect.remove()
		
		runtime_effect.disconnect("applied", _on_effect_applied.bind(runtime_effect))
		runtime_effect.disconnect("activated", _on_effect_activated.bind(runtime_effect))
		runtime_effect.disconnect("removed", _on_effect_removed.bind(runtime_effect))
		
		runtime_effects.erase(effect.effect_name)
		emit_signal("effect_removed", effect)
		return true
	return false

func set_initial_effects(effects: Array[Effect]) -> void:
	initial_effects = effects

func try_apply(effect: Effect) -> bool:
	var runtime_effect = get_runtime_effect(effect)
	if runtime_effect and runtime_effect.state == RuntimeEffect.State.INIT:
		runtime_effect.apply()
		return runtime_effect.state == RuntimeEffect.State.APPLIED
	return false

func try_activate(effect: Effect) -> bool:
	var runtime_effect = get_runtime_effect(effect)
	if runtime_effect and runtime_effect.state == RuntimeEffect.State.APPLIED:
		runtime_effect.activate()
		return runtime_effect.state == RuntimeEffect.State.ACTIVE
	return false

func try_remove(effect: Effect) -> bool:
	var runtime_effect = get_runtime_effect(effect)
	if runtime_effect and runtime_effect.state != RuntimeEffect.State.REMOVED:
		runtime_effect.remove()
		return runtime_effect.state == RuntimeEffect.State.REMOVED
	return false
