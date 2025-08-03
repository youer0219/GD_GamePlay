class_name GD_BuffUtilities

static func get_dic_array(size:int,dic:Dictionary = {})->Array[Dictionary]:
	var dic_array :Array[Dictionary] = []
	for i in size:
		dic_array.append(dic)
	return dic_array

static func merge_dic_array(dic_array:Array[Dictionary],new_dic_array:Array[Dictionary])->void:
	for i in dic_array.size():
		dic_array[i].merge(new_dic_array[i],true)
