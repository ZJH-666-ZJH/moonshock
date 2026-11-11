# MoonShock

纯 MoonBit 的一维可压缩理想气体 Euler 方程库。它将精确 Riemann 参照、有限体积时间推进、守恒诊断、恢复与数据交换放在同一套可校验的接口中，供数值方法开发、科学计算教学和嵌入式仿真工具复用。

模块：`ZJH-666-ZJH/moonshock@0.1.0`。许可证：MIT。源码与问题反馈：[GitHub](https://github.com/ZJH-666-ZJH/moonshock)。[MoonCakes](https://mooncakes.io/docs/ZJH-666-ZJH/moonshock)。

## 解决什么问题

编写一个激波管样例后，通常还需要自己处理物理状态校验、误差参照、边界通量记账、断点恢复和网格比较。MoonShock 提供可复用的库接口和三个带断言的完整工作流：

- 数值方法开发者输入 Sod/Lax/自定义左右状态，运行 HLL 或 Rusanov，取得精确解误差和守恒残差。
- 教学者输入周期熵波和一组分辨率，与解析单元平均值比较，观察误差与实测收敛阶。
- 应用开发者导入严格实验 JSON，批量运行、按时间采样，通过 checkpoint 恢复、CSV 交换或守恒重映射接入后续计算。

## 环境与安装

要求 **moonc ≥ 0.10.16**。开发过程的兼容基线为 `v0.10.16+b1a0e846e`；CI 固定使用 `v0.10.20+65efd5b93`，不随 latest 漂移。可在 [MoonBit 官网](https://www.moonbitlang.com/download) 安装工具链，并运行 `moon version --all` 核对编译器。JS 运行需要 Node.js；native 需要 C 编译器。库无第三方运行依赖。

创建一个空目录并执行：

```sh
moon new moonshock-consumer
cd moonshock-consumer
moon add ZJH-666-ZJH/moonshock@0.1.0
```

在消费者的 `cmd/main/moon.pkg` 中导入模块（若生成的目录不同，以自己的主程序目录为准）：

```moonbit
import {
  "ZJH-666-ZJH/moonshock" @gas,
}

options("is-main": true)
```

将该目录下的 `main.mbt` 替换为：

```moonbit
fn main {
  try {
    let gas = @gas.Gas::new(1.4)
    let mesh = @gas.Mesh::new(0.0, 1.0, 96)
    let (left, right) = @gas.TubeCase::Sod.states()
    let initial = gas.shock_tube(mesh, left, right, 0.5)
    let result = @gas.Simulation::new(gas, mesh, initial)
      .run_until(0.15, @gas.SolverConfig::standard())
    assert_true(result.conservation_residual().max_abs() < 1.0e-11)
    println(result.profile_csv())
  } catch {
    error => abort("MoonShock: \{error}")
  }
}
```

运行 `moon run cmd/main --target wasm-gc`。输出四列 `x,rho,velocity,pressure` 数值表。该片段也是仓库 [Sod 示例](examples/sod/main.mbt) 的简化消费方式。

## 实现范围

守恒变量为密度、动量密度、总能量密度；原始变量为密度、速度、压力，采用常数热容比 `gamma > 1` 的理想气体状态方程。所有输入应使用一致单位。

| 能力 | 接口与行为 |
|---|---|
| 热力学与通量 | `Gas::new`、`Primitive::new`、`conserved`、`primitive`、`physical_flux`；拒绝非有限数和非正密度/压力 |
| 精确参照 | `riemann` 用带括号二分求解非真空星区，提供波速、星区密度、空间/相似坐标采样；有迭代上限与残差检查 |
| 数值演化 | HLL/Rusanov，Constant/Minmod/MonotonizedCentral，ForwardEuler/SSPRK2；CFL `(0,0.5]`、阶段物理状态校验和有界重试 |
| 边界 | 周期；左右独立流出或反射壁；反射速度，记录积分边界通量 |
| 诊断 | 总质量/动量/能量、最小密度/压力、最大 Mach/波速、密度总变差、动能、熵积分、守恒残差 |
| 完整实验 | `Experiment::new` / `run` / `json_config`、`parse_experiment`、`run_batch`，每个失败不取消后续实验 |
| 恢复与交换 | `checkpoint` / `restore_checkpoint`、`profile_csv` / `import_csv`、`remeshed` / `remap` / `integrate` |
| 观测与验证 | `probe`、`observe`、`entropy_convergence`；解析周期波误差、观测阶与守恒审计 |

`pkg.generated.mbti` 是完整公开接口清单。[设计说明](docs/architecture.md) 说明数值约束与误差语义；[格式说明](docs/formats.md) 给出 JSON/CSV 和恢复约定。

## 可运行的工作流

克隆仓库后运行以下命令；每个示例均包含结果断言，失败会以非零状态退出。

```sh
moon run examples/sod --target wasm-gc
moon run examples/restart --target wasm-gc
moon run examples/study --target wasm-gc
```

- `sod`：96 单元演化至 0.15，比较非真空精确参照，检查边界尚未影响参照和守恒残差。默认策略下密度归一化 L1 误差约 0.00541。
- `restart`：计算至 0.05，JSON 保存/恢复，再按 0.075/0.1 采样；检查相同时间分段的结果、CSV 往返及 48→96 单元重映射的积分守恒。
- `study`：24/48/96 单元周期熵波，输出实测误差与阶；再验证完整配置往返和独立批量运行。默认设置下末级观测阶约 2.06，该数值只对应本例，不代表所有间断解都有二阶收敛。

更改数值策略的例子：

```moonbit
let config = @gas.SolverConfig::new(
  @gas.Boundaries::Periodic,
  @gas.Reconstruction::Minmod,
  @gas.FluxMethod::Rusanov,
  @gas.Integrator::SspRk2,
  cfl=0.3,
  max_steps=10000,
  max_retries=20,
)
```

实验配置采用 `experiment.json_config()` 导出，再以 `@gas.parse_experiment(text).run()` 消费，避免手写不完整配置。checkpoint 不包含数值策略；恢复后须显式提供 `SolverConfig`。`run_until` 返回新快照，错误不会改变输入快照；`cells()` 返回数组副本。

## 检查、构建与测试

```sh
moon info
moon fmt --check
moon check --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
python3 scripts/verify_oracle.py --target wasm-gc
python3 scripts/source_inventory.py
```

将 `wasm-gc` 替换为 `wasm`、`js`、`native` 可检查其余后端。CI 对四个后端分别执行严格检查、构建、全部测试、三个示例及独立数值对照，另外检查格式和最低编译器版本。当前有 44 项测试，包含 12 种数值策略组合的恒定态、强激波、双稀疏波、壁面碰撞、守恒、恢复与严格解析路径。

独立对照脚本仅用 Python 标准库，采用带导数的 Newton 求根，与库的二分算法不同；42 组确定性初值覆盖不同热容比、密度、速度、压力，输出 378 个状态，并检查 Rankine–Hugoniot 激波条件与稀疏扇不变量。它提供有界差分与物理不变量证据，不声称形式证明或覆盖全部浮点输入。

## 数值与资源限制

- 只实现一维、无粘、单种常热容比理想气体。无真空生成解，无多维网格、化学反应、重力、GPU 或工程安全认证。真空输入明确返回错误。
- 数值解使用单元平均值；激波实验误差参照取单元中心的精确点值，间断附近存在采样约定误差。周期熵波收敛研究使用解析单元平均值。
- `reference_unaffected_by_boundaries` 仅在双端流出且精确波尚未到边界时为真；为假时不能把该误差当作有限域的物理精度证据。HLL/Rusanov 的数值扩散会拓宽激波和接触间断。
- 正性检查与缩步重试是失败检测与恢复机制，不构成任意输入的全局正性证明。极端浮点范围、不可表示网格/时间、预算耗尽会报错。
- 网格 2..1,000,000 单元；单次最多 10,000,000 接受步，单步最多 40 次缩步；累计步数及重试不超过 1,000,000,000。大坐标偏移要求 `dx ≥ 3.6e-15 × max(abs(left),abs(right))`，以保留可分辨坐标。
- 批量实验最多 1,000 项；输入规模和时间预算由调用者控制。checkpoint/CSV 至多 256,000,000 UTF-16 代码单元，实验 JSON 至多 1,000,000。不能将这些上限直接用作不可信公网服务的内存/CPU 配额。
- 固定 CSV 只接受数值四列，不支持引号/注释/任意列名。重映射是同一物理区间的分片常量投影，会损失亚单元结构；重网格开启新的守恒账本。
- checkpoint 不是签名格式；内部边界账本用于数值审计，不证明数据来源可信。反序列化拒绝重复、缺失、额外字段和非物理单元。

## 许可证、参考和 AI 使用

项目源码按 [MIT](LICENSE) 发布。MoonBit core 为官方运行依赖。数学设计参考 Clawpack Riemann Book 的 [Euler 章节](https://www.clawpack.org/riemann_book/html/Euler.html)，本项目独立实现算法及测试，没有复制其代码或测试数据，也不声明为 Clawpack 的完整移植。详见 [来源与边界](NOTICE.md)。

项目在参与者授权下使用 AI 编程代理协助选题检索、实现、测试、文档和发布；质量结论以可运行测试、公开 CI 与发布消费者验证为依据。查重范围与相邻方案差异记录在 [选题证据](docs/competition/duplicate-check.md)，不宣称穷尽生态或绝对唯一。
