SELECT   OBJECT_NAME(i.object_id)  AS [Table Name],
         i.name AS [Not Used Index Name],
         s.last_user_update AS [Last Update Time],
         s.user_updates AS [Updates]
FROM     sys.dm_db_index_usage_stats AS s
JOIN     sys.indexes AS i
ON       i.object_id = s.object_id
AND      i.index_id = s.index_id
JOIN     sys.objects AS o
ON       o.object_id = s.object_id
WHERE    s.database_id = DB_ID()
AND      (    user_scans   = 0
          AND user_seeks   = 0
          AND user_lookups = 0
          AND last_user_scan   IS NULL
          AND last_user_seek   IS NULL
          AND last_user_lookup IS NULL 
         )
AND      OBJECTPROPERTY(i.[object_id],         'IsSystemTable'   ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsAutoStatistics') = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsHypothetical'  ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsStatistics'    ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsFulltextKey'   ) = 0
AND      (i.index_id between 2 AND 250 OR (i.index_id=1 AND OBJECTPROPERTY(i.[object_id],'IsView')=1))
AND      o.type <> 'IT'
ORDER BY OBJECT_NAME(i.object_id)


--_____________________________________

DECLARE @pagesizeKB int
SELECT @pagesizeKB = low / 1024 FROM master.dbo.spt_values
WHERE number = 1 AND type = 'E'

SELECT d.name AS 'database_name',sch.name AS 'schema_name', t.name AS 'table_name', i.name AS 'index_name', 
i.is_disabled,i.is_primary_key,i.is_unique_constraint,i.is_unique,
rows = i1.rowcnt,
reservedKB = (ISNULL(SUM(i1.reserved), 0) + ISNULL(SUM(i2.reserved), 0)) * @pagesizeKB,
dataKB = (ISNULL(SUM(i1.dpages), 0) + ISNULL(SUM(i2.used), 0)) * @pagesizeKB,
index_sizeKB = ((ISNULL(SUM(i1.used), 0) + ISNULL(SUM(i2.used), 0))
- (ISNULL(SUM(i1.dpages), 0) + ISNULL(SUM(i2.used), 0))) * @pagesizeKB,
unusedKB = ((ISNULL(SUM(i1.reserved), 0) + ISNULL(SUM(i2.reserved), 0))
- (ISNULL(SUM(i1.used), 0) + ISNULL(SUM(i2.used), 0))) * @pagesizeKB,
ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates, ius.last_user_seek, ius.last_user_scan, ius.last_user_update,
ius.system_seeks, ius.system_scans, ius.system_updates, ius.last_system_seek, ius.last_system_scan, ius.last_system_update
 FROM sys.dm_db_index_usage_stats ius
 JOIN sys.databases d ON d.database_id = ius.database_id AND ius.database_id=db_id()
 JOIN sys.tables t ON t.object_id = ius.object_id
 JOIN sys.indexes i ON i.object_id = ius.object_id AND i.index_id = ius.index_id
 JOIN     sys.objects AS o ON o.object_id = ius.object_id
 JOIN sys.schemas AS sch ON sch.schema_id = o.schema_id
 LEFT OUTER JOIN sysindexes i1 ON i1.id = o.object_id AND i1.indid < 2
 LEFT OUTER JOIN sysindexes i2 ON i2.id = o.object_id AND i2.indid = 255
 WHERE i.type_desc <> 'CLUSTERED'
AND		 OBJECTPROPERTY(i.[object_id],         'IsSystemTable'   ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsAutoStatistics') = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsHypothetical'  ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsStatistics'    ) = 0
AND      INDEXPROPERTY (i.[object_id], i.name, 'IsFulltextKey'   ) = 0
AND      (i.index_id between 2 AND 250 OR (i.index_id=1 AND OBJECTPROPERTY(i.[object_id],'IsView')=1))
AND      (    ius.user_scans   = 0
          AND ius.user_seeks   = 0
          AND ius.user_lookups = 0
          AND ius.last_user_scan   IS NULL
          AND ius.last_user_seek   IS NULL
          AND ius.last_user_lookup IS NULL 
         )
AND i.is_disabled <> 1
AND o.type <> 'IT'
AND (ius.user_updates /(ius.user_seeks + ius.user_scans + 1) > 1 
OR (ius.last_system_seek <  dateadd(hh,-192,getdate()) OR ius.last_system_seek IS NULL OR ius.last_user_scan IS NULL))
  GROUP BY d.name,sch.name,t.name,i.name,i.is_disabled,i.is_primary_key,i.is_unique_constraint,i.is_unique,
 i1.rowcnt,ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates, ius.last_user_seek, ius.last_user_scan, ius.last_user_update,
ius.system_seeks, ius.system_scans, ius.system_updates, ius.last_system_seek, ius.last_system_scan, ius.last_system_update
 ORDER BY user_updates DESC
