----------------- ��������� ���� -------------------------------

DECLARE @dbname nvarchar (100), @sql nvarchar (1000)
SET @dbname = N'BackendSQL'
USE [master]
SET @sql = 'ALTER DATABASE ' + @dbname + ' SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT;'
EXEC (@sql);
SET @sql = 'ALTER DATABASE ' + @dbname + ' SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT;'
EXEC (@sql);
SET @sql = 'ALTER DATABASE ' + @dbname + ' SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;'
EXEC (@sql);






-----------------����� ������ ���������� -----------------------
--SELECT DATEADD(DD,-7,GETDATE()- {fn CURRENT_time()})

SELECT DISTINCT 'DROP STATISTICS ' + sc.name + '.' + ao.name + '.' + s.name as comm, s.no_recompute, s.name, STATS_DATE(i.object_id, i.index_id) AS sud
FROM sys.[stats]  AS  s  inner join sys.objects as ao
on s.object_id=ao.object_id
inner join sys.indexes as i
on s.object_id=i.object_id
INNER JOIN sys.schemas as sc
ON ao.schema_id = sc.schema_id
where 
auto_created = 1 and /*���������� ������� �������������*/

 ao.type = N'U' /*���������� ������� �������������*/
--and no_recompute = 1 /*���������� �� ����������� ���������*/
--and sud < DATEADD(DD,-7,GETDATE()- {fn CURRENT_time()})
and s.name  like '%_dta_%' OR s.name like '%_WA_%' and sc.name <> 'sys'
order by sud asc




---------------- �������� �������������� ��������------------------------------------
DECLARE @strSQL nvarchar(1024)
DECLARE @objid int
DECLARE @indid tinyint
DECLARE ITW_Stats CURSOR FOR SELECT id, indid FROM sysindexes /*WHERE name LIKE 'hind_%'*/ ORDER BY name
OPEN ITW_Stats
FETCH NEXT FROM ITW_Stats INTO @objid, @indid
WHILE (@@FETCH_STATUS <> -1)
BEGIN
SELECT @strSQL = (SELECT case when INDEXPROPERTY(i.id, i.name, 'IsStatistics') = 1 then 'drop statistics [' else 'drop index [' end + OBJECT_NAME(i.id) + '].[' + i.name + ']'
FROM sysindexes i join sysobjects o on i.id = o.id
WHERE i.id = @objid and i.indid = @indid AND
(INDEXPROPERTY(i.id, i.name, 'IsHypothetical') = 1 OR
(INDEXPROPERTY(i.id, i.name, 'IsStatistics') = 1 AND
INDEXPROPERTY(i.id, i.name, 'IsAutoStatistics') = 0)))
PRINT(@strSQL)
FETCH NEXT FROM ITW_Stats INTO @objid, @indid
END
CLOSE ITW_Stats
DEALLOCATE ITW_Stats
