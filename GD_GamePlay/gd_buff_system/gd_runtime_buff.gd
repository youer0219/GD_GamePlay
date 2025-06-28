class_name GD_RuntimeBuff
extends RefCounted

# Signals for state changes
signal awake(runtime_buff: GD_RuntimeBuff)
signal started(runtime_buff: GD_RuntimeBuff)
signal refreshed(runtime_buff: GD_RuntimeBuff)
signal interval_triggered(runtime_buff: GD_RuntimeBuff)
signal removed(runtime_buff: GD_RuntimeBuff)
signal enabled(runtime_buff: GD_RuntimeBuff)
signal disenabled(runtime_buff: GD_RuntimeBuff)

enum BUFF_STATE {
	INIT,
	AWAKE,
	EXIST,
	REMOVE,
}

var buff: GD_Buff = null
var container: GD_BuffContainer = null
var duration_time: float = 0.0:
	set(value):
		duration_time = max(0.0,value)
var state:BUFF_STATE = BUFF_STATE.INIT
var enable:bool = false:set = _set_enable
var higher_buff_num:int = 0:set = _set_higher_buff_num
var layer:int = 1:
	set(value):
		layer = clamp(value,0,buff.max_layers)
var curr_interval_time := 0.0
var curr_interval_num := 0
var duration_time_flow_rate:float = 1.0:
	set(value):
		duration_time_flow_rate = max(0,value)
var blackboard: Dictionary = {}

func _init(new_buff: GD_Buff, new_container: GD_BuffContainer) -> void:
	if not new_buff or not new_container:
		push_error("Buff or Container cannot be null!")
		return
	
	self.buff = new_buff
	self.container = new_container
	self.blackboard = new_buff.init_buff_blackboard.duplicate(true)
	self.duration_time = new_buff.get_duration()
	self.curr_interval_num = new_buff.get_default_interval_num()

func buff_awake()->void:
	if not _is_base_check_pass():
		return
	
	state = BUFF_STATE.AWAKE
	buff._on_buff_awake(container, self)
	awake.emit()

func buff_start() -> void:
	if not _is_base_check_pass():
		return
	
	state = BUFF_STATE.EXIST
	buff._on_buff_start(container, self)
	started.emit()
	
	enable = can_enable()

func buff_process(delta: float) -> void:
	if not _is_base_check_pass():
		return
	
	buff._on_buff_process(container, self, delta)

func buff_interval_trigger() -> void:
	if not _is_base_check_pass():
		return
	
	buff._on_buff_interval_trigger(container, self)
	interval_triggered.emit()

func buff_stack(new_runtime_buff:GD_RuntimeBuff) -> void:
	if not _is_base_check_pass() or not new_runtime_buff:
		return
	
	buff._on_buff_stack(container, self, new_runtime_buff)
	refreshed.emit()

func buff_remove() -> void:
	if not _is_base_check_pass():
		return
	
	enable = false
	state = BUFF_STATE.REMOVE
	buff._on_buff_remove(container, self)
	removed.emit()

func exist_buff_enable()->void:
	buff._on_exist_buff_enable(container,self)
	enabled.emit()

func exist_buff_disenable()->void:
	buff._on_exist_buff_disenable(container,self)
	disenabled.emit()

func can_stack_with(other_buff: GD_Buff) -> bool:
	return buff.can_stack_with(other_buff)

func conflicts_with(other_buff: GD_Buff) -> bool:
	return buff.conflicts_with(other_buff)

func should_remove_buff_after_process()->bool:
	return buff.should_remove_buff_after_process(container,self)

func can_enable()->bool:
	return higher_buff_num == 0 and state == BUFF_STATE.EXIST

func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

func should_remove_after_stack()->bool:
	return buff.should_remove_after_stack()

func _is_base_check_pass() -> bool:
	if buff == null or container == null:
		push_error("Buff or Container is null!")
		return false
	return true

func _set_enable(value:bool):
	## 只允许在EXIST状态下设置为true，其余状态应该都为false。
	if state != BUFF_STATE.EXIST:
		if value:
			push_error("只允许在EXIST状态下设置为true")
		return
	if enable == value:return
	enable = value
	if enable:
		exist_buff_enable()
	else:
		exist_buff_disenable()


func _set_higher_buff_num(new_num:int):
	higher_buff_num = max(new_num,0)
	enable = can_enable()
