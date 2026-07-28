-- KingbaseES V9R1C10 Oracle 模式兼容脚本
-- 数据来源：APIJSON-Demo/Oracle；INSERT 数据载荷保持不变。
-- 建议在 KStudio 中以 UTF-8 编码、Oracle 模式连接执行。

SELECT '_Visit' AS "table_name", COUNT(*) AS "actual_rows", 0 AS "expected_rows", CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "_Visit"
UNION ALL
SELECT 'Access' AS "table_name", COUNT(*) AS "actual_rows", 29 AS "expected_rows", CASE WHEN COUNT(*) = 29 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Access"
UNION ALL
SELECT 'apijson_privacy' AS "table_name", COUNT(*) AS "actual_rows", 146 AS "expected_rows", CASE WHEN COUNT(*) = 146 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "apijson_privacy"
UNION ALL
SELECT 'apijson_user' AS "table_name", COUNT(*) AS "actual_rows", 146 AS "expected_rows", CASE WHEN COUNT(*) = 146 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "apijson_user"
UNION ALL
SELECT 'b_stone' AS "table_name", COUNT(*) AS "actual_rows", 0 AS "expected_rows", CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "b_stone"
UNION ALL
SELECT 'Comment' AS "table_name", COUNT(*) AS "actual_rows", 531 AS "expected_rows", CASE WHEN COUNT(*) = 531 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Comment"
UNION ALL
SELECT 'Document' AS "table_name", COUNT(*) AS "actual_rows", 258 AS "expected_rows", CASE WHEN COUNT(*) = 258 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Document"
UNION ALL
SELECT 'Function' AS "table_name", COUNT(*) AS "actual_rows", 14 AS "expected_rows", CASE WHEN COUNT(*) = 14 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Function"
UNION ALL
SELECT 'Login' AS "table_name", COUNT(*) AS "actual_rows", 321 AS "expected_rows", CASE WHEN COUNT(*) = 321 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Login"
UNION ALL
SELECT 'Method' AS "table_name", COUNT(*) AS "actual_rows", 299 AS "expected_rows", CASE WHEN COUNT(*) = 299 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Method"
UNION ALL
SELECT 'Moment' AS "table_name", COUNT(*) AS "actual_rows", 97 AS "expected_rows", CASE WHEN COUNT(*) = 97 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Moment"
UNION ALL
SELECT 'Praise' AS "table_name", COUNT(*) AS "actual_rows", 18 AS "expected_rows", CASE WHEN COUNT(*) = 18 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Praise"
UNION ALL
SELECT 'Random' AS "table_name", COUNT(*) AS "actual_rows", 438 AS "expected_rows", CASE WHEN COUNT(*) = 438 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Random"
UNION ALL
SELECT 'Request' AS "table_name", COUNT(*) AS "actual_rows", 44 AS "expected_rows", CASE WHEN COUNT(*) = 44 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Request"
UNION ALL
SELECT 'Response' AS "table_name", COUNT(*) AS "actual_rows", 3 AS "expected_rows", CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Response"
UNION ALL
SELECT 'TestRecord' AS "table_name", COUNT(*) AS "actual_rows", 1908 AS "expected_rows", CASE WHEN COUNT(*) = 1908 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "TestRecord"
UNION ALL
SELECT 'Verify' AS "table_name", COUNT(*) AS "actual_rows", 146 AS "expected_rows", CASE WHEN COUNT(*) = 146 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM "Verify"
UNION ALL
SELECT 'db3.CONTRACT' AS "table_name", COUNT(*) AS "actual_rows", 10 AS "expected_rows", CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END AS "status" FROM db3.CONTRACT
ORDER BY 1;
