# Kingbase 数据库模式切换实现分析

## 1. 结论

当前项目采用的是**显式期望模式 + 服务端真实模式校验 + 已验证数据源路由**机制：

- `KINGBASE_MODE` 或请求配置负责表达期望使用的数据库模式；
- ORM 根据数据库标识选择 SQL 方言；
- Demo 集成层连接 KingbaseES 后执行 `SHOW database_mode`；
- 期望模式与服务端真实模式一致时，才允许取得对应数据源；
- 两者不一致时立即失败，不会回退到未经校验的 JDBC 直连。

一个数据库模式标识会同时决定：

1. APIJSON 使用哪一种 SQL 方言；
2. 使用哪个 Kingbase 数据源和连接池；
3. 使用哪一套分页、标识符引号、参数绑定及结果转换规则；
4. 对应数据源的服务端真实兼容模式是否通过校验。

目前支持以下三种 KingbaseES 兼容模式：

| 数据库标识 | 对应模式 |
| --- | --- |
| `KINGBASE-MYSQL` | KingbaseES MySQL 兼容模式 |
| `KINGBASE-ORACLE` | KingbaseES Oracle 兼容模式 |
| `KINGBASE-SQLSERVER` | KingbaseES SQL Server 兼容模式 |

相关常量定义在：

```text
src/main/java/apijson/orm/SQLConfig.java
```

当前 `feature-kingbase-compatible` 分支已经将未配置环境变量时的默认数据库设为：

```text
KINGBASE-MYSQL
```

## 2. 数据库模式从哪里来

Demo 服务在 `DemoSQLConfig` 的静态代码块中读取环境变量 `KINGBASE_MODE`：

```java
static {
    String kingbaseMode = System.getenv("KINGBASE_MODE");
    DEFAULT_DATABASE = StringUtil.isEmpty(kingbaseMode, true)
            ? DATABASE_KINGBASE_MYSQL
            : KingbaseModeDetector.normalizeConfiguredDatabase(
                    kingbaseMode);
}
```

源码位置：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\demo\DemoSQLConfig.java
```

其行为如下：

```text
KINGBASE_MODE 未设置或为空
            ↓
使用默认值 KINGBASE-MYSQL

KINGBASE_MODE 已设置
            ↓
使用 KINGBASE_MODE 指定的数据库模式
```

由于这段逻辑位于静态代码块中，环境变量一般是在类加载时读取的。因此修改 `KINGBASE_MODE` 后，需要重新启动应用。

## 3. 全局默认模式和请求模式的关系

每个 `SQLConfig` 对象都可以保存自己的 `database` 属性。

ORM 通过 `gainSQLDatabase()` 取得当前实际使用的数据库标识：

```java
public String gainSQLDatabase() {
    String db = getDatabase();
    return db == null ? DEFAULT_DATABASE : db;
}
```

源码位置：

```text
src/main/java/apijson/orm/AbstractSQLConfig.java
```

数据库模式的优先级是：

1. 当前请求或当前 `SQLConfig` 明确设置的 `database`；
2. 全局 `DEFAULT_DATABASE`。

也就是说，请求没有指定数据库模式时使用全局默认值；请求明确指定模式时，可以覆盖全局默认值。

## 4. 模式是如何被自动区分的

### 4.1 方言枚举

项目通过 `KingbaseSQLDialect` 枚举集中管理三种 Kingbase 方言：

```java
public enum KingbaseSQLDialect {
    NONE(null, null, false, false),
    LEGACY(SQLConfig.DATABASE_KINGBASE, "\"", false, false),
    MYSQL(SQLConfig.DATABASE_KINGBASE_MYSQL, "`", true, true),
    ORACLE(SQLConfig.DATABASE_KINGBASE_ORACLE, "\"", false, false),
    SQLSERVER(SQLConfig.DATABASE_KINGBASE_SQLSERVER, "\"", false, false);
}
```

源码位置：

```text
src/main/java/apijson/orm/KingbaseSQLDialect.java
```

`KingbaseSQLDialect.from()` 会根据数据库标识进行精确匹配：

```java
public static KingbaseSQLDialect from(String database) {
    if (database != null) {
        for (KingbaseSQLDialect dialect : values()) {
            if (database.equals(dialect.database)) {
                return dialect;
            }
        }
    }
    return NONE;
}
```

因此，这里的“自动区分”实际上是：

```text
database 字符串
        ↓
KingbaseSQLDialect.from(database)
        ↓
MYSQL / ORACLE / SQLSERVER 方言
```

ORM 方言层本身不依据 JDBC URL、端口或数据库元数据判断模式，仍然以数据库标识为输入。Demo 集成层会额外执行 `SHOW database_mode`，用于验证这个标识是否与服务端真实模式一致。

### 4.2 模式判断方法

`AbstractSQLConfig` 提供了统一判断方法：

```java
isKingBase()
isKingBaseMySQL()
isKingBaseOracle()
isKingBaseSQLServer()
```

其核心实现仍然是将 `gainSQLDatabase()` 返回的数据库标识交给 `KingbaseSQLDialect`：

```java
public boolean isKingBaseMySQL() {
    return isKingBaseMySQL(gainSQLDatabase());
}

public static boolean isKingBaseMySQL(String db) {
    return KingbaseSQLDialect.from(db).isMySQL();
}
```

Oracle 和 SQL Server 模式的判断方式相同。

### 4.3 服务端真实模式检测

Demo 服务新增了 `KingbaseModeDetector`：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\boot\KingbaseModeDetector.java
```

检测器通过以下语句读取 KingbaseES 真实兼容模式：

```sql
SHOW database_mode;
```

并执行以下映射：

| 服务端返回值 | APIJSON 数据库标识 |
| --- | --- |
| `mysql` | `KINGBASE-MYSQL` |
| `oracle` | `KINGBASE-ORACLE` |
| `sqlserver`、`sql_server`、`mssql` | `KINGBASE-SQLSERVER` |

校验逻辑等价于：

```java
String expected = normalizeConfiguredDatabase(expectedDatabase);
String actual = detect(connection);
if (!expected.equals(actual)) {
    throw new SQLException(
            "Kingbase database mode mismatch: expected "
                    + expected + " but server reported " + actual);
}
```

检测结果只负责确认真实模式，不会静默改写期望模式。这样可以避免配置为 Oracle、实际连接 MySQL 模式时，应用自动改变行为而掩盖部署错误。

### 4.4 标识大小写处理

ORM 的方言匹配使用 `String.equals()`，因此请求中的数据库标识仍然需要使用标准大写形式。Demo 启动环境变量 `KINGBASE_MODE` 会先经过 `trim()` 和大写归一化，因此 `kingbase-oracle` 也会被规范化为 `KINGBASE-ORACLE`。

正确写法：

```text
KINGBASE-MYSQL
KINGBASE-ORACLE
KINGBASE-SQLSERVER
```

请求级 `@database` 仍建议使用：

```text
KINGBASE-MYSQL
KINGBASE-ORACLE
KINGBASE-SQLSERVER
```

## 5. 数据库模式如何影响 SQL

模式识别完成后，ORM 会自动应用对应的 SQL 生成规则。

| 行为 | Kingbase-MySQL | Kingbase-Oracle | Kingbase-SQLServer |
| --- | --- | --- | --- |
| 标识符引号 | 反引号 `` ` `` | 双引号 `"` | 双引号 `"` |
| SQL 兼容族 | MySQL 兼容 | Oracle/T-SQL 兼容 | SQL Server/T-SQL 兼容 |
| 表别名 | 使用 `AS` | 省略 `AS` | 使用 `AS` |
| SELECT 分页 | `LIMIT/OFFSET` | `ROWNUM` 包装 | `OFFSET ... FETCH NEXT` |
| UPDATE/DELETE LIMIT | 支持 | 不使用 | 不使用 |
| Explain | `EXPLAIN` | `EXPLAIN PLAN FOR` | `EXPLAIN` |
| Demo 默认 schema | `public` | `PUBLIC` | `public` |

### 5.1 标识符引号

`getQuote()` 根据 `KingbaseSQLDialect` 返回标识符引号：

```java
KingbaseSQLDialect kingbaseDialect =
        KingbaseSQLDialect.from(gainSQLDatabase());

if (kingbaseDialect.isKingbase()) {
    return kingbaseDialect.getIdentifierQuote();
}
```

因此：

```sql
-- Kingbase-MySQL
SELECT `id`, `name` FROM `public`.`User`;

-- Kingbase-Oracle
SELECT "id", "name" FROM "PUBLIC"."User";
```

### 5.2 表别名

Oracle 及 Kingbase-Oracle 模式会省略 `AS`：

```java
public String gainAs() {
    return isOracle() || isKingBaseOracle() || isManticore()
            ? " "
            : " AS ";
}
```

### 5.3 分页

分页逻辑会根据方言选择不同实现：

- Kingbase-MySQL 使用 `LIMIT ... OFFSET ...`；
- Kingbase-Oracle 使用基于 `ROWNUM` 的包装查询；
- Kingbase-SQLServer 使用 `OFFSET ... ROWS FETCH NEXT ... ROWS ONLY`。

相关源码位于：

```text
src/main/java/apijson/orm/AbstractSQLConfig.java
```

方法主要包括：

```java
gainLimitString()
gainOraclePageSQL()
KingbaseSQLDialect.getSelectLimit()
```

### 5.4 JDBC 参数和结果转换

执行器针对三种 Kingbase 模式分别处理 JDBC 参数：

```java
if (config.isKingBaseMySQL()) {
    setKingbaseMySQLArgument(statement, index + 1, value);
}

if (config.isKingBaseOracle()) {
    setKingbaseOracleArgument(statement, index + 1, value);
}

if (config.isKingBaseSQLServer()) {
    setKingbaseSQLServerArgument(statement, index + 1, value);
}
```

查询结果也有相应的模式转换方法：

```java
mapKingbaseMySQLResultValue(...)
mapKingbaseOracleResultValue(...)
mapKingbaseSQLServerResultValue(...)
```

源码位置：

```text
src/main/java/apijson/orm/AbstractSQLExecutor.java
```

## 6. 数据源是如何自动选择的

Spring 启动时会创建三套独立的 Kingbase Druid 数据源：

```java
@Bean
@ConfigurationProperties(prefix = "spring.datasource.kingbase-mysql")
public DruidDataSource kingbaseMysqlDataSource() {
    return new DruidDataSource();
}

@Bean
@ConfigurationProperties(prefix = "spring.datasource.kingbase-oracle")
public DruidDataSource kingbaseOracleDataSource() {
    return new DruidDataSource();
}

@Bean
@ConfigurationProperties(prefix = "spring.datasource.kingbase-sqlserver")
public DruidDataSource kingbaseSqlserverDataSource() {
    return new DruidDataSource();
}
```

源码位置：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\boot\DemoDataSourceConfig.java
```

当前 `application.yml` 中三套默认连接分别是：

| 模式 | 默认 JDBC URL |
| --- | --- |
| Kingbase-MySQL | `jdbc:kingbase8://192.168.219.132:54321/apijson?currentSchema=public` |
| Kingbase-Oracle | `jdbc:kingbase8://192.168.219.132:54322/apijson?currentSchema=PUBLIC` |
| Kingbase-SQLServer | `jdbc:kingbase8://192.168.219.132:54323/apijson?currentSchema=public` |

配置文件位置：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\resources\application.yml
```

新增的 `KingbaseDataSourceRegistry` 将三种期望模式与三个数据源绑定：

```java
configuredDataSources.put(
        SQLConfig.DATABASE_KINGBASE_MYSQL,
        kingbaseMysqlDataSource);
configuredDataSources.put(
        SQLConfig.DATABASE_KINGBASE_ORACLE,
        kingbaseOracleDataSource);
configuredDataSources.put(
        SQLConfig.DATABASE_KINGBASE_SQLSERVER,
        kingbaseSqlserverDataSource);
```

源码位置：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\boot\KingbaseDataSourceRegistry.java
```

执行 SQL 时，`DemoSQLExecutor` 不再直接按 Bean 名称取得 Kingbase 数据源，而是通过注册表取得已经验证的数据源：

```java
if (config.isKingBase()) {
    KingbaseDataSourceRegistry registry = applicationContext
            .getBean(KingbaseDataSourceRegistry.class);
    ds = registry.getVerifiedDataSource(database);
}
```

注册表的校验策略是：

1. 默认模式在 Spring Bean 初始化阶段进行校验；
2. 其他 Kingbase 数据源在第一次使用时进行校验；
3. 开启 `verify-all-on-startup` 后，启动时校验全部三套数据源；
4. 每个已成功校验的数据源会缓存校验状态，正常请求不会重复执行检测；
5. 校验或路由失败会直接抛出异常，不允许落回未验证连接。

配置项如下：

```yaml
apijson:
  kingbase:
    verify-on-startup: ${KINGBASE_VERIFY_ON_STARTUP:true}
    verify-all-on-startup: ${KINGBASE_VERIFY_ALL_ON_STARTUP:false}
```

即使将 `KINGBASE_VERIFY_ON_STARTUP` 设为 `false`，也只是推迟启动时连接；对应数据源第一次使用时仍然必须通过模式校验。

连接缓存键中仍然包含数据库标识，因此不同数据库模式不会使用同一个连接缓存键。

## 7. 完整自动路由流程

整体调用链如下：

```text
KINGBASE_MODE 环境变量
或请求中的 @database
            ↓
DEFAULT_DATABASE / SQLConfig.database
            ↓
gainSQLDatabase()
            ↓
KingbaseSQLDialect.from(database)
            ↓
┌─────────────────────────────┐
│ 选择 SQL 方言               │
│ - 标识符引号                │
│ - 分页语法                  │
│ - Explain 语法              │
│ - 参数绑定                  │
│ - 结果值转换                │
└─────────────────────────────┘
            ↓
isKingBaseMySQL()
isKingBaseOracle()
isKingBaseSQLServer()
            ↓
KingbaseDataSourceRegistry
选择期望模式对应的数据源
            ↓
首次校验时获取 JDBC Connection
并执行 SHOW database_mode
            ↓
期望模式 = 服务端真实模式？
        ├── 否：抛出异常并终止
        └── 是：标记数据源已验证
                    ↓
获取已验证的业务 JDBC Connection
            ↓
执行与兼容模式匹配的 SQL
```

## 8. 从 Kingbase-MySQL 切换到 Kingbase-Oracle

### 8.1 全局模式切换

设计上可以通过环境变量将全局模式切换为 Kingbase-Oracle：

```powershell
$env:KINGBASE_MODE = "KINGBASE-ORACLE"
$env:KINGBASE_ORACLE_URL = "jdbc:kingbase8://数据库IP:端口/apijson?currentSchema=PUBLIC"
$env:KINGBASE_USERNAME = "system"
$env:KINGBASE_PASSWORD = "密码"
```

然后重新启动应用。

重启后会自动发生以下变化：

1. `DEFAULT_DATABASE` 变为 `KINGBASE-ORACLE`；
2. `isKingBaseOracle()` 返回 `true`；
3. ORM 开始生成 Oracle 兼容 SQL；
4. 默认 schema 从 `public` 调整为 `PUBLIC`；
5. `DemoSQLExecutor` 选择 `kingbaseOracleDataSource`；
6. `KingbaseDataSourceRegistry` 连接 `KINGBASE_ORACLE_URL` 指定的实例；
7. 执行 `SHOW database_mode`，确认返回值为 `oracle`；
8. 校验通过后，向业务请求提供 `kingbaseOracleDataSource`；
9. JDBC 参数及结果值使用 Kingbase-Oracle 对应的转换逻辑。

如果服务端返回 `mysql` 或 `sqlserver`，应用会在启动校验阶段失败，并报告期望模式与实际模式不一致。

### 8.2 请求级模式切换

APIJSON 还支持通过请求顶层的 `@database` 指定当前请求使用的数据库模式：

```json
{
  "@database": "KINGBASE-ORACLE",
  "User": {
    "id": 1
  }
}
```

ORM 会检查 `@database` 是否位于支持的数据库列表中：

```java
String database = getString(request, KEY_DATABASE);
if (StringUtil.isNotEmpty(database, false)
        && DATABASE_LIST.contains(database) == false) {
    throw new UnsupportedDataTypeException(...);
}
```

校验通过后，模式会被写入当前请求的 `SQLConfig`：

```java
config.setDatabase(database);
```

对于 SQL JOIN，主表和副表必须使用相同的数据库模式，否则会抛出异常，避免在同一条 SQL 中混用不同方言。

生产环境应谨慎允许客户端传入 `@database`，因为这意味着客户端可能选择不同的数据源和连接池。更稳妥的做法是由服务端固定默认模式，或在权限校验层限制可用的数据库模式。

## 9. “自动区分”的边界

当前实现能够自动完成：

- 根据数据库标识选择方言；
- 根据方言生成不同 SQL；
- 将三种 Kingbase 方言绑定到对应连接池；
- 通过 `SHOW database_mode` 读取服务端真实模式；
- 校验期望模式与服务端真实模式；
- 默认数据源启动时校验，其他数据源首次使用时校验；
- 模式不一致时快速失败；
- 根据方言处理 JDBC 参数和查询结果；
- 隔离不同模式的连接缓存。

当前实现不会自动完成：

- 从 Kingbase JDBC 元数据推断兼容模式；
- 根据端口号推断兼容模式；
- 在模式不一致时静默更改应用期望模式；
- 自动把一个 KingbaseES 实例从 MySQL 模式转换成 Oracle 模式。

因此，应用配置必须与服务端实例保持一致：

```text
KINGBASE-MYSQL
        ↕
KingbaseES MySQL 兼容模式实例

KINGBASE-ORACLE
        ↕
KingbaseES Oracle 兼容模式实例
```

如果应用配置为 `KINGBASE-ORACLE`，但连接到的实例实际运行在 MySQL 兼容模式，注册表会在 SQL 执行前拒绝该数据源，不允许 Oracle 兼容 SQL 发送到 MySQL 模式实例。

## 10. 建议

1. 请求级 `@database` 使用完整且大小写正确的模式标识。
2. 切换全局模式后重启应用。
3. 确保 `KINGBASE_MODE`、JDBC URL 和 KingbaseES 服务端真实模式三者一致。
4. Oracle 模式下确认 schema 大小写，当前默认值为 `PUBLIC`。
5. 生产环境通过环境变量注入用户名和密码，不要使用配置文件中的默认密码。
6. 如果开放请求级 `@database`，应增加权限限制和可用模式白名单。
7. 生产环境建议保持 `KINGBASE_VERIFY_ON_STARTUP=true`。
8. 同时部署三种 Kingbase 模式且要求全部可用时，设置 `KINGBASE_VERIFY_ALL_ON_STARTUP=true`。
9. 不建议通过端口、JDBC URL 或 JDBC 产品名代替 `SHOW database_mode`。

## 11. 当前代码落地情况

本次实现只修改了 Kingbase 相关逻辑，没有修改原生 MySQL、Oracle、SQL Server、PostgreSQL 的数据库常量、判断函数或路由规则。

### 11.1 新增文件

| 文件 | 作用 |
| --- | --- |
| `KingbaseModeDetector.java` | 执行并解析 `SHOW database_mode`，归一化配置模式，校验期望与实际模式 |
| `KingbaseDataSourceRegistry.java` | 绑定三种 Kingbase 模式与数据源，管理启动/首次使用校验状态 |
| `KingbaseModeDetectorTest.java` | 无第三方测试依赖的模式映射、探测及不一致失败测试 |

文件位置：

```text
E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\boot\KingbaseModeDetector.java

E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\src\main\java\apijson\boot\KingbaseDataSourceRegistry.java

E:\project\java\APIJSON-all\APIJSON-Demo\APIJSON-Java-Server\
APIJSONBoot-MultiDataSource\kingbase-smoke\src\KingbaseModeDetectorTest.java
```

### 11.2 修改文件

| 文件 | Kingbase 相关修改 |
| --- | --- |
| `DemoSQLConfig.java` | 固定默认模式为 Kingbase-MySQL；规范化并校验 `KINGBASE_MODE`；提供显式默认模式读取入口 |
| `DemoSQLExecutor.java` | Kingbase 请求改为从已验证注册表取得连接；校验失败禁止回退 |
| `application.yml` | 增加 Kingbase 启动校验配置 |

### 11.3 验证结果

已经完成以下本地验证：

- `APIJSONBoot-MultiDataSource` Maven 编译成功；
- `KingbaseCompatibilityTest` 共 17 个测试全部通过；
- `KingbaseModeDetectorTest` 通过；
- Git 差异检查未发现空白错误；
- 原生数据库的 `SQLConfig` 常量及 `isMySQL()`、`isOracle()`、`isSQLServer()`、`isPostgreSQL()` 实现未修改。

本次验证没有连接外部 KingbaseES 实例，因此真实数据库启动校验需要在目标环境中进一步验证。启动时如果目标实例不可连接、`SHOW database_mode` 不可执行或模式不匹配，应用会按设计快速失败。
