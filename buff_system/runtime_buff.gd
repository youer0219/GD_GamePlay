# runtime_buff.gd
class_name RuntimeBuff
extends RefCounted

# runtime state change signals
signal activated
signal blocked
signal ended
signal granted
signal revoked
signal unblocked
signal cooldown_started
signal cooldown_ended
#signal duration_started
#signal duration_ended

enum BuffState {
	IDLE = 1,
	ACTIVE = 2,
	BLOCKED = 4,
	COOLING_DOWN = 8,
	GRANTED = 16
}

var buff: Buff = null
var container: BuffContainer = null
var state: int = BuffState.IDLE
var cooldown_time: float = 0.0
var duration_time: float = 0.0

func activate() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_ACTIVATING
	
	if is_revoked():
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE_IS_REVOKED
	
	if is_blocked():
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE_IS_BLOCKED
	
	if should_be_blocked() and block() == Buff.BuffEventType.BLOCKED:
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE_DECIDED_TO_BLOCK
	
	if is_duration_active():
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE_IS_DURATION_ACTIVE
	
	if is_cooldown_active():
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE_IS_COOLING_DOWN
	
	if buff._can_be_activated(container, self):
		if buff._on_activate(container, self):
			_set_state(Buff.BuffEventType.ACTIVATED)
			emit_signal("activated")
			
			if trigger_duration():
				return Buff.BuffEventType.ACTIVATED_DURATION_STARTED
			
			if trigger_cooldown():
				return Buff.BuffEventType.ACTIVATED_COOLDOWN_STARTED
			
			return Buff.BuffEventType.ACTIVATED
		else:
			_set_state(Buff.BuffEventType.ERROR_ACTIVATING)
			return Buff.BuffEventType.ERROR_ACTIVATING
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_ACTIVATE)
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE

func block() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_BLOCKING
	
	if not (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_BLOCK_IS_NOT_GRANTED
	
	if buff._can_be_blocked(container, self):
		if buff._on_block(container, self):
			_set_state(Buff.BuffEventType.BLOCKED)
			emit_signal("blocked")
			try_reset_cooldown()
			try_reset_duration()
			return Buff.BuffEventType.BLOCKED
		else:
			_set_state(Buff.BuffEventType.ERROR_BLOCKING)
			return Buff.BuffEventType.ERROR_BLOCKING
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_BLOCK)
		return Buff.BuffEventType.REFUSED_TO_BLOCK

func end() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_ENDING
	
	if (state & BuffState.BLOCKED) == BuffState.BLOCKED:
		return Buff.BuffEventType.REFUSED_TO_END_IS_BLOCKED
	
	if not ((state & BuffState.ACTIVE) == BuffState.ACTIVE or (state & BuffState.COOLING_DOWN) == BuffState.COOLING_DOWN):
		return Buff.BuffEventType.REFUSED_TO_END_IS_COOLING_DOWN
	
	if (state & BuffState.COOLING_DOWN) == BuffState.COOLING_DOWN and not is_zero_approx(cooldown_time):
		return Buff.BuffEventType.REFUSED_TO_END
	
	if not (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_END_IS_NOT_GRANTED
	
	if buff._can_be_ended(container, self):
		if buff._on_end(container, self):
			_set_state(Buff.BuffEventType.ENDED)
			emit_signal("ended")
			try_reset_cooldown()
			try_reset_duration()
			return Buff.BuffEventType.ENDED
		else:
			_set_state(Buff.BuffEventType.ERROR_ENDING)
			return Buff.BuffEventType.ERROR_ENDING
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_END)
		return Buff.BuffEventType.REFUSED_TO_END

func get_buff() -> Buff:
	return buff

func get_container() -> BuffContainer:
	return container

func get_cooldown() -> float:
	return buff._get_cooldown(container) if buff != null else 0.0

func get_duration() -> float:
	return buff._get_duration(container) if buff != null else 0.0

func grant() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_GRANTING
	
	if (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_GRANT_ALREADY_GRANTED
	
	if buff._can_be_granted(container, self):
		if buff._on_grant(container, self):
			_set_state(Buff.BuffEventType.GRANTED)
			emit_signal("granted")
			return Buff.BuffEventType.GRANTED
		else:
			_set_state(Buff.BuffEventType.ERROR_GRANTING)
			return Buff.BuffEventType.ERROR_GRANTING
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_GRANT)
		return Buff.BuffEventType.REFUSED_TO_GRANT

func is_active() -> bool:
	return (state & BuffState.ACTIVE) == BuffState.ACTIVE

func is_blocked() -> bool:
	return (state & BuffState.BLOCKED) == BuffState.BLOCKED

func is_cooldown_active() -> bool:
	return not is_zero_approx(cooldown_time)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func is_ended() -> bool:
	return not ((state & BuffState.ACTIVE) == BuffState.ACTIVE or (state & BuffState.BLOCKED) == BuffState.BLOCKED) and (state & BuffState.GRANTED) == BuffState.GRANTED

func is_granted() -> bool:
	return (state & BuffState.GRANTED) == BuffState.GRANTED

func is_revoked() -> bool:
	return not (state & BuffState.GRANTED) == BuffState.GRANTED

func revoke() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_REVOKING
	
	if not (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_REVOKE_ALREADY_REVOKED
	
	if buff._can_be_revoked(container, self):
		if buff._on_revoke(container, self):
			_set_state(Buff.BuffEventType.REVOKED)
			if not is_zero_approx(cooldown_time):
				emit_signal("cooldown_end")
			cooldown_time = 0.0
			duration_time = 0.0
			emit_signal("revoked")
			return Buff.BuffEventType.REVOKED
		else:
			_set_state(Buff.BuffEventType.ERROR_REVOKING)
			return Buff.BuffEventType.ERROR_REVOKING
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_REVOKE)
		return Buff.BuffEventType.REFUSED_TO_REVOKE

func set_buff(p_buff: Buff) -> void:
	buff = p_buff
	state = BuffState.IDLE

func set_container(p_container: BuffContainer) -> void:
	container = p_container
	cooldown_time = 0.0

func should_be_activated() -> bool:
	return buff._should_be_activated(container) if buff != null else false

func should_be_blocked() -> bool:
	return buff._should_be_blocked(container) if buff != null else false

func should_be_ended() -> bool:
	return buff._should_be_ended(container) if buff != null else true

func unblock() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_UNBLOCKING
	
	if not (state & BuffState.BLOCKED) == BuffState.BLOCKED:
		return Buff.BuffEventType.REFUSED_TO_UNBLOCK_IS_NOT_BLOCKED
	
	if buff._should_be_blocked(container):
		return Buff.BuffEventType.REFUSED_TO_UNBLOCK_SHOULD_BE_BLOCKED
	
	_set_state(Buff.BuffEventType.UNBLOCKED)
	emit_signal("unblocked")
	return Buff.BuffEventType.UNBLOCKED

func handle_tick(delta: float) -> void:
	if buff == null or container == null:
		return
	
	if buff.has_method("_on_tick"):
		buff._on_tick.call(delta, cooldown_time, container, self)
		return
	
	if should_be_blocked() and block() == Buff.BuffEventType.BLOCKED:
		return
	
	if is_active() and is_duration_active():
		duration_time = clamp(duration_time - delta, 0.0, get_duration())
		if not is_duration_active():
			trigger_cooldown()
		return
	
	if (state & BuffState.COOLING_DOWN) == BuffState.COOLING_DOWN and is_cooldown_active():
		cooldown_time = clamp(cooldown_time - delta, 0.0, get_cooldown())
		if not is_cooldown_active():
			emit_signal("cooldown_end")
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
		if buff.has_method("_can_activate_cooldown"):
			should_activate_cooldown = buff._can_activate_cooldown.call(container, self)
		else:
			should_activate_cooldown = true
		
		if should_activate_cooldown:
			cooldown_time = cooldown
		
		_set_state(Buff.BuffEventType.ACTIVATED_COOLDOWN_STARTED)
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
	if buff.has_method("_should_reset_cooldown"):
		should_reset_cooldown = buff._should_reset_cooldown.call(container)
	
	if should_reset_cooldown:
		cooldown_time = 0.0
		emit_signal("cooldown_ended")

func try_reset_duration() -> void:
	var should_reset_duration = true
	if buff.has_method("_should_reset_duration"):
		should_reset_duration = buff._should_reset_duration.call(container)
	
	if should_reset_duration:
		duration_time = 0.0

func _set_state(event_type: Buff.BuffEventType) -> void:
	match event_type:
		Buff.BuffEventType.ACTIVATED:
			state &= ~BuffState.IDLE
			state |= BuffState.ACTIVE
		Buff.BuffEventType.ACTIVATED_COOLDOWN_STARTED:
			state &= ~BuffState.ACTIVE
			state |= BuffState.COOLING_DOWN
		Buff.BuffEventType.BLOCKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.COOLING_DOWN
			state &= ~BuffState.IDLE
			state |= BuffState.BLOCKED
		Buff.BuffEventType.ENDED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.COOLING_DOWN
			state |= BuffState.IDLE
		Buff.BuffEventType.GRANTED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state &= ~BuffState.COOLING_DOWN
			state |= BuffState.IDLE
			state |= BuffState.GRANTED
		Buff.BuffEventType.REVOKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state &= ~BuffState.COOLING_DOWN
			state &= ~BuffState.GRANTED
			state &= ~BuffState.IDLE
		Buff.BuffEventType.UNBLOCKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state |= BuffState.IDLE
