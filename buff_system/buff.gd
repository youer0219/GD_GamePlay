# buff.gd
class_name Buff
extends Resource

# buff event signals
@warning_ignore("unused_signal")
signal activated(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal blocked(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal ended(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal granted(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal revoked(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal unblocked(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal cooldown_started(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal cooldown_ended(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal duration_started(buff_container: BuffContainer, runtime_buff: RuntimeBuff)
@warning_ignore("unused_signal")
signal duration_ended(buff_container: BuffContainer, runtime_buff: RuntimeBuff)

enum BuffEventType {
	ACTIVATED,
	ACTIVATED_COOLDOWN_STARTED,
	ACTIVATED_DURATION_STARTED,
	BLOCKED,
	ENDED,
	ERROR_ACTIVATING,
	ERROR_BLOCKING,
	ERROR_ENDING,
	ERROR_GRANTING,
	ERROR_REVOKING,
	ERROR_UNBLOCKING,
	GRANTED,
	REFUSED_TO_ACTIVATE,
	REFUSED_TO_ACTIVATE_DECIDED_TO_BLOCK,
	REFUSED_TO_ACTIVATE_IS_BLOCKED,
	REFUSED_TO_ACTIVATE_IS_COOLING_DOWN,
	REFUSED_TO_ACTIVATE_IS_DURATION_ACTIVE,
	REFUSED_TO_ACTIVATE_IS_REVOKED,
	REFUSED_TO_BLOCK,
	REFUSED_TO_BLOCK_IS_NOT_GRANTED,
	REFUSED_TO_END,
	REFUSED_TO_END_IS_BLOCKED,
	REFUSED_TO_END_IS_COOLING_DOWN,
	REFUSED_TO_END_IS_NOT_ACTIVE,
	REFUSED_TO_END_IS_NOT_GRANTED,
	REFUSED_TO_GRANT,
	REFUSED_TO_GRANT_ALREADY_GRANTED,
	REFUSED_TO_REVOKE,
	REFUSED_TO_REVOKE_ALREADY_REVOKED,
	REFUSED_TO_UNBLOCK,
	REFUSED_TO_UNBLOCK_IS_NOT_BLOCKED,
	REFUSED_TO_UNBLOCK_SHOULD_BE_BLOCKED,
	REVOKED,
	UNBLOCKED
}

var buff_name: StringName = ""

func _can_add_buff(_buff_container: BuffContainer)->bool:
	return true

func _can_activate_cooldown(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _can_be_activated(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _can_be_blocked(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _can_be_ended(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _can_be_granted(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _can_be_revoked(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _get_cooldown(_buff_container: BuffContainer) -> float:
	return 0.0

func _get_duration(_buff_container: BuffContainer) -> float:
	return 0.0

func _on_activate(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _on_block(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _on_end(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _on_grant(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

func _on_revoke(_buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> bool:
	return true

#func _on_tick(_delta: float, _tick_time: float, _buff_container: BuffContainer, _runtime_buff: RuntimeBuff) -> void:
	#pass

func _should_be_activated(_buff_container: BuffContainer) -> bool:
	return false

func _should_be_blocked(_buff_container: BuffContainer) -> bool:
	return false

func _should_be_ended(_buff_container: BuffContainer) -> bool:
	return true

func _should_reset_cooldown(_buff_container: BuffContainer) -> bool:
	return true

func _should_reset_duration(_buff_container: BuffContainer) -> bool:
	return true
