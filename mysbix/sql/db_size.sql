SELECT	   Sum(data_length + index_length)
FROM	   information_schema.tables
WHERE	   table_schema=@p1
GROUP BY   table_schema;
