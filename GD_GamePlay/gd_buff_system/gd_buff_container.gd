class_name GD_BuffContainer
extends Node

# Buff management signals
signal buff_awake(runtime_buff:GD_RuntimeBuff)
signal buff_started(runtime_buff:GD_RuntimeBuff)
signal buff_refreshed(runtime_buff:GD_RuntimeBuff)
signal buff_interval_triggered(runtime_buff:GD_RuntimeBuff)
signal buff_removed(runtime_buff:GD_RuntimeBuff)
signal buff_enabled(runtime_buff:GD_RuntimeBuff)
signal buff_disenabled(runtime_buff:GD_RuntimeBuff)

var initial_buffs: Array[GD_Buff] = []
## 待添加的buff字典。每帧开始时将其运行时buff实例化、添加到runtime_buffs字典中并调用其start方法
var pending_add_buffs:Dictionary = {}
var runtime_buffs: Dictionary = {} # StringName: GD_RuntimeBuff

func _ready() -> void:
	for buff in initial_buffs:
		if buff:
			add_buff(buff)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for runtime_buff:GD_RuntimeBuff in pending_add_buffs.values():
		runtime_buffs[runtime_buff.buff.buff_name] = runtime_buff
		
		runtime_buff.buff_start()
	
	if not pending_add_buffs.is_empty():
		pending_add_buffs.clear()
	
	var should_remove_buffs:Array[GD_RuntimeBuff] = []
	for runtime_buff:GD_RuntimeBuff in runtime_buffs.values():
		runtime_buff.buff_process(delta)
		if runtime_buff.should_remove_buff_after_process():
			should_remove_buffs.append(runtime_buff)
	for should_remove_buff in should_remove_buffs:
		remove_runtime_buff(should_remove_buff)

func add_buff(buff: GD_Buff,context:Dictionary = {}) -> bool:
	if not buff:
		push_error("The Buff cannot be null.")
		return false
	
	## 冲突和重叠检查
	var stack_runtime_buffs: Array[GD_RuntimeBuff] = []
	
	for existing_runtime_buff:GD_RuntimeBuff in get_runtime_buffs():
		if existing_runtime_buff.conflicts_with(buff):
			return false
		elif existing_runtime_buff.can_stack_with(buff):
			stack_runtime_buffs.append(existing_runtime_buff)
	
	var runtime_buff = buff.get_runtime_instance(self)
	runtime_buff.blackboard.merge(context,true)
	
	if not stack_runtime_buffs.is_empty():
		for stack_runtime_buff:GD_RuntimeBuff in stack_runtime_buffs:
			stack_runtime_buff.buff_stack(runtime_buff)
			if stack_runtime_buff.should_remove_after_stack():
				return false
	
	if has_buff(buff):
		return false
	
	pending_add_buffs[buff.buff_name] = runtime_buff
	_connect_runtime_buff(runtime_buff)
	runtime_buff.buff_awake()
	
	return true

## 默认传入的contexts要么为空，要么和buffs一样大小
func add_buffs(buffs:Array[GD_Buff],contexts:Array[Dictionary] = [])->bool:
	var result := true
	if contexts == []:
		for i in buffs.size():
			result = add_buff(buffs[i]) and result
	else:
		for i in buffs.size():
			result = add_buff(buffs[i],contexts[i]) and result
	return result

func remove_buff(buff: GD_Buff) -> bool:
	var runtime_buff:GD_RuntimeBuff = get_runtime_buff(buff)
	return remove_runtime_buff(runtime_buff)

func remove_runtime_buff(runtime_buff:GD_RuntimeBuff)->bool:
	if runtime_buff == null:
		push_error("Attempted to remove unexisting buff")
		return false
	
	runtime_buff.buff_remove()
	
	if pending_add_buffs.has(runtime_buff.buff.buff_name): ## 通过不在pending_add_buffs内判断其位置且 pending_add_buffs 一般很小
		pending_add_buffs.erase(runtime_buff.buff.buff_name)
	else:
		runtime_buffs.erase(runtime_buff.buff.buff_name)
		_disconnect_runtime_buff(runtime_buff)
	
	return true

func clear():
	for runtime_buff:GD_RuntimeBuff in runtime_buffs.values():
		runtime_buff.buff_remove()
		_disconnect_runtime_buff(runtime_buff)
	for pending_add_buff:GD_RuntimeBuff in pending_add_buffs.values():
		pending_add_buff.buff_remove()
	
	runtime_buffs.clear()
	pending_add_buffs.clear()

func has_buff(buff: GD_Buff) -> bool:
	if pending_add_buffs.has(buff.buff_name):
		return true
	return runtime_buffs.has(buff.buff_name)

func get_runtime_buff(buff: GD_Buff) -> GD_RuntimeBuff:
	var runtime_buff = runtime_buffs.get(buff.buff_name)
	return runtime_buff if runtime_buff != null else pending_add_buffs.get(buff.buff_name)

func get_runtime_buffs()->Array[GD_RuntimeBuff]:
	var all_runtime_buffs:Array[GD_RuntimeBuff] = []
	all_runtime_buffs.append_array(pending_add_buffs.values())
	all_runtime_buffs.append_array(runtime_buffs.values())
	return all_runtime_buffs

func get_initial_buffs() -> Array[GD_Buff]:
	return initial_buffs

func _connect_runtime_buff(runtime_buff:GD_RuntimeBuff):
	runtime_buff.awake.connect(_on_buff_awake.bind(runtime_buff))
	runtime_buff.started.connect(_on_buff_started.bind(runtime_buff))
	runtime_buff.refreshed.connect(_on_buff_refreshed.bind(runtime_buff))
	runtime_buff.interval_triggered.connect(_on_interval_triggered.bind(runtime_buff))
	runtime_buff.removed.connect(_on_buff_removed.bind(runtime_buff))
	runtime_buff.enabled.connect(_on_buff_enabled.bind(runtime_buff))
	runtime_buff.disenabled.connect(_on_buff_disenabled.bind(runtime_buff))

func _disconnect_runtime_buff(runtime_buff:GD_RuntimeBuff):
	runtime_buff.awake.disconnect(_on_buff_awake)
	runtime_buff.started.disconnect(_on_buff_started)
	runtime_buff.refreshed.disconnect(_on_buff_refreshed)
	runtime_buff.interval_triggered.disconnect(_on_interval_triggered)
	runtime_buff.removed.disconnect(_on_buff_removed)
	runtime_buff.enabled.disconnect(_on_buff_enabled)
	runtime_buff.disenabled.disconnect(_on_buff_disenabled)

func _on_buff_awake(runtime_buff: GD_RuntimeBuff) -> void:
	buff_awake.emit(runtime_buff)

func _on_buff_started(runtime_buff: GD_RuntimeBuff) -> void:
	buff_started.emit(runtime_buff)

func _on_buff_refreshed(runtime_buff: GD_RuntimeBuff) -> void:
	buff_refreshed.emit(runtime_buff)

func _on_interval_triggered(runtime_buff: GD_RuntimeBuff) -> void:
	buff_interval_triggered.emit(runtime_buff)

func _on_buff_removed(runtime_buff: GD_RuntimeBuff) -> void:
	buff_removed.emit(runtime_buff)

func _on_buff_enabled(runtime_buff:GD_RuntimeBuff) -> void:
	buff_enabled.emit(runtime_buff)

func _on_buff_disenabled(runtime_buff:GD_RuntimeBuff) -> void:
	buff_disenabled.emit(runtime_buff)

static func get_dic_array(size:int,dic:Dictionary = {})->Array[Dictionary]:
	var dic_array :Array[Dictionary] = []
	for i in size:
		dic_array.append(dic)
	return dic_array

static func merge_dic_array(dic_array:Array[Dictionary],new_dic_array:Array[Dictionary])->void:
	for i in dic_array.size():
		dic_array[i].merge(new_dic_array[i],true)
