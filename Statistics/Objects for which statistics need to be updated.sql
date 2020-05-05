SELECT DISTINCT 'UPDATE STATISTICS ['+ s.name + '].['+ o.name + ']([' + si.name +']) WITH RESAMPLE'--, STATS_DATE(i.object_id, i.index_id) AS StatsUpdated
FROM [sys].[sysindexes] si
JOIN [sys].[objects] o ON si.id = o.object_id 
JOIN sys.indexes i ON i.object_id = o.object_id 
LEFT JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type = 'U'
AND STATS_DATE(i.object_id, i.index_id) < DATEADD(DAY,-1,GETDATE())


--для 2008R2

SELECT  
  o.name, si.name, si.rowmodctr  
FROM sys.objects o
join sys.sysindexes si on o.object_id = si.id
WHERE
si.status>0 
AND si.rowmodctr>1000 
AND o.type = 'U' 

--c 2012

SELECT 
  o.name, stat.name, modification_counter [rowmodctr]   
FROM sys.stats AS stat
join sys.objects AS o on stat.object_id = o.object_id   
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
WHERE stat.object_id = object_id('[dbo].[Test_table]')
AND modification_counter>1000;
