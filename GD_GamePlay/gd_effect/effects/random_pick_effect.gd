extends GD_Effect
class_name Random_Pick_Effect

@export var effects:Array[GD_Effect]

var choosed_effect:GD_Effect

func apply(context:Dictionary = {})->Dictionary:
	if effects.is_empty():
		push_error("No effect provided to Random_Pick_Effect")
		return context
	
	choosed_effect = effects.pick_random()
	return choosed_effect.apply(context)

func disapply(context:Dictionary = {})->Dictionary:
	if choosed_effect == null:
		return context
	
	return choosed_effect.disapply(context)
