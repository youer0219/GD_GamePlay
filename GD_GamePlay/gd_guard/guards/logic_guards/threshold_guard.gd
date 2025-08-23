extends GD_LogicGuard
class_name GD_ThresholdGuard
## 门限守卫

@export var guards: Array[GD_Guard] = []
@export_range(0,INF,1.0) var need_guard_num:int = 1

func is_satisfied(context:Dictionary = {}) -> bool:
	if guards.size() < need_guard_num:
		push_error("No enough guards provided to ThresholdGuard")
		return false
	var curr_num := 0
	for guard in guards:
		if guard.is_satisfied(context):
			curr_num += 1
			if curr_num >= need_guard_num:
				return true
	return false
