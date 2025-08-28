extends GD_Effect
class_name GroupEffect

@export var effects:Array[GD_Effect]

func apply(context:Dictionary = {})->Dictionary:
	if effects.is_empty():
		push_error("No effect provided to Random_Pick_Effect")
		return context
	
	for i in effects.size():
		context = effects[i].apply(context)
	return context

func disapply(context:Dictionary = {})->Dictionary:
	if effects.is_empty():
		push_error("No effect provided to Random_Pick_Effect")
		return context
	
	for i in effects.size():
		context = effects[i].disapply(context)
	return context
