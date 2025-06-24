class_name GD_RuntimeBuff
extends RefCounted

# Signals for state changes
signal awake(runtime_buff: GD_RuntimeBuff)
signal started(runtime_buff: GD_RuntimeBuff)
signal refreshed(runtime_buff: GD_RuntimeBuff)
signal interval_triggered(runtime_buff: GD_RuntimeBuff)
signal removed(runtime_buff: GD_RuntimeBuff)

var buff: GD_Buff = null
var container: GD_BuffContainer = null
var duration_time: float = 0.0:
	set(value):
		duration_time = max(0.0,value)
var blackboard: Dictionary = {}

func _init(new_buff: GD_Buff, new_container: GD_BuffContainer) -> void:
	if not new_buff or not new_container:
		push_error("Buff or Container cannot be null!")
		return
	
	self.buff = new_buff
	self.container = new_container
	self.blackboard = new_buff.init_buff_blackboard.duplicate(true)
	self.duration_time = buff.get_duration()

func buff_awake()->void:
	if not _is_base_check_pass():
		return
		
	buff._on_buff_awake(container, self)
	awake.emit()

func buff_start() -> void:
	if not _is_base_check_pass():
		return
		
	buff._on_buff_start(container, self)
	started.emit()

func buff_process(delta: float) -> void:
	if not _is_base_check_pass():
		return
	
	# 处理持续时间
	duration_time = duration_time - delta
	
	buff._on_buff_process(container, self, delta)

func buff_interval_trigger() -> void:
	if not _is_base_check_pass():
		return
	
	buff._on_buff_interval_trigger(container, self)
	interval_triggered.emit()

func buff_refresh(new_buff:GD_Buff) -> void:
	if not _is_base_check_pass() or not new_buff:
		return
	
	buff._on_buff_refresh(container, self, new_buff)
	refreshed.emit()

func buff_remove() -> void:
	if not _is_base_check_pass():
		return
	
	buff._on_buff_remove(container, self)
	removed.emit()

func can_stack_with(other_buff: GD_Buff) -> bool:
	return buff.can_stack_with(other_buff)

func conflicts_with(other_buff: GD_Buff) -> bool:
	return buff.conflicts_with(other_buff)

func can_remove_buff()->bool:
	return buff.can_remove_buff(container,self)

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func should_remove_after_stack()->bool:
	return buff.should_remove_after_stack()

func _is_base_check_pass() -> bool:
	if buff == null or container == null:
		push_error("Buff or Container is null!")
		return false
	return true
