class_name RuntimeEffect
extends RefCounted

# Effect state enum
enum State {
	INIT,       # Initial state
	APPLIED,    # Applied but not active
	ACTIVE,     # Active (timing)
	REMOVED,    # Removed
}

# Signals for state changes
signal applied(runtime_effect:RuntimeEffect)
signal activated(runtime_effect:RuntimeEffect)
signal removed(runtime_effect:RuntimeEffect)

var effect: Effect = null
var container: EffectContainer = null
var state: int = State.INIT
var duration_time: float = 0.0
var blackboard:Dictionary = {}

func _init(new_effect:Effect,new_container:EffectContainer) -> void:
	self.effect = new_effect
	self.container = new_container
	self.blackboard = new_effect.init_effect_blackboard

func apply() -> void:
	if not _is_base_check_pass():
		return
	
	if state != State.INIT:
		return
	
	effect._on_apply(container, self)
	set_state(State.APPLIED)
	emit_signal("applied")

# Activate effect (APPLIED → ACTIVE)
func activate() -> void:
	if not _is_base_check_pass():
		return
	
	if state != State.APPLIED:
		push_error("Can only activate effects from APPLIED state")
		return
	
	duration_time = effect.get_duration()
	effect._on_active(container, self)
	set_state(State.ACTIVE)
	emit_signal("activated")

# Remove effect (APPLIED/ACTIVE → REMOVED)
func remove() -> void:
	if not _is_base_check_pass():
		return
	
	if state == State.REMOVED:
		return
	
	effect._on_remove(container, self)
	set_state(State.REMOVED)
	emit_signal("removed")

# Process tick (only in ACTIVE state)
func handle_tick(delta: float) -> void:
	if state == State.REMOVED:
		return
	
	if state == State.ACTIVE and is_duration_active():
		duration_time = max(0.0, duration_time - delta)
		if not is_duration_active():  # Duration ended
			remove()
			return
	
	effect._on_tick(container, self, delta)

func stack(_new_effect:Effect):
	if not _is_base_check_pass():
		return
	
	effect._on_stack(container,self)

# 检查与其他效果的堆叠/冲突关系
func can_stack_with(other_effect: Effect) -> bool:
	return effect.can_stack_with(other_effect)

func conflicts_with(other_effect: Effect) -> bool:
	return effect.conflicts_with(other_effect)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func should_active_in_addition()->bool:
	return effect.should_active_in_addition()

func set_state(new_state: int) -> void:
	state = new_state

# Base null check
func _is_base_check_pass() -> bool:
	if effect == null or container == null:
		push_error("Effect or Container is null!")
		return false
	return true
