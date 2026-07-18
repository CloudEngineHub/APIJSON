package apijson.orm;

import apijson.RequestMethod;
import apijson.JSON;
import apijson.JSONParser;
import org.junit.BeforeClass;
import org.junit.Test;

import java.math.BigDecimal;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Types;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class KingbaseCompatibilityTest {
	@BeforeClass
	public static void installJsonParser() {
		JSON.DEFAULT_JSON_PARSER = new JSONParser<Map<String, Object>, List<Object>>() {
			@Override
			public Map<String, Object> createJSONObject() {
				return new LinkedHashMap<>();
			}

			@Override
			public List<Object> createJSONArray() {
				return new ArrayList<>();
			}

			@Override
			public Object parse(Object json) {
				if ("{\"enabled\":true}".equals(json)) {
					Map<String, Object> result = createJSONObject();
					result.put("enabled", true);
					return result;
				}
				return json;
			}

			@Override
			public Map<String, Object> parseObject(Object json) {
				return (Map<String, Object>) parse(json);
			}

			@Override
			public <T> T parseObject(Object json, Class<T> clazz) {
				return clazz.cast(parse(json));
			}

			@Override
			public List<Object> parseArray(Object json) {
				return (List<Object>) parse(json);
			}

			@Override
			public <T> List<T> parseArray(Object json, Class<T> clazz) {
				return (List<T>) parse(json);
			}

			@Override
			public String toJSONString(Object obj, boolean format) {
				return String.valueOf(obj);
			}
		};
	}

	private AbstractSQLConfig<Long, Map<String, Object>, List<Object>> config(String database) {
		AbstractSQLConfig<Long, Map<String, Object>, List<Object>> config =
				new AbstractSQLConfig<Long, Map<String, Object>, List<Object>>(RequestMethod.GET, "User") {
					@Override
					public String gainDBVersion() {
						return "9.0.0";
					}

					@Override
					public String gainDBUri() {
						return "jdbc:kingbase8://localhost/test";
					}

					@Override
					public String gainDBAccount() {
						return "test";
					}

					@Override
					public String gainDBPassword() {
						return "test";
					}
				};
		config.setDatabase(database);
		return config;
	}

	@Test
	public void recognizesAllCompatibilityModes() {
		AbstractSQLConfig<Long, Map<String, Object>, List<Object>> mysql = config(SQLConfig.DATABASE_KINGBASE_MYSQL);
		AbstractSQLConfig<Long, Map<String, Object>, List<Object>> oracle = config(SQLConfig.DATABASE_KINGBASE_ORACLE);
		AbstractSQLConfig<Long, Map<String, Object>, List<Object>> sqlServer = config(SQLConfig.DATABASE_KINGBASE_SQLSERVER);

		assertTrue(mysql.isKingBase() && mysql.isKingBaseMySQL() && mysql.isMSQL());
		assertTrue(oracle.isKingBase() && oracle.isKingBaseOracle() && oracle.isTSQL());
		assertTrue(sqlServer.isKingBase() && sqlServer.isKingBaseSQLServer() && sqlServer.isTSQL());
		assertEquals("`", mysql.getQuote());
		assertEquals(" ", oracle.gainAs());
		assertEquals("\"", sqlServer.getQuote());
	}

	@Test
	public void generatesModeSpecificRegularExpressions() {
		String mysql = config(SQLConfig.DATABASE_KINGBASE_MYSQL).gainRegExpString("name", "name", "A.*", true);
		String oracle = config(SQLConfig.DATABASE_KINGBASE_ORACLE).gainRegExpString("name", "name", "A.*", true);
		String sqlServer = config(SQLConfig.DATABASE_KINGBASE_SQLSERVER).gainRegExpString("name", "name", "A.*", true);

		assertTrue(mysql.startsWith("regexp_like("));
		assertTrue(oracle.startsWith("regexp_like("));
		assertTrue(sqlServer.contains(" ~* "));
	}

	@Test
	public void usesJsonbContainmentForEveryKingbaseCompatibilityMode() {
		for (String database : new String[] {
				SQLConfig.DATABASE_KINGBASE_MYSQL,
				SQLConfig.DATABASE_KINGBASE_ORACLE,
				SQLConfig.DATABASE_KINGBASE_SQLSERVER
		}) {
			String sql = config(database).gainContainString("get<>", "get", new Object[] {"UNKNOWN"}, Logic.TYPE_OR);
			assertTrue(sql, sql.contains("::jsonb @>"));
			assertTrue(sql, !sql.contains("json_contains("));
			assertTrue(sql, !sql.contains("json_textcontains("));
		}
	}

	@Test
	public void mapsJdbcValuesToJsonSafeValues() throws Exception {
		AbstractSQLExecutor<Long, Map<String, Object>, List<Object>> executor =
				new AbstractSQLExecutor<Long, Map<String, Object>, List<Object>>() { };
		SQLConfig<Long, Map<String, Object>, List<Object>> config = config(SQLConfig.DATABASE_KINGBASE_MYSQL);

		Object json = executor.mapResultValue(config, "{\"enabled\":true}", Types.OTHER, "jsonb", "settings");
		Object array = executor.mapResultValue(config, new Object[] {1, "two"}, Types.ARRAY, "varchar[]", "tags");

		assertTrue(json instanceof Map);
		assertEquals("true", String.valueOf(((Map<?, ?>) json).get("enabled")));
		assertEquals("1234567890.123456789", executor.mapResultValue(config,
				new BigDecimal("1234567890.123456789"), Types.NUMERIC, "numeric", "amount"));
		assertTrue(array instanceof List);
		assertEquals(2, ((List<?>) array).size());
	}

	@Test
	public void removesOnlyApiGeneratedIdForIdentityColumn() throws Exception {
		AbstractSQLExecutor<Long, Map<String, Object>, List<Object>> executor =
				new AbstractSQLExecutor<Long, Map<String, Object>, List<Object>>() {
					@Override
					protected boolean isAutoGeneratedIdColumn(SQLConfig<Long, Map<String, Object>, List<Object>> config,
							Connection conn) {
						return true;
					}
				};
		AbstractSQLConfig<Long, Map<String, Object>, List<Object>> config = config(SQLConfig.DATABASE_KINGBASE_SQLSERVER);
		config.setMethod(RequestMethod.POST).setId(123L).setIdGeneratedByAPIJSON(true);
		config.setColumn(new ArrayList<>(Arrays.asList("id", "name")));
		config.setValues(new ArrayList<>(Arrays.asList(new ArrayList<Object>(Arrays.asList(123L, "test")))));

		assertTrue(executor.prepareDatabaseGeneratedId(config, null));
		assertEquals(Arrays.asList("name"), config.getColumn());
		assertEquals(Arrays.asList("test"), config.getValues().get(0));
		assertEquals(null, config.getId());
	}

	@Test
	public void hidesOnlyFinalOraclePaginationRowNumber() throws Exception {
		AbstractSQLExecutor<Long, Map<String, Object>, List<Object>> executor =
				new AbstractSQLExecutor<Long, Map<String, Object>, List<Object>>() { };
		SQLConfig<Long, Map<String, Object>, List<Object>> config = config(SQLConfig.DATABASE_KINGBASE_ORACLE).setCount(10);
		ResultSetMetaData metadata = (ResultSetMetaData) Proxy.newProxyInstance(
				getClass().getClassLoader(), new Class<?>[] {ResultSetMetaData.class}, (proxy, method, args) -> {
					if ("getColumnCount".equals(method.getName())) return 3;
					if ("getColumnName".equals(method.getName())) return ((Integer) args[0]) == 3 ? "rn" : "name";
					return null;
				});

		assertFalse(executor.isHideColumn(config, (ResultSet) null, metadata, 0, new LinkedHashMap<>(), 2, null, null));
		assertTrue(executor.isHideColumn(config, (ResultSet) null, metadata, 0, new LinkedHashMap<>(), 3, null, null));
	}
}
