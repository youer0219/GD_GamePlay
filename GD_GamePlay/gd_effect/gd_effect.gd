extends Resource
class_name GD_Effect
## 最基础的效果

## TODO: 研究是否要添加一个“未生效不允许disapply的保护

func apply(context:Dictionary = {})->Dictionary:
	return context

func disapply(context:Dictionary = {})->Dictionary:
	return context
