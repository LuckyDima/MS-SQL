--Creates the ALTER TABLE Statements
SET NOCOUNT ON
SELECT 'ALTER TABLE [' + s.[name] + '].[' + o.[name] + '] REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM sys.objects AS o WITH (NOLOCK)
JOIN sys.indexes AS i WITH (NOLOCK) ON o.[object_id] = i.[object_id]
JOIN sys.schemas AS s WITH (NOLOCK) ON o.[schema_id] = s.[schema_id]
JOIN sys.dm_db_partition_stats AS ps WITH (NOLOCK) ON i.[object_id] = ps.[object_id] AND ps.[index_id] = i.[index_id]
JOIN sys.partitions AS p WITH (NOLOCK) ON i.[object_id] = p.[object_id] AND i.[index_id] = p.[index_id]
WHERE o.[type] = 'U' 
  AND ps.[reserved_page_count] > 10000 
  AND p.data_compression_desc != 'PAGE'
ORDER BY ps.[reserved_page_count];


--Creates the ALTER INDEX Statements
SET NOCOUNT ON
SELECT 'ALTER INDEX [' + i.[name] + '] ON [' + s.[name] + '].[' + o.[name] + '] REBUILD WITH (DATA_COMPRESSION=PAGE);'
FROM sys.objects AS o WITH (NOLOCK)
JOIN sys.indexes AS i WITH (NOLOCK) ON o.[object_id] = i.[object_id]
JOIN sys.schemas s WITH (NOLOCK) ON o.[schema_id] = s.[schema_id]
JOIN sys.dm_db_partition_stats AS ps WITH (NOLOCK) ON i.[object_id] = ps.[object_id] AND ps.[index_id] = i.[index_id]
JOIN sys.partitions AS p WITH (NOLOCK) ON i.[object_id] = p.[object_id] AND i.[index_id] = p.[index_id]
WHERE o.type = 'U' 
  AND i.[index_id] > 0 
  AND ps.[reserved_page_count] > 10000 
  AND p.data_compression_desc != 'PAGE'
ORDER BY ps.[reserved_page_count];

--Set advanced settings to reduce competition on the last page of the index
SET NOCOUNT ON
SELECT 'ALTER INDEX [' + i.[name] + '] ON [' + s.[name] + '].[' + o.[name] + '] SET (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON);'
FROM sys.objects AS o WITH (NOLOCK)
JOIN sys.indexes AS i WITH (NOLOCK) ON o.[object_id] = i.[object_id]
JOIN sys.schemas AS s WITH (NOLOCK) ON o.[schema_id] = s.[schema_id]
WHERE o.[type] = 'U' 
  AND i.[index_id] > 0 
  AND i.optimize_for_sequential_key = 0
ORDER BY o.[name], i.[name];
