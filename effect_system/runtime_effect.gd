class_name RuntimeEffect
extends RefCounted

# 效果状态枚举（新增 PAUSED）
enum State {
	INIT,       # 最初状态
	APPLIED,    # 已应用但未激活
	ACTIVE,     # 激活中（计时中）
	PAUSED,     # 暂停（计时停止）
	REMOVED,    # 已移除
}

var effect: Effect = null
var container: EffectContainer = null
var state: int = State.INIT
var duration_time: float = 0.0

func apply()->void:
	if not _is_base_check_pass():
		return
	
	if state != State.INIT:
		return
	
	effect._on_apply(container,self)
	set_state(State.APPLIED)

# 激活效果（从 APPLIED → ACTIVE）
func activate() -> void:
	if not _is_base_check_pass():
		return
	
	if state != State.APPLIED:
		push_error("只能从APPLIED状态激活效果")
		return
	
	duration_time = effect.get_duration()
	effect._on_active(container, self)  # 触发激活回调
	set_state(State.ACTIVE)

# 暂停效果（从 ACTIVE → PAUSED）
func pause() -> void:
	if not _is_base_check_pass():
		return
	
	#if state != State.ACTIVE:
		#push_error("只能从ACTIVE状态暂停效果")  ## 允许从大部分状态暂停BUFF
		#return
	if state == State.REMOVED:
		return
	
	effect._on_pause(container, self)  # 触发暂停回调
	set_state(State.PAUSED)

# 恢复效果（从 PAUSED → ACTIVE）
func resume() -> void:
	if not _is_base_check_pass():
		return
	
	if state != State.PAUSED:
		push_error("只能从PAUSED状态恢复效果")
		return
	
	effect._on_resume(container, self)  # 触发恢复回调
	set_state(State.ACTIVE)

# 移除效果（支持从 APPLIED/ACTIVE/PAUSED → REMOVED）
func remove() -> void:
	if not _is_base_check_pass():
		return
	
	if state == State.REMOVED:
		return
	
	effect._on_remove(container, self)  # 触发移除回调（无论原状态）
	set_state(State.REMOVED)

# 每帧更新（仅在 ACTIVE 状态时计时）
func handle_tick(delta: float) -> void:
	if state == State.REMOVED:
		return
	if state == State.ACTIVE and is_duration_active():
		duration_time = max(0.0, duration_time - delta)
		if not is_duration_active():  # 计时结束自动移除
			remove()
			return
	effect._on_tick(container, self, delta)  # 无论状态都触发Tick回调（需Effect自行处理PAUSED逻辑）

# 状态检查辅助函数
func is_duration_active() -> bool:
	return not is_zero_approx(duration_time)

# 状态转换辅助函数
func set_state(new_state: int) -> void:
	state = new_state

# 基础检查（effect/container非空）
func _is_base_check_pass() -> bool:
	if effect == null or container == null:
		push_error("Effect or Container is null!")
		return false
	return true
