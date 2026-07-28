# KingbaseES Oracle 模式初始化脚本

本目录由 `APIJSON-Demo/Oracle` 生成，面向 KingbaseES V9R1C10 的 Oracle 模式。
生成过程不改写任何 `INSERT` 语句的数据载荷；主初始化脚本包含 17 张表、
4398 条记录，另有 `sys.sql` 中 `db3.CONTRACT` 的 10 条记录。

## 在 KStudio 中执行

1. 使用 Oracle 模式实例连接目标数据库，字符编码使用 UTF-8。
2. 打开并执行 `初始化.sql`，创建主数据表并导入数据。
3. 如需多数据源示例的合同表，再执行 `sys.sql`（会创建 `db3` 模式）。
4. 执行 `验证.sql`，确认每一行的 `status` 都为 `PASS`。

`single/` 与源 Oracle 目录一一对应，是可独立执行的旧版单表脚本。它们和
`初始化.sql` 的快照时间、命名方式并不完全相同，因此不要在执行完整初始化后再整批执行
`single/`，除非确实希望用这些单表快照覆盖对应对象。

所有建表脚本会先尝试删除目标对象，适合在专用测试库中重复执行；请勿直接用于含有业务数据的库。

源转储中有两类 Oracle 空字符串与 `NOT NULL` 冲突：
`Method.class` 的 2 行和 `TestRecord.response` 的 386 行使用 `''`。
KingbaseES Oracle 模式会将空字符串视为 `NULL`，因此生成脚本仅将这两个字段改为可空，
数据值本身保持不变。

源脚本的 `TO_DATE` 使用 `SYYYY` 格式模型；当前 KingbaseES 环境会将无正负号的年份
错误解析为公元前日期，因此生成脚本改用 `YYYY`。所有日期字符串保持不变。

源脚本在 `Comment` 和 `Moment` 上重复使用索引名 `userId`。KingbaseES 的模式级
索引名称必须唯一，因此分别改名为 `Comment_userId` 和 `Moment_userId`，索引列不变。

## 主初始化数据量

| 表 | 期望行数 |
| --- | ---: |
| `_Visit` | 0 |
| `Access` | 29 |
| `apijson_privacy` | 146 |
| `apijson_user` | 146 |
| `b_stone` | 0 |
| `Comment` | 531 |
| `Document` | 258 |
| `Function` | 14 |
| `Login` | 321 |
| `Method` | 299 |
| `Moment` | 97 |
| `Praise` | 18 |
| `Random` | 438 |
| `Request` | 44 |
| `Response` | 3 |
| `TestRecord` | 1908 |
| `Verify` | 146 |
| `db3.CONTRACT` | 10 |

## 兼容依据

- KingbaseES V9R1C10 Oracle 兼容性说明：
  https://docs.kingbase.com.cn/cn/KES-V9R1C10/application/application-develop-guide/kes-vs-oracle/overview/
- KingbaseES V9R1C10 Oracle 模式 SQL 参考：
  https://docs.kingbase.com.cn/cn/KES-V9R1C10/application/application-develop-guide/reference/oracle/sql/
- KStudio 快速上手：
  https://docs.kingbase.com.cn/cn/KES-V9R1C10/application/application-develop-guide/tools/kstudio/quick_start/KStudio_start-2/
