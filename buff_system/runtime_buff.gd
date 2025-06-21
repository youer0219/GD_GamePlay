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

enum BuffState {
	IDLE = 1,
	ACTIVE = 2,
	BLOCKED = 4,
	GRANTED = 16
}

var buff: Buff = null
var container: BuffContainer = null
var state: int = BuffState.IDLE
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
	
	if buff._can_be_activated(container, self):
		buff._on_activate(container, self)
		_set_state(Buff.BuffEventType.ACTIVATED)
		emit_signal("activated")
		
		if trigger_duration():
			return Buff.BuffEventType.ACTIVATED_DURATION_STARTED
		
		return Buff.BuffEventType.ACTIVATED
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_ACTIVATE)
		return Buff.BuffEventType.REFUSED_TO_ACTIVATE


func block() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_BLOCKING
	
	if not (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_BLOCK_IS_NOT_GRANTED
	
	if buff._can_be_blocked(container, self):
		buff._on_block(container, self)
		_set_state(Buff.BuffEventType.BLOCKED)
		emit_signal("blocked")
		return Buff.BuffEventType.BLOCKED
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_BLOCK)
		return Buff.BuffEventType.REFUSED_TO_BLOCK

func end() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_ENDING
	
	if (state & BuffState.BLOCKED) == BuffState.BLOCKED:
		return Buff.BuffEventType.REFUSED_TO_END_IS_BLOCKED
	
	if not (state & BuffState.ACTIVE) == BuffState.ACTIVE:
		return Buff.BuffEventType.REFUSED_TO_END_IS_NOT_ACTIVE
	
	if not (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_END_IS_NOT_GRANTED
	
	if buff._can_be_ended(container, self):
		buff._on_end(container, self)
		_set_state(Buff.BuffEventType.ENDED)
		emit_signal("ended")
		return Buff.BuffEventType.ENDED
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_END)
		return Buff.BuffEventType.REFUSED_TO_END

func get_buff() -> Buff:
	return buff

func get_container() -> BuffContainer:
	return container

func get_duration() -> float:
	return buff._get_duration(container) if buff != null else 0.0

func grant() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_GRANTING
	
	if (state & BuffState.GRANTED) == BuffState.GRANTED:
		return Buff.BuffEventType.REFUSED_TO_GRANT_ALREADY_GRANTED
	
	if buff._can_be_granted(container, self):
		buff._on_grant(container, self)
		_set_state(Buff.BuffEventType.GRANTED)
		emit_signal("granted")
		return Buff.BuffEventType.GRANTED
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_GRANT)
		return Buff.BuffEventType.REFUSED_TO_GRANT

func is_active() -> bool:
	return (state & BuffState.ACTIVE) == BuffState.ACTIVE

func is_blocked() -> bool:
	return (state & BuffState.BLOCKED) == BuffState.BLOCKED

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func is_ended() -> bool:
	return not is_active() and not is_blocked() and is_granted()

func is_granted() -> bool:
	return (state & BuffState.GRANTED) == BuffState.GRANTED

func is_revoked() -> bool:
	return not is_granted()

func revoke() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_REVOKING
	
	if not is_granted():
		return Buff.BuffEventType.REFUSED_TO_REVOKE_ALREADY_REVOKED
	
	if buff._can_be_revoked(container, self):
		buff._on_revoke(container, self)
		_set_state(Buff.BuffEventType.REVOKED)
		duration_time = 0.0
		emit_signal("revoked")
		return Buff.BuffEventType.REVOKED
	else:
		_set_state(Buff.BuffEventType.REFUSED_TO_REVOKE)
		return Buff.BuffEventType.REFUSED_TO_REVOKE

func set_buff(p_buff: Buff) -> void:
	buff = p_buff
	state = BuffState.IDLE

func set_container(p_container: BuffContainer) -> void:
	container = p_container

func can_stack_with(new_buff:Buff)->bool:
	return buff._can_stack_with(new_buff) if buff != null else false

func can_conflict_with(new_buff:Buff)->bool:
	return buff._can_conflict_with(new_buff) if buff != null else false

func should_be_activated() -> bool:
	return buff._should_be_activated(container) if buff != null else false

func should_be_blocked() -> bool:
	return buff._should_be_blocked(container) if buff != null else false

func should_be_ended() -> bool:
	return buff._should_be_ended(container) if buff != null else true

func unblock() -> Buff.BuffEventType:
	if buff == null or container == null:
		return Buff.BuffEventType.ERROR_UNBLOCKING
	
	if not is_blocked():
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
		buff._on_tick.call(delta, container, self)
		return
	
	if should_be_blocked() and block() == Buff.BuffEventType.BLOCKED:
		return
	
	if is_active() and is_duration_active():
		duration_time = clamp(duration_time - delta, 0.0, get_duration())
		return
	
	if should_be_ended():
		end()
	
	if not should_be_activated():
		return
	
	activate()

func trigger_duration() -> bool:
	var duration = get_duration()
	if not is_zero_approx(duration):
		duration_time = duration
		return true
	return false

func _set_state(event_type: Buff.BuffEventType) -> void:
	match event_type:
		Buff.BuffEventType.ACTIVATED, Buff.BuffEventType.ACTIVATED_DURATION_STARTED:
			state &= ~BuffState.IDLE
			state |= BuffState.ACTIVE
		Buff.BuffEventType.BLOCKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.IDLE
			state |= BuffState.BLOCKED
		Buff.BuffEventType.ENDED:
			state &= ~BuffState.ACTIVE
			state |= BuffState.IDLE
		Buff.BuffEventType.GRANTED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state |= BuffState.IDLE
			state |= BuffState.GRANTED
		Buff.BuffEventType.REVOKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state &= ~BuffState.GRANTED
			state &= ~BuffState.IDLE
		Buff.BuffEventType.UNBLOCKED:
			state &= ~BuffState.ACTIVE
			state &= ~BuffState.BLOCKED
			state |= BuffState.IDLE
