# ability.gd
class_name Ability
extends Resource

enum AbilityEventType {
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

var ability_name: StringName = ""

func _can_activate_cooldown(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _can_be_activated(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _can_be_blocked(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _can_be_ended(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _can_be_granted(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _can_be_revoked(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> bool:
	return true

func _get_cooldown(_ability_container: AbilityContainer) -> float:
	return 0.0

func _get_duration(_ability_container: AbilityContainer) -> float:
	return 0.0

func _on_activate(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility):
	pass

func _on_block(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility):
	pass

func _on_end(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility):
	pass

func _on_grant(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility):
	pass

func _on_revoke(_ability_container: AbilityContainer, _runtime_ability: RuntimeAbility):
	pass

#func _on_tick(_delta: float, _tick_time: float, _ability_container: AbilityContainer, _runtime_ability: RuntimeAbility) -> void:
	#pass

func _should_be_activated(_ability_container: AbilityContainer) -> bool:
	return false

func _should_be_blocked(_ability_container: AbilityContainer) -> bool:
	return false

func _should_be_ended(_ability_container: AbilityContainer) -> bool:
	return true

func _should_reset_cooldown(_ability_container: AbilityContainer) -> bool:
	return true

func _should_reset_duration(_ability_container: AbilityContainer) -> bool:
	return true
