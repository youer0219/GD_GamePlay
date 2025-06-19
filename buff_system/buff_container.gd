# buff_container.gd
class_name BuffContainer
extends Node

enum ErrorType {
	NOT_FOUND,
	PARAMETER_IS_NULL
}

# container management signals
signal buff_activated(buff: Buff)
signal buff_added(buff: Buff)
signal buff_blocked(buff: Buff)
signal buff_ended(buff: Buff) 
signal buff_granted(buff: Buff)
signal buff_removed(buff: Buff)
signal buff_revoked(buff: Buff)
signal buff_unblocked(buff: Buff)
signal cooldown_started(buff: Buff)
signal cooldown_ended(buff: Buff)

var initial_buffs: Array[Buff] = []
var runtime_buffs: Dictionary = {} # StringName: RuntimeBuff

func _ready() -> void:
	for buff in initial_buffs:
		if buff:
			add_buff(buff)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for runtime_buff in runtime_buffs.values():
		if runtime_buff and runtime_buff.is_granted():
			runtime_buff.handle_tick(delta)

func _on_active_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_activated", runtime_buff.get_buff())

func _on_blocked_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_blocked", runtime_buff.get_buff())

func _on_ended_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_ended", runtime_buff.get_buff())

func _on_granted_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_granted", runtime_buff.get_buff())

func _on_revoked_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_revoked", runtime_buff.get_buff())

func _on_cooldown_end(runtime_buff: RuntimeBuff) -> void:
	emit_signal("cooldown_ended", runtime_buff.get_buff())

func _on_cooldown_start(runtime_buff: RuntimeBuff) -> void:
	emit_signal("cooldown_started", runtime_buff.get_buff())

func _on_unblocked_buff(runtime_buff: RuntimeBuff) -> void:
	emit_signal("buff_unblocked", runtime_buff.get_buff())

func add_buff(buff: Buff) -> bool:
	if not buff:
		push_error("The Buff cannot be null.")
		return false
	
	var stack_runtime_buffs:Array[RuntimeBuff]
	var conflict_runtime_buffs:Array[RuntimeBuff]
	for existing_runtime_buff:RuntimeBuff in runtime_buffs.values():
		if existing_runtime_buff.can_conflict_with(buff):
			conflict_runtime_buffs.append(existing_runtime_buff)
		elif existing_runtime_buff.can_stack_with(buff):
			stack_runtime_buffs.append(existing_runtime_buff)
	if not conflict_runtime_buffs.is_empty():
		return false
	elif not stack_runtime_buffs.is_empty():
		## TODO:叠加机制
		return false
	
	if not has_buff(buff):
		var runtime_buff = _build_runtime_buff(buff)
		runtime_buff.set_buff(buff)
		runtime_buff.set_container(self)
		
		runtime_buffs[buff.buff_name] = runtime_buff
		
		runtime_buff.connect("activated", _on_active_buff.bind(runtime_buff))
		runtime_buff.connect("blocked", _on_blocked_buff.bind(runtime_buff))
		runtime_buff.connect("ended", _on_ended_buff.bind(runtime_buff))
		runtime_buff.connect("granted", _on_granted_buff.bind(runtime_buff))
		runtime_buff.connect("revoked", _on_revoked_buff.bind(runtime_buff))
		runtime_buff.connect("cooldown_ended", _on_cooldown_end.bind(runtime_buff))
		runtime_buff.connect("cooldown_started", _on_cooldown_start.bind(runtime_buff))
		runtime_buff.connect("unblocked", _on_unblocked_buff.bind(runtime_buff))
		
		emit_signal("buff_added", buff)
		
		if try_grant(buff) == Buff.BuffEventType.GRANTED and runtime_buff.should_be_activated() and try_activate(buff) == Buff.BuffEventType.ACTIVATED:
			return true
	
	return false


func _build_runtime_buff(_buff: Buff) -> RuntimeBuff:
	return RuntimeBuff.new()

func get_runtime_buff(variant: Variant) -> RuntimeBuff:
	if variant is Buff:
		return runtime_buffs.get(variant.buff_name)
	return runtime_buffs.get(variant)

func get_runtime_buffs() -> Array[RuntimeBuff]:
	return Array(runtime_buffs.values(),TYPE_OBJECT,"RefCounted",RuntimeBuff)

func get_initial_buffs() -> Array[Buff]:
	return initial_buffs

func find_buff(predicate: Callable) -> RuntimeBuff:
	for i in runtime_buffs.size():
		var runtime_buff = runtime_buffs.values()[i]
		if runtime_buff and predicate.call(runtime_buff, i):
			return runtime_buff
	return null

func has_buff(variant: Variant) -> bool:
	if variant is Buff:
		return runtime_buffs.has(variant.buff_name)
	return runtime_buffs.has(variant)

func is_buff_active(variant: Variant) -> bool:
	var runtime_buff = get_runtime_buff(variant)
	return runtime_buff and runtime_buff.is_active()

func is_buff_blocked(variant: Variant) -> bool:
	var runtime_buff = get_runtime_buff(variant)
	return runtime_buff and runtime_buff.is_blocked()

func is_buff_cooldown_active(variant: Variant) -> bool:
	var runtime_buff = get_runtime_buff(variant)
	return runtime_buff and runtime_buff.is_cooldown_active()

func is_buff_ended(variant: Variant) -> bool:
	var runtime_buff = get_runtime_buff(variant)
	return runtime_buff and runtime_buff.is_ended()

func is_buff_granted(variant: Variant) -> bool:
	var runtime_buff = get_runtime_buff(variant)
	return runtime_buff and runtime_buff.is_granted()

func remove_buff(buff: Buff) -> bool:
	if has_buff(buff):
		var runtime_buff = runtime_buffs[buff.buff_name]
		
		if runtime_buff.is_active():
			runtime_buff.end()
		
		runtime_buff.revoke()
		
		runtime_buffs.erase(buff.buff_name)
		
		emit_signal("buff_removed", buff)
		return true
	return false

func set_initial_buffs(buffs: Array[Buff]) -> void:
	initial_buffs = buffs

func try_activate(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_ACTIVATING
	
	return runtime_buff.activate()

func try_block(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_BLOCKING
	
	return runtime_buff.block()

func try_end(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_ENDING
	
	return runtime_buff.end()

func try_grant(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_GRANTING
	
	return runtime_buff.grant()

func try_revoke(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_REVOKING
	
	return runtime_buff.revoke()

func try_unblock(variant: Variant) -> Buff.BuffEventType:
	var runtime_buff = get_runtime_buff(variant)
	if not runtime_buff:
		return Buff.BuffEventType.ERROR_UNBLOCKING
	
	return runtime_buff.unblock()
