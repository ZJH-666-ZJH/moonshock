# 来源与实现边界

MoonShock 是独立实现的一维理想气体 Euler 求解库，不是对既有项目代码的翻译或移植。

- 数学基线：[Clawpack Riemann Book, Euler equations](https://www.clawpack.org/riemann_book/html/Euler.html)。参照其公认方程、激波/稀疏波分类和 Riemann 问题定义；没有复制程序、图像或数据文件。本项目的精确解采用带括号二分，Python 对照独立采用 Newton 及守恒条件。
- HLL、Rusanov、Minmod、MC、SSPRK2 是公开数值方法名。本仓库实现和回归样例由本项目编写。
- [moonbitlang/core](https://github.com/moonbitlang/core) 随官方工具链使用，按该项目自身许可证提供，不在本仓库重新包装发布。
- 相邻 MoonBit 项目 moon_hydro、FlowLabLite 仅用于判断能力重合，未复制其源代码。具体可核查差异见选题证据。

第三方资料自身的著作权和许可证不因被引用而改变。本仓库 MIT 许可证只适用于本项目交付的文件。
