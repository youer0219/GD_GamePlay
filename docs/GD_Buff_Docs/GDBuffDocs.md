# GD_BuffSystem

## 简介

参考+组成+目前状态

## Buff生命周期综述

### Buff初始化

可以通过new方法创建Buff实例。也可以提前保存为资源，通过preload方法加载。

推荐使用后者。因为在目前的设计中，我们尽量将动态变化的数据移到runtime-buff中，而将buff视为静态的数据和逻辑配置单元。
这意味着对于同一个buff，你可以只有一个buff实例，多个runtime-buff实例。

### Buff添加到容器时

Buff应当且仅应当通过容器的`add_buff`方法添加到容器中。在添加过程中会进行一些处理，具体如下：
1. 空值检查
2. 冲突和叠加检查
	- 注意，是已存在的buff（包括同帧添加的buff）检查新buff
	- 存在冲突时立即返回false。明确不存在冲突后实例化runtime-buff。
	- 叠加操作会触发每一个可叠加buff的`_on_buff_stack`方法，直到完成。
		- 但遇到`should_remove_after_stack`返回true的buff时，中断并返回false。
	- 对于同一个buff，冲突优先于叠加。
3. 重复检查：`buff_name`应当唯一
4. 将runtime-buff添加到待添加字典中。runtime-buff连接信号，进入AWAKE状态，触发buff的`_on_buff_awake`方法。
5. 返回true。

在`下一帧`开始时，如果runtime-buff仍然存在与待添加字典中，runtime-buff正式添加到容器中并生效：
1. 将runtime-buff添加到runtime_buffs字典中
2. runtime-buff进入EXIST状态，触发buff的`_on_buff_start`方法。
在回调方法执行后，如能生效，触发buff的`_on_exist_buff_enable`方法。
3. 循环1和2，结束循环后清空待添加字典

添加n个buff的时间复杂度为n^2。请注意性能。

### Buff存在于容器时

在runtime-buff正式添加到容器的同一帧，容器开始每帧调用runtime_buffs字典中的runtime-buff的buff_process方法，
触发buff的`_on_buff_process`方法。

在buff默认实现`_on_buff_process`方法中，会处理runtime-buff的持续时间和间隔触发机制。
满足间隔触发条件时，触发buff的`_on_buff_interval_trigger`方法。
当持续时间结束时，触发buff的`_on_buff_time_end`方法，这里可以实现消耗buff层数重置持续时间的功能（见Buff叠加）。

容器在调用buff_process方法后，最终会调用buff的`should_remove_buff_after_process`方法（通过runtime-buff的同名方法），
以判断是否需要移除该buff。默认移除条件是runtime-buff的持续时间为0。

#### 间隔触发机制

### Buff从容器中移除时

与添加buff不同的是，移除buff是`立即`的。buff将立即失效，然后进入REMOVE状态，触发buff的`_on_buff_remove`方法。
注意，这里是先失效，再移除。

与添加buff相同的是，你应当且仅应当通过容器的`remove_buff`或`remove_runtime_buff`方法来移除buff。

runtime-buff为RefCounted类型，不需要我们管理其销毁，不再引用即可。

### Buff生效失效机制

这里单独讲述buff的生效失效机制。

仅当runtime-buff处于EXIST状态时，才可以触发相关回调。
在EXIST状态修改enable值时，忽视不变的修改，依据变换后的值选择执行
buff的`_on_exist_buff_enable`方法或`_on_exist_buff_disenable`方法。

当buff进入EXIST状态后，会尝试将enable设为`can_enable`方法的返回值。buff被移除前，会自动将enable设为false。
对于一般的buff，can_enable方法的默认返回值为true。

如果enable与其他属性相关，可以通过重写runtime-buff的`can_enable`方法和关联属性的`set`方法实现。
在can_enable方法中加入对属性值的要求。在set方法最后尝试更新enable的值。

## Buff关系实现

### 冲突关系

冲突关系在添加buff时判断。

`绝对冲突`关系是指`buff_name`之间的冲突。同一容器内不允许出现两个同名的buff。实际查找buff时也依赖buff_name的唯一性。

`相对冲突`关系是指开发者设置的各类冲突检测。这里将buff冲突分为四类：
- A存B存：不冲突。这是默认情况。
- A存B不存：A排斥B的添加，但`在添加buff上`允许先B后A
- B存A不存：B排斥A的添加，但`在添加buff上`允许先A后B
- AB互斥：AB不能同时存在于一个容器中。

本项目通过重写buff的`can_stack_with`方法来判断`已有buff是否排斥新buff`。如果你想实现两两互斥，
则需要同时修改两者的`can_stack_with`方法，或者在某一个生效时，驱逐另一个buff。

请注意，AWAKE状态的runtime-buff也会加入到冲突的判断中。

### 叠加关系

叠加关系在冲突关系之后处理。

默认情况下，已有buff判断能否能与新buff叠加的条件是：覆写名称相同且覆写名称未被禁用。

目前实现了五种叠加机制：优先级、刷新、叠层、加时、唯一：
- 优先级：最高优先级生效
- 刷新：持续时间回满
- 叠层：层数加一，触发buff的`_on_stack_layer_change`方法
- 加时：持续时间+新buff持续时间
- 唯一：仅最先加入的buff可以存在

一般的叠加机制后，新runtime-buff会立即结束。但你也可以重写`should_remove_after_stack`方法
以改变新runtime-buff的命运。默认情况下，只有叠加模式为优先级时，会保留新runtime-buff。

请注意，AWAKE状态的runtime-buff也会加入到叠加的处理中。

## Buff工厂
