# GD_GamePlay

目前通过GDS实现了能力系统和BUFF系统。这不是插件，而是一组脚本。

属性系统我认为[godot_gameplay_attributes](https://github.com/OctoD/godot_gameplay_attributes)已经满足需求且使用C++实现，性能优秀。
可能为了学习或自定义，会在未来用GDS写一个。

警告：未经过项目实践测试。未有性能测试。制作中，API可能变化。

## GODOT Version

Godot4.4

## Ability System

这里主要仿照了[godot-gameplay-abilities](https://github.com/OctoD/godot-gameplay-abilities)实现。原本实现为C++语言。

使用GDS版本的优势在于：
- 便于直接理解（虽然，原版核心源码只有一个文件，借助AI也可以理解逻辑）
- 极强的扩展性
- 快速验证功能后可以直接转为原版

我会尽可能保持与原版一致的行为。同时，如果想要无缝转原版，请小心扩展，因为C++版本自由度不高。

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
	- buff持续时间流速机制（不打算完全实现mrfz机制，不影响间隔时间）
	- buff工厂(很不成熟的想法，可以删除)
- TODO:
	- 代码优化，补充注释和文档
	- 完善buff工厂功能
	- 实践DEMO

[BUFF系统文档](docs/GD_Buff_Docs/GDBuffDocs.md)（未完工……）

## Guards

可扩展的守卫系统。包括守卫组类和守卫类，并通过上下文字典即context属性在不同守卫中传递数据。

一般建议使用守卫组类，在编辑器中添加守卫资源实现各类守卫功能。但也可以单独使用守卫类，调用时设计好上下文字典。

- 已实现的守卫类：
	- 逻辑守卫
		- GD_AllOfGuard：全真为真
		- GD_AnyOfGuard：全假为假
		- GD_NotGuard：相反
		- GD_ThresholdGuard：门限，大于等于一定数量为真即为真
	- 表达式守卫 GD_ExpressionGuard：基于context和表达式判断正误
- TODO:
	- 不确定是否guard类中也应该加入自己的context属性。未来可能改变。

## utilities

之前实现的一个优先级字典。`已弃用`。

## MIT协议

本项目遵守MIT协议
