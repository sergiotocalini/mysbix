SELECT		COUNT(*)
FROM		information_schema.SCHEMATA
WHERE		SCHEMA_NAME
NOT IN		('mysql', 'performance_schema', 'information_schema', 'sys');
