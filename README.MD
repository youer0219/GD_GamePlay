# GD_GamePlay

目前通过GDS实现了能力系统和BUFF系统。属性系统我认为[godot_gameplay_attributes](https://github.com/OctoD/godot_gameplay_attributes)已经满足需求且使用C++实现，性能优秀，暂无计划。

警告：未经过项目实践测试。未有性能测试。制作中，API可能变化。

## Ability System

这里主要仿照了[godot-gameplay-abilities](https://github.com/OctoD/godot-gameplay-abilities)实现。原本实现为C++语言。

使用GDS版本的优势在于：
- 便于直接理解（虽然，原版核心源码只有一个文件，借助AI也可以理解逻辑）
- 极强的扩展性
- 快速验证功能后可以直接转为原版。我会尽可能保持与原版一致的行为。

PS:其实原版就是GDS转C++，这是一个轮回哈哈。为了避免类名冲突，我都加了前缀`GD_`。

## Buff System

目标是实现[明日方舟的BUFF效果](https://prts.wiki/w/BUFF#)

生命周期等参考了[Unity-Buff-System](https://github.com/NoSLoofah/)和[如何实现一个强大的MMO技能系统——BUFF](https://zhuanlan.zhihu.com/p/150812545)

- 已实现
	- 基本生命周期与持续时间
	- 生效失效
	- 五种叠加机制（优先级、唯一、堆叠、加时、刷新）
		- 持续时间结束后的处理（消耗一层buff并重置 或 直接移除）
	- 冲突机制
	- 间隔触发机制
- 未实现
	- 抵抗（buff时间流速机制）
	- buff工厂，支持JSON格式生成buff，支持静态配置数据检查

## MIT协议

本项目遵守MIT协议
