# 选题与有界语义查重

日期：2026-11-11。按照已安装 `osc2026-guide` 的 Project Research Guide 执行研究；固定赛事要求不由检索工具改写。所有查询的原始 stdout、exit code、HTTP 状态及来源摘要保存在仓库外的本地验收材料。失败查询不计为零命中。

## 需求与完成标准

以 Clawpack [Euler 章节](https://www.clawpack.org/riemann_book/html/Euler.html) 的公认守恒律模型为设计基线，独立实现数值算法，不移植其程序。输入密度、速度、压力和热容比，输出可诊断的守恒量演化与精确非真空 Riemann 参照。需求来自成熟跨生态科学计算工具的实际能力，不声称已访谈用户。

三类用户及完整流程：数值方法开发者将激波初值演化后与精确解比较并得到误差；科学计算教学者配置接触间断和边界后运行并检查守恒；嵌入应用开发者通过校验过的数据交换、探针和批量配置取得可继续计算的状态。完成标准为解析恒定态、Sod 星区参照、周期守恒、壁面无质量通量、网格收敛及严格错误语义，三个工作流必须实际运行。

## 不同领域候选比较

1–5 分；硬失败不由总分抵消。顺序为广度、需求、复用、低重合风险、深度、可验证性、可完成性、维护性。

| 候选 | 八项评分 | 结论 |
|---|---|---|
| 天文 FITS HDU/图像/表格 | 4/5/5/1/5/5/4/4 | 33，直接重复淘汰 |
| 机械雨流疲劳与载荷谱 | 4/5/4/1/4/5/5/4 | 32，直接重复淘汰 |
| COMTRADE 电力录波分析 | 4/5/4/1/4/5/4/4 | 31，直接重复淘汰 |
| LLL 整数格约简 | 4/5/5/1/5/5/4/3 | 32，代码反查发现直接实现，淘汰 |
| 一维可压缩气体 Euler 工作流 | 4/5/5/4/5/5/4/4 | 36，通过当前有界检索；选定 |

## 查询范围

实际运行 `moon search <term> --limit 100 --json`。FITS/astronomy/FITS header/binary table；rainflow/fatigue/Goodman/Basquin/cycle counting/ASTM E1049/雨流；COMTRADE/oscillography；LLL/Babai/Lenstra；finite volume/shallow water/Riemann/Godunov/Clawpack/Rusanov/HLL/Burgers/conservation law/compressible/Euler solver/shock tube/finite volume method/gas dynamics/Euler equations/激波/riemann solver/HLL flux/moonshock。结果是模糊排序，100 条上限不代表全生态穷尽。

GitHub REST 仓库及代码搜索每页100：FITS、rainflow、COMTRADE、LLL、Lovasz，以及 `Euler language:MoonBit`、`compressible language:MoonBit`、`shock_tube language:MoonBit`、`Riemann language:MoonBit`、`Rusanov language:MoonBit`、`HLLC language:MoonBit`、`finite_volume language:MoonBit`、`Godunov language:MoonBit`、`density pressure flux language:MoonBit` 和 gas/shock/finite-volume 相关仓库。宽泛 Euler、Sod 等查询超过100条，仅审阅返回页，不能声称全遍历；Riemann24条、compressible89条、Rusanov/finite_volume/Godunov/pressure组合0条。HLLC 两项是压缩测试数据误匹配。含嵌入引号的早期查询存在 native argv 错误，未用其失败作为查重依据，后以无引号组合词查询补充。

实际获取并检查 [awesome-moonbit](https://github.com/moonbitlang/awesome-moonbit) 完整列表，永久注册表全部能力检索以及相关 MoonMultigrid/MoonDOE 指纹。注册表中的保留、完成和外部查验均作为约束。源码 URL 和下面各项目真实目录经 GitHub API 验证；不是根据包名猜测仓库。

## 已有能力与边界

| 项目/版本 | 源码证据与行为 | 分类/决策 |
|---|---|---|
| [cosettese/moonastrofits 0.1.0](https://github.com/cosettese/MoonAstroFITS) | manifest、README、接口、header.mbt；80字节卡、2880对齐、图像及BINTABLE | FITS直接替代，淘汰 |
| [fatigue-spectrum](https://github.com/gckbbrant/fatigue-spectrum) | README/完整tree：雨流索引、S–N、Miner和CLI | 疲劳核心工作流直接重复，淘汰 |
| [oscbridge 0.2.0](https://github.com/dongxuan2012/moonbit-oscbridge) | README/接口，ASCII COMTRADE1999录波及窗口 | 录波直接替代，淘汰 |
| [symbit 0.5.10](https://github.com/CAIMEOX/symbit/blob/main/src/sympolys/lll.mbt) | 实际lll.mbt：BigInt/BigRational Gram-Schmidt、Lovasz、约简和变换矩阵 | LLL直接替代，淘汰 |
| [moon_hydro 0.8.1](https://github.com/toadium/moon_hydro) | README/manifest/tree/shared/swe_core.mbt/swe_core_test.mbt；h/hu，地形、Manning摩擦、浅水dam-break | 数值通量相邻，核心方程与任务不同 |
| [FlowLabLite](https://github.com/YuFenfen-ai/FlowLabLite) | README/tree/cmd/main/solver_fvm.mbt/main_wbtest.mbt；不可压缩FVM-SIMPLE及压力修正、cavity回归 | CFD相邻，非可压缩总能量双曲问题 |
| MoonMultigrid / jqlssg | 永久登记完整指纹；2D椭圆Dirichlet多重网格/MG-PCG，明确不做时间相关CFD | 同数值方向不同输入、方程与结果 |
| MoonDOE | 永久登记试验设计及可辨识性 | 不同工作流 |

共享“有限体积”“CFL”“Riemann”术语本身不是新颖性。独立建设的必要性是气体密度/动量/总能量、热力学物理状态、双波族/接触间断与精确 Riemann 参照的完整一致接口；扩展浅水或不可压缩应用会引入另一套方程和状态模型。SWE水深/流量和压力Poisson流程无法作为此库直接输入/输出契约。

未选方向还包括已有 BioSeqs 系统发育、thinfilm_tmm 偏振和数值插值；未将模糊关键词零命中当作独特性。通过结论限于上述日期、查询、返回页及可读源码范围，GitHub索引和私有/未索引实现可能遗漏，不宣称绝对唯一。实现前已持永久注册表同一路径排他锁重读并原子预留；发布前再次执行核心行为反查。

## 发布前复核（2026-11-11）

通过指定账号的隔离 GitHub API 再查 `Godunov language:MoonBit`、`shock_tube language:MoonBit` 和 `Rusanov language:MoonBit`，各返回 0 项；精确仓库 `ZJH-666-ZJH/moonshock` 返回 404，尚未创建。该复核补充既有源码比较，受公开索引和查询表述限制，不证明绝对唯一。
