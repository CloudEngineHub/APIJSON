-- Run after import.sql. Every returned status must be OK.
SET search_path TO public;

SELECT 'Access' AS table_name, 37 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 37 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Access`
UNION ALL
SELECT 'Chain' AS table_name, 18 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 18 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Chain`
UNION ALL
SELECT 'Comment' AS table_name, 1127 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 1127 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Comment`
UNION ALL
SELECT 'Document' AS table_name, 1877 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 1877 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Document`
UNION ALL
SELECT 'Function' AS table_name, 22 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 22 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Function`
UNION ALL
SELECT 'Login' AS table_name, 321 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 321 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Login`
UNION ALL
SELECT 'Method' AS table_name, 2090 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 2090 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Method`
UNION ALL
SELECT 'Moment' AS table_name, 188 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 188 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Moment`
UNION ALL
SELECT 'Praise' AS table_name, 18 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 18 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Praise`
UNION ALL
SELECT 'Random' AS table_name, 1187 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 1187 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Random`
UNION ALL
SELECT 'Request' AS table_name, 83 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 83 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Request`
UNION ALL
SELECT 'Script' AS table_name, 13 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 13 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Script`
UNION ALL
SELECT 'TestRecord' AS table_name, 5851 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 5851 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `TestRecord`
UNION ALL
SELECT 'Verify' AS table_name, 493 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 493 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Verify`
UNION ALL
SELECT '_Visit' AS table_name, 0 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `_Visit`
UNION ALL
SELECT 'apijson_privacy' AS table_name, 336 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 336 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `apijson_privacy`
UNION ALL
SELECT 'apijson_user' AS table_name, 436 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 436 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `apijson_user`
UNION ALL
SELECT 'Device' AS table_name, 298 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 298 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Device`
UNION ALL
SELECT 'Flow' AS table_name, 200 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 200 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Flow`
UNION ALL
SELECT 'Input' AS table_name, 0 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Input`
UNION ALL
SELECT 'Output' AS table_name, 341 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 341 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `Output`
UNION ALL
SELECT 'System' AS table_name, 278 AS expected_rows,
       COUNT(*) AS actual_rows,
       CASE WHEN COUNT(*) = 278 THEN 'OK' ELSE 'MISMATCH' END AS status
FROM `System`;

-- ViewTable must be present as a view.
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'ViewTable';
