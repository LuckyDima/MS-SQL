
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name],*
FROM sys.indexes i
INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id] WHERE i.data_space_id = f.data_space_id
AND i.data_space_id = 3 -- Filegroup
GO


select * from sys.database_files


select * from sys.filegroups

SELECT OBJECT_SCHEMA_NAME(t.object_id) AS schema_name
,t.name AS table_name
,i.index_id
,i.name AS index_name
,p.partition_number
,fg.name AS filegroup_name
,FORMAT(p.rows, '#,###') AS rows,*
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id=p.object_id AND i.index_id=p.index_id
LEFT OUTER JOIN sys.partition_schemes ps ON i.data_space_id=ps.data_space_id
LEFT OUTER JOIN sys.destination_data_spaces dds ON ps.data_space_id=dds.partition_scheme_id AND p.partition_number=dds.destination_id
INNER JOIN sys.filegroups fg ON COALESCE(dds.data_space_id, i.data_space_id)=fg.data_space_id
INNER JOIN sys.database_files fil ON fil.data_space_id = fg.data_space_id
WHERE i.data_space_id=3 AND fil.name = 'TravelStatistic_index2'


select
    fil.name as [FileName],
    fg.name as GroupName,*
from sys.database_files fil
inner join sys.filegroups fg
on fil.data_space_id = fg.data_space_id
