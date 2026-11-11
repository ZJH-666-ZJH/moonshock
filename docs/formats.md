# 数据交换约定

## checkpoint v1

`Simulation::checkpoint()` 导出 UTF-8 可存储的 JSON 字符串。顶层恰好十个字段：schema=1、gamma、left、right、time、steps、retries、initial_totals、boundary_change、cells。cells 的每项恰好含 mass/momentum/energy 三个有限数字。单元数决定 uniform Mesh。恢复检查物理单元、非负时间、整数计数及字段集合；不包含边界策略/数值配置，恢复运行必须重新显式提供它们。未知 schema 拒绝。

恢复结果保持累计步数、缩步次数、初始总量与边界变化；`remeshed` 则开始新的账本和计数。相同快照与相同时间分段可复现，直接一次运行到终点和分段运行的时间步分割可能不同，不能承诺逐位相等。

## 实验 v1

`Experiment::json_config()` 输出完整输入。顶层恰好九项：schema=1、name、gamma、mesh、left_state、right_state、interface_at、end_time、solver。mesh 恰好含 left/right/cells；状态恰好含 rho/velocity/pressure。solver 恰好含 boundaries/reconstruction/flux/integrator/cfl/max_steps/max_retries。

边界名称：periodic/outflow/wall/wall-outflow/outflow-wall；重构：constant/minmod/mc；通量：hll/rusanov；积分：euler/ssprk2。解析拒绝未知枚举、重复键、小数计数和超预算请求。建议通过导出接口生成输入。

## 固定 CSV

首行必须为 `x,rho,velocity,pressure`，其后每个单元一行，正好四个无填充的有限数值字段。接受 LF、CRLF 和一个终末换行；不接受空白内行、引号、额外列/行。x 必须与指定 Mesh 的中心相符：容差为 max(1e-8 dx,4e-15 abs(x))，且上限为 0.25 dx。尾部 CR 会被去除。rho/pressure 必须正；转换为守恒量后也检查浮点范围。

CSV 不携带 gamma、时间、边界账本或策略；须由调用者提供 Gas/Mesh，仅用于数值剖面交换。需要恢复完整演化状态时使用 checkpoint。
