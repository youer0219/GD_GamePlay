extends GD_Effect
class_name MutiApplyEffect

@export var apply_conunt:int = 1
@export var effect:GD_Effect

func apply(context:Dictionary = {})->Dictionary:
	if effect == null:
		push_error("No effect provided to MutiApplyEffect")
		return context
	
	for i in range(apply_conunt):
		context = effect.apply(context)
	
	return context

func disapply(context:Dictionary = {})->Dictionary:
	if effect == null:
		push_error("No effect provided to MutiApplyEffect")
		return context
	
	for i in range(apply_conunt):
		context = effect.disapply(context)
	
	return context
