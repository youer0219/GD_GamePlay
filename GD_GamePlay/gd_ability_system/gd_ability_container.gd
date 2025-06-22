# ability_container.gd
class_name GD_AbilityContainer
extends Node

enum ErrorType {
	NOT_FOUND,
	PARAMETER_IS_NULL
}

# 容器管理信号
signal ability_activated(ability: GD_Ability)
signal ability_added(ability: GD_Ability)
signal ability_blocked(ability: GD_Ability)
signal ability_ended(ability: GD_Ability) 
signal ability_granted(ability: GD_Ability)
signal ability_removed(ability: GD_Ability)
signal ability_revoked(ability: GD_Ability)
signal ability_unblocked(ability: GD_Ability)
signal cooldown_started(ability: GD_Ability)
signal cooldown_ended(ability: GD_Ability)

var initial_abilities: Array[GD_Ability] = []
var runtime_abilities: Dictionary = {} # StringName: GD_RuntimeAbility

func _ready() -> void:
	for ability in initial_abilities:
		if ability:
			add_ability(ability)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for runtime_ability in runtime_abilities.values():
		if runtime_ability and runtime_ability.is_granted():
			runtime_ability.handle_tick(delta)

func _on_active_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_activated", runtime_ability.get_ability())

func _on_blocked_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_blocked", runtime_ability.get_ability())

func _on_ended_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_ended", runtime_ability.get_ability())

func _on_granted_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_granted", runtime_ability.get_ability())

func _on_revoked_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_revoked", runtime_ability.get_ability())

func _on_cooldown_end(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("cooldown_ended", runtime_ability.get_ability())

func _on_cooldown_start(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("cooldown_started", runtime_ability.get_ability())

func _on_unblocked_ability(runtime_ability: GD_RuntimeAbility) -> void:
	emit_signal("ability_unblocked", runtime_ability.get_ability())

func add_ability(ability: GD_Ability) -> bool:
	if not ability:
		push_error("The GD_Ability cannot be null.")
		return false
	
	if not has_ability(ability):
		var runtime_ability = _build_runtime_ability(ability)
		runtime_ability.set_ability(ability)
		runtime_ability.set_container(self)
		
		runtime_abilities[ability.ability_name] = runtime_ability
		
		runtime_ability.connect("activated", _on_active_ability.bind(runtime_ability))
		runtime_ability.connect("blocked", _on_blocked_ability.bind(runtime_ability))
		runtime_ability.connect("ended", _on_ended_ability.bind(runtime_ability))
		runtime_ability.connect("granted", _on_granted_ability.bind(runtime_ability))
		runtime_ability.connect("revoked", _on_revoked_ability.bind(runtime_ability))
		runtime_ability.connect("cooldown_ended", _on_cooldown_end.bind(runtime_ability))
		runtime_ability.connect("cooldown_started", _on_cooldown_start.bind(runtime_ability))
		runtime_ability.connect("unblocked", _on_unblocked_ability.bind(runtime_ability))
		
		emit_signal("ability_added", ability)
		
		if try_grant(ability) == GD_Ability.AbilityEventType.GRANTED and runtime_ability.should_be_activated() and try_activate(ability) == GD_Ability.AbilityEventType.ACTIVATED:
			return true
	
	return false

func _build_runtime_ability(_ability: GD_Ability) -> GD_RuntimeAbility:
	return GD_RuntimeAbility.new()

func get_runtime_ability(variant: Variant) -> GD_RuntimeAbility:
	if variant is GD_Ability:
		return runtime_abilities.get(variant.ability_name)
	return runtime_abilities.get(variant)

func get_runtime_abilities() -> Array[GD_RuntimeAbility]:
	return Array(runtime_abilities.values(),TYPE_OBJECT,"RefCounted",GD_RuntimeAbility)

func get_initial_abilities() -> Array[GD_Ability]:
	return initial_abilities

func find_ability(predicate: Callable) -> GD_RuntimeAbility:
	for i in runtime_abilities.size():
		var runtime_ability = runtime_abilities.values()[i]
		if runtime_ability and predicate.call(runtime_ability, i):
			return runtime_ability
	return null

func has_ability(variant: Variant) -> bool:
	if variant is GD_Ability:
		return runtime_abilities.has(variant.ability_name)
	return runtime_abilities.has(variant)

func is_ability_active(variant: Variant) -> bool:
	var runtime_ability = get_runtime_ability(variant)
	return runtime_ability and runtime_ability.is_active()

func is_ability_blocked(variant: Variant) -> bool:
	var runtime_ability = get_runtime_ability(variant)
	return runtime_ability and runtime_ability.is_blocked()

func is_ability_cooldown_active(variant: Variant) -> bool:
	var runtime_ability = get_runtime_ability(variant)
	return runtime_ability and runtime_ability.is_cooldown_active()

func is_ability_ended(variant: Variant) -> bool:
	var runtime_ability = get_runtime_ability(variant)
	return runtime_ability and runtime_ability.is_ended()

func is_ability_granted(variant: Variant) -> bool:
	var runtime_ability = get_runtime_ability(variant)
	return runtime_ability and runtime_ability.is_granted()

func remove_ability(ability: GD_Ability) -> bool:
	if has_ability(ability):
		var runtime_ability = runtime_abilities[ability.ability_name]
		
		if runtime_ability.is_active():
			runtime_ability.end()
		
		runtime_ability.revoke()
		
		runtime_abilities.erase(ability.ability_name)
		
		emit_signal("ability_removed", ability)
		return true
	return false

func set_initial_abilities(abilities: Array[GD_Ability]) -> void:
	initial_abilities = abilities

func try_activate(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_ACTIVATING
	
	return runtime_ability.activate()

func try_block(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_BLOCKING
	
	return runtime_ability.block()

func try_end(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_ENDING
	
	return runtime_ability.end()

func try_grant(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_GRANTING
	
	return runtime_ability.grant()

func try_revoke(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_REVOKING
	
	return runtime_ability.revoke()

func try_unblock(variant: Variant) -> GD_Ability.AbilityEventType:
	var runtime_ability = get_runtime_ability(variant)
	if not runtime_ability:
		return GD_Ability.AbilityEventType.ERROR_UNBLOCKING
	
	return runtime_ability.unblock()
