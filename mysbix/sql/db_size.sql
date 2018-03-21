SELECT	   Round(Sum(data_length + index_length) / 1024 / 1024, 2)
FROM	   information_schema.tables
WHERE	   table_schema=@p1
GROUP BY   table_schema;
