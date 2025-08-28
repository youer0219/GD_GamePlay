extends GD_Effect
class_name Random_Pick_Effect

@export var effects:Array[GD_Effect]         # 可选效果池
@export var pick_count:int = 1               # 随机选取数量
@export var allow_repeat:bool = false        # 是否允许重复

var choosed_effects:Array[GD_Effect] = []    # 本次选择的效果

func apply(context:Dictionary = {}) -> Dictionary:
	if effects.is_empty():
		push_error("No effect provided to Random_Pick_Effect")
		return context
	
	choosed_effects.clear()
	
	var pool:Array = effects.duplicate()
	for i in range(pick_count):
		if pool.is_empty():
			break
		
		var effect:GD_Effect
		if allow_repeat:
			effect = pool.pick_random()
		else:
			var idx:int = randi() % pool.size()
			effect = pool[idx]
			pool.remove_at(idx)
		choosed_effects.append(effect)
	
	for e in choosed_effects:
		context = e.apply(context)
	
	return context

func disapply(context:Dictionary = {}) -> Dictionary:
	if choosed_effects.is_empty():
		return context
	
	for e in choosed_effects:
		context = e.disapply(context)
	
	return context
