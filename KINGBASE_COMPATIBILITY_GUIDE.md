# Kingbase兼容模式使用指南

## 概述

APIJSON框架现已支持人大金仓数据库（Kingbase）的三种兼容模式：
- **KINGBASE-MYSQL**: 兼容MySQL语法的Kingbase模式
- **KINGBASE-ORACLE**: 兼容Oracle语法的Kingbase模式  
- **KINGBASE-SQLSERVER**: 兼容SQL Server语法的Kingbase模式

## 兼容模式说明

人大金仓数据库支持多种数据库的语法兼容模式。本次修改使APIJSON框架能够识别并正确处理这些兼容模式，确保SQL语句生成符合相应数据库的语法规范。

## 使用方法

### 1. 配置数据库类型

在配置APIJSON时，通过`@database`参数指定Kingbase的兼容模式：

**示例1 - MySQL兼容模式:**
```json
{
  "User": {
    "@database": "KINGBASE-MYSQL",
    "id": 1
  }
}
```

**示例2 - Oracle兼容模式:**
```json
{
  "User": {
    "@database": "KINGBASE-ORACLE", 
    "id": 1
  }
}
```

**示例3 - SQL Server兼容模式:**
```json
{
  "User": {
    "@database": "KINGBASE-SQLSERVER",
    "id": 1
  }
}
```

### 2. 全局配置（推荐）

如果整个项目使用同一种Kingbase兼容模式，建议在AbstractParser中设置全局数据库类型：

```java
AbstractParser parser = new YourParser();
parser.setGlobalDatabase("KINGBASE-MYSQL"); // 根据实际兼容模式选择
```

## 各兼容模式特性

### KINGBASE-MYSQL 模式

此模式下，Kingbase将遵循MySQL语法规范：

- **标识符引号**: 使用反引号 `` ` `` 
  ```sql
  SELECT `id`, `name` FROM `User`
  ```

- **正则表达式**: 支持`regexp_like()`函数
  ```sql
  WHERE regexp_like(`name`, 'pattern', 'i')
  ```

- **WITH AS表达式**: MySQL 8.0+ 支持
  
- **LIMIT分页**: 使用`LIMIT offset, count`语法

### KINGBASE-ORACLE 模式

此模式下，Kingbase将遵循Oracle语法规范：

- **标识符引号**: 使用双引号 `"`
  ```sql
  SELECT "id", "name" FROM "User"
  ```

- **别名语法**: 不使用AS关键字
  ```sql
  SELECT u.id FROM User u
  ```

- **分页语法**: 使用`ROWNUM`或`OFFSET FETCH`
  ```sql
  WHERE ROWNUM BETWEEN 0 AND 10
  ```

- **JSON函数**: 使用Oracle的`json_textcontains()`等函数

- **EXPLAIN语法**: 使用`EXPLAIN PLAN FOR`

### KINGBASE-SQLSERVER 模式

此模式下，Kingbase将遵循SQL Server语法规范：

- **标识符引号**: 使用双引号 `"`或方括号 `[]`

- **EXPLAIN语法**: 使用`SET STATISTICS PROFILE ON`

- **分页语法**: 支持`OFFSET ... ROWS FETCH NEXT ... ROWS ONLY`

## 代码修改说明

### 1. SQLConfig接口

新增三个常量定义：
```java
String DATABASE_KINGBASE_MYSQL = "KINGBASE-MYSQL";
String DATABASE_KINGBASE_ORACLE = "KINGBASE-ORACLE"; 
String DATABASE_KINGBASE_SQLSERVER = "KINGBASE-SQLSERVER";
```

新增三个判断方法：
```java
boolean isKingBaseMySQL();
boolean isKingBaseOracle();
boolean isKingBaseSQLServer();
```

### 2. AbstractSQLConfig类

- 修改`isKingBase()`方法，使其包含三种兼容模式的判断
- 实现三个新的判断方法：`isKingBaseMySQL()`, `isKingBaseOracle()`, `isKingBaseSQLServer()`
- 修改`isTSQL()`方法，Oracle和SQL Server兼容模式属于TSQL语法
- 修改`isMSQL()`方法，MySQL兼容模式属于MSQL语法
- 修改引号、AS关键字、分页、正则表达式等SQL语法生成逻辑

### 3. AbstractSQLExecutor类

- 修改PreparedStatement创建逻辑，支持Kingbase三种兼容模式的JDBC特性

### 4. CommonException类

- 修改数据库类型识别逻辑，能够正确显示Kingbase的兼容模式信息

## 向后兼容性

本次修改完全向后兼容。原有的`KINGBASE`配置方式仍然有效：

```json
{
  "User": {
    "@database": "KINGBASE",
    "id": 1  
  }
}
```

框架会将其识别为Kingbase数据库，但不特定于某一兼容模式。建议明确指定兼容模式以获得最佳SQL语法支持。

## 注意事项

1. **选择正确的兼容模式**: 确保配置的兼容模式与实际Kingbase数据库初始化时选择的兼容模式一致

2. **JDBC驱动**: 使用Kingbase官方提供的JDBC驱动，确保驱动版本支持所选的兼容模式

3. **SQL函数**: 某些数据库特有的函数在不同兼容模式下可能表现不同，请参考Kingbase官方文档

4. **性能测试**: 在生产环境使用前，建议进行充分的性能和兼容性测试

## 示例项目配置

### 数据源配置示例（Spring Boot）

```yaml
spring:
  datasource:
    url: jdbc:kingbase8://localhost:54321/test
    username: SYSTEM
    password: 123456
    driver-class-name: com.kingbase8.Driver
```

### APIJSON配置示例

```java
@Configuration
public class APIJSONConfig {
    
    @Bean
    public AbstractParser parser() {
        AbstractParser parser = new DemoParser();
        // 根据Kingbase初始化时选择的兼容模式进行配置
        parser.setGlobalDatabase("KINGBASE-MYSQL"); 
        return parser;
    }
}
```

## 技术支持

如遇到Kingbase兼容模式相关问题，请：

1. 检查Kingbase数据库的实际兼容模式配置
2. 确认JDBC驱动版本是否支持
3. 查看APIJSON框架生成的SQL语句是否符合预期语法
4. 在APIJSON GitHub仓库提交Issue，附上详细的配置和错误信息

## 更新日志

**版本 8.1.7+**
- 新增KINGBASE-MYSQL兼容模式支持
- 新增KINGBASE-ORACLE兼容模式支持  
- 新增KINGBASE-SQLSERVER兼容模式支持
- 优化Kingbase数据库的SQL语法生成逻辑
- 完善数据库类型识别机制

---

**文档版本**: 1.0  
**最后更新**: 2026-05-10
