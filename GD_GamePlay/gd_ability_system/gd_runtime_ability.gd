# runtime_ability.gd
class_name GD_RuntimeAbility
extends RefCounted

# 运行时状态变化信号
signal activated
signal blocked
signal ended
signal granted
signal revoked
signal unblocked
signal cooldown_started
signal cooldown_ended

enum AbilityState {
	IDLE = 1,
	ACTIVE = 2,
	BLOCKED = 4,
	COOLING_DOWN = 8,
	GRANTED = 16
}

var ability: GD_Ability = null
var container: GD_AbilityContainer = null
var state: int = AbilityState.IDLE
var cooldown_time: float = 0.0
var duration_time: float = 0.0

func activate() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_ACTIVATING
	
	if is_revoked():
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE_IS_REVOKED
	
	if is_blocked():
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE_IS_BLOCKED
	
	if should_be_blocked() and block() == GD_Ability.AbilityEventType.BLOCKED:
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE_DECIDED_TO_BLOCK
	
	if is_duration_active():
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE_IS_DURATION_ACTIVE
	
	if is_cooldown_active():
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE_IS_COOLING_DOWN
	
	if ability._can_be_activated(container, self):
		ability._on_activate(container, self)
		_set_state(GD_Ability.AbilityEventType.ACTIVATED)
		emit_signal("activated")
		
		if trigger_duration():
			return GD_Ability.AbilityEventType.ACTIVATED_DURATION_STARTED
		
		if trigger_cooldown():
			return GD_Ability.AbilityEventType.ACTIVATED_COOLDOWN_STARTED
		
		return GD_Ability.AbilityEventType.ACTIVATED
	else:
		_set_state(GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE)
		return GD_Ability.AbilityEventType.REFUSED_TO_ACTIVATE

func block() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_BLOCKING
	
	if not (state & AbilityState.GRANTED) == AbilityState.GRANTED:
		return GD_Ability.AbilityEventType.REFUSED_TO_BLOCK_IS_NOT_GRANTED
	
	if ability._can_be_blocked(container, self):
		ability._on_block(container, self)
		_set_state(GD_Ability.AbilityEventType.BLOCKED)
		emit_signal("blocked")
		try_reset_cooldown()
		try_reset_duration()
		return GD_Ability.AbilityEventType.BLOCKED
	else:
		_set_state(GD_Ability.AbilityEventType.REFUSED_TO_BLOCK)
		return GD_Ability.AbilityEventType.REFUSED_TO_BLOCK

func end() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_ENDING
	
	if (state & AbilityState.BLOCKED) == AbilityState.BLOCKED:
		return GD_Ability.AbilityEventType.REFUSED_TO_END_IS_BLOCKED
	
	if not ((state & AbilityState.ACTIVE) == AbilityState.ACTIVE or (state & AbilityState.COOLING_DOWN) == AbilityState.COOLING_DOWN):
		return GD_Ability.AbilityEventType.REFUSED_TO_END_IS_COOLING_DOWN
	
	if (state & AbilityState.COOLING_DOWN) == AbilityState.COOLING_DOWN and not is_zero_approx(cooldown_time):
		return GD_Ability.AbilityEventType.REFUSED_TO_END
	
	if not (state & AbilityState.GRANTED) == AbilityState.GRANTED:
		return GD_Ability.AbilityEventType.REFUSED_TO_END_IS_NOT_GRANTED
	
	if ability._can_be_ended(container, self):
		ability._on_end(container, self)
		_set_state(GD_Ability.AbilityEventType.ENDED)
		emit_signal("ended")
		try_reset_cooldown()
		try_reset_duration()
		return GD_Ability.AbilityEventType.ENDED
	else:
		_set_state(GD_Ability.AbilityEventType.REFUSED_TO_END)
		return GD_Ability.AbilityEventType.REFUSED_TO_END

func get_ability() -> GD_Ability:
	return ability

func get_container() -> GD_AbilityContainer:
	return container

func get_cooldown() -> float:
	return ability._get_cooldown(container) if ability != null else 0.0

func get_duration() -> float:
	return ability._get_duration(container) if ability != null else 0.0

func grant() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_GRANTING
	
	if (state & AbilityState.GRANTED) == AbilityState.GRANTED:
		return GD_Ability.AbilityEventType.REFUSED_TO_GRANT_ALREADY_GRANTED
	
	if ability._can_be_granted(container, self):
		ability._on_grant(container, self)
		_set_state(GD_Ability.AbilityEventType.GRANTED)
		emit_signal("granted")
		return GD_Ability.AbilityEventType.GRANTED
	else:
		_set_state(GD_Ability.AbilityEventType.REFUSED_TO_GRANT)
		return GD_Ability.AbilityEventType.REFUSED_TO_GRANT

func is_active() -> bool:
	return (state & AbilityState.ACTIVE) == AbilityState.ACTIVE

func is_blocked() -> bool:
	return (state & AbilityState.BLOCKED) == AbilityState.BLOCKED

func is_cooldown_active() -> bool:
	return not is_zero_approx(cooldown_time)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func is_ended() -> bool:
	return not ((state & AbilityState.ACTIVE) == AbilityState.ACTIVE or (state & AbilityState.BLOCKED) == AbilityState.BLOCKED) and (state & AbilityState.GRANTED) == AbilityState.GRANTED

func is_granted() -> bool:
	return (state & AbilityState.GRANTED) == AbilityState.GRANTED

func is_revoked() -> bool:
	return not (state & AbilityState.GRANTED) == AbilityState.GRANTED

func revoke() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_REVOKING
	
	if not (state & AbilityState.GRANTED) == AbilityState.GRANTED:
		return GD_Ability.AbilityEventType.REFUSED_TO_REVOKE_ALREADY_REVOKED
	
	if ability._can_be_revoked(container, self):
		ability._on_revoke(container, self)
		_set_state(GD_Ability.AbilityEventType.REVOKED)
		if not is_zero_approx(cooldown_time):
			emit_signal("cooldown_end")
		cooldown_time = 0.0
		duration_time = 0.0
		emit_signal("revoked")
		return GD_Ability.AbilityEventType.REVOKED
	else:
		_set_state(GD_Ability.AbilityEventType.REFUSED_TO_REVOKE)
		return GD_Ability.AbilityEventType.REFUSED_TO_REVOKE

func set_ability(p_ability: GD_Ability) -> void:
	ability = p_ability
	state = AbilityState.IDLE

func set_container(p_container: GD_AbilityContainer) -> void:
	container = p_container
	cooldown_time = 0.0

func should_be_activated() -> bool:
	return ability._should_be_activated(container) if ability != null else false

func should_be_blocked() -> bool:
	return ability._should_be_blocked(container) if ability != null else false

func should_be_ended() -> bool:
	return ability._should_be_ended(container) if ability != null else true

func unblock() -> GD_Ability.AbilityEventType:
	if ability == null or container == null:
		return GD_Ability.AbilityEventType.ERROR_UNBLOCKING
	
	if not (state & AbilityState.BLOCKED) == AbilityState.BLOCKED:
		return GD_Ability.AbilityEventType.REFUSED_TO_UNBLOCK_IS_NOT_BLOCKED
	
	if ability._should_be_blocked(container):
		return GD_Ability.AbilityEventType.REFUSED_TO_UNBLOCK_SHOULD_BE_BLOCKED
	
	_set_state(GD_Ability.AbilityEventType.UNBLOCKED)
	emit_signal("unblocked")
	return GD_Ability.AbilityEventType.UNBLOCKED

func handle_tick(delta: float) -> void:
	if ability == null or container == null:
		return
	
	if ability.has_method("_on_tick"):
		ability._on_tick.call(delta, cooldown_time, container, self)
		return
	
	if should_be_blocked() and block() == GD_Ability.AbilityEventType.BLOCKED:
		return
	
	if is_active() and is_duration_active():
		duration_time = clamp(duration_time - delta, 0.0, get_duration())
		if not is_duration_active():
			trigger_cooldown()
		return
	
	if (state & AbilityState.COOLING_DOWN) == AbilityState.COOLING_DOWN and is_cooldown_active():
		cooldown_time = clamp(cooldown_time - delta, 0.0, get_cooldown())
		if not is_cooldown_active():
			emit_signal("cooldown_ended")
		return
	
	if should_be_ended():
		end()
	
	if not should_be_activated():
		return
	
	activate()

func trigger_cooldown() -> bool:
	var cooldown = get_cooldown()
	if not is_zero_approx(cooldown):
		var should_activate_cooldown = false
		if ability.has_method("_can_activate_cooldown"):
			should_activate_cooldown = ability._can_activate_cooldown.call(container, self)
		else:
			should_activate_cooldown = true
		
		if should_activate_cooldown:
			cooldown_time = cooldown
		
		_set_state(GD_Ability.AbilityEventType.ACTIVATED_COOLDOWN_STARTED)
		emit_signal("cooldown_started")
		return true
	return false

func trigger_duration() -> bool:
	var duration = get_duration()
	if not is_zero_approx(duration):
		duration_time = duration
		return true
	return false

func try_reset_cooldown() -> void:
	var should_reset_cooldown = not is_zero_approx(cooldown_time)
	if ability.has_method("_should_reset_cooldown"):
		should_reset_cooldown = ability._should_reset_cooldown.call(container)
	
	if should_reset_cooldown:
		cooldown_time = 0.0
		emit_signal("cooldown_ended")

func try_reset_duration() -> void:
	var should_reset_duration = true
	if ability.has_method("_should_reset_duration"):
		should_reset_duration = ability._should_reset_duration.call(container)
	
	if should_reset_duration:
		duration_time = 0.0

func _set_state(event_type: GD_Ability.AbilityEventType) -> void:
	match event_type:
		GD_Ability.AbilityEventType.ACTIVATED:
			state &= ~AbilityState.IDLE
			state |= AbilityState.ACTIVE
		GD_Ability.AbilityEventType.ACTIVATED_COOLDOWN_STARTED:
			state &= ~AbilityState.ACTIVE
			state |= AbilityState.COOLING_DOWN
		GD_Ability.AbilityEventType.BLOCKED:
			state &= ~AbilityState.ACTIVE
			state &= ~AbilityState.COOLING_DOWN
			state &= ~AbilityState.IDLE
			state |= AbilityState.BLOCKED
		GD_Ability.AbilityEventType.ENDED:
			state &= ~AbilityState.ACTIVE
			state &= ~AbilityState.COOLING_DOWN
			state |= AbilityState.IDLE
		GD_Ability.AbilityEventType.GRANTED:
			state &= ~AbilityState.ACTIVE
			state &= ~AbilityState.BLOCKED
			state &= ~AbilityState.COOLING_DOWN
			state |= AbilityState.IDLE
			state |= AbilityState.GRANTED
		GD_Ability.AbilityEventType.REVOKED:
			state &= ~AbilityState.ACTIVE
			state &= ~AbilityState.BLOCKED
			state &= ~AbilityState.COOLING_DOWN
			state &= ~AbilityState.GRANTED
			state &= ~AbilityState.IDLE
		GD_Ability.AbilityEventType.UNBLOCKED:
			state &= ~AbilityState.ACTIVE
			state &= ~AbilityState.BLOCKED
			state |= AbilityState.IDLE
