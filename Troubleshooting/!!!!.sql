-- что сейчас происходит на сервере
select session_id, status, wait_type, command, last_wait_type, percent_complete, qt.text, total_elapsed_time/1000 as [total_elapsed_time, сек],
       wait_time/1000 as [wait_time, сек], (total_elapsed_time - wait_time)/1000 as [work_time, сек]
  from sys.dm_exec_requests as qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  where session_id >= 50 and session_id <> @@spid
  order by 1

-- что сейчас происходит на сервере (подробнее)
select *
  from sys.sysprocesses where spid > 50 and spid <> @@spid and status <> 'sleeping'
  order by spid, ecid



-- фрагментированные индексы
SELECT TOP 100
       DatbaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       i.type_desc,
       [Fragmentation %] = ROUND(avg_fragmentation_in_percent,2),
       page_count,
       partition_number,
       'alter index [' + i.name + '] on [' + sh.name + '].['+ OBJECT_NAME(s.[object_id]) + '] REBUILD' + case
                                                                                                           when p.data_space_id is not null then ' PARTITION = '+convert(varchar(100),partition_number)
                                                                                                           else ''
                                                                                                         end + ' with(maxdop = 1,  SORT_IN_TEMPDB = on)' [sql]
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
  INNER JOIN sys.indexes as i ON s.[object_id] = i.[object_id] AND
                                 s.index_id = i.index_id
  left join sys.partition_schemes as p on i.data_space_id = p.data_space_id
  left join sys.objects o on  s.[object_id] = o.[object_id]
  left join sys.schemas as sh on sh.[schema_id] = o.[schema_id]
  WHERE s.database_id = DB_ID() AND
        i.name IS NOT NULL AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 and
        page_count > 100 and
        avg_fragmentation_in_percent > 10
  ORDER BY 4,page_count




-- задержки
;WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
       100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
        -- Maybe comment these four out if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
        N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
        -- Maybe comment these six out if you have AG issues
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
        N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
        N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
        N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_RECOVERY',
        N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
    AND [waiting_tasks_count] > 0
    )
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
    CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
    ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold

-- итоговое число отсутствующих индексов для каждой базы данных
SELECT [DatabaseName] = DB_NAME(database_id),
       [Number Indexes Missing] = count(*) 
  FROM sys.dm_db_missing_index_details
  GROUP BY DB_NAME(database_id)
  ORDER BY 2 DESC


-- Отсутствующие индексы, вызывающие издержки
SELECT TOP 10 
       [Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0),
       avg_user_impact,
       TableName = statement,
       [EqualityUsage] = equality_columns,
       [InequalityUsage] = inequality_columns,
       [Include Cloumns] = included_columns
  FROM sys.dm_db_missing_index_groups g 
  INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
  INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle
  WHERE database_id = DB_ID()
  ORDER BY [Total Cost] DESC;


-- Неиспользуемые индексы
SELECT DatabaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       user_updates,
       system_updates,
       'EXEC sp_rename ''[dbo].['+OBJECT_NAME(s.[object_id])+'].['+i.name+']'',''disable_'+i.name+''',''INDEX''' as Rename,
       'ALTER INDEX '+i.name+' ON '+OBJECT_NAME(s.[object_id])+' DISABLE' as [Disable]
  FROM sys.dm_db_index_usage_stats s 
  INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] AND
                              s.index_id = i.index_id
  WHERE s.database_id = DB_ID() AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 AND
        user_seeks = 0     AND
        user_scans = 0     AND
        user_lookups = 0   AND
        i.is_disabled <> 1 AND
        i.is_primary_key <> 1
  order by user_updates + system_updates desc


-- Запросы с высокими издержками на ввод-вывод
SELECT TOP 10
       [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count,
       [Total IO] = (total_logical_reads + total_logical_writes),
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, (CASE
                                                                               WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                                                                               ELSE qs.statement_end_offset
                                                                             END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average IO] DESC



-- Запросы с высоким использованием ресурсов ЦП
SELECT TOP 10
       [Average CPU used] = total_worker_time / qs.execution_count,
       [Total CPU used] = total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING(qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average CPU used] DESC;


-- Запросы, страдающие от блокировки
SELECT TOP 10
       [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
       [Total Time Blocked] = total_elapsed_time - total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average Time Blocked] DESC;


-- нагрузку на подсистему ввода-вывода
select top 5 
    (total_logical_reads/execution_count) as avg_logical_reads,
    (total_logical_writes/execution_count) as avg_logical_writes,
    (total_physical_reads/execution_count) as avg_phys_reads,
     Execution_count, 
    statement_start_offset as stmt_start_offset, 
    plan_handle,
    qt.text
from sys.dm_exec_query_stats  qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
order by  (total_logical_reads + total_logical_writes) Desc



-- какой процессор что делает
SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных],
       c.session_id AS [ID сессии],
       t.scheduler_id AS [Номер процессора],
       s.text AS [Текст SQL-запроса]
  FROM sys.dm_exec_connections AS c
  CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
  JOIN sys.dm_os_tasks t ON t.session_id = c.session_id AND
                            t.task_state = 'RUNNING' AND
                            ISNULL(s.dbid,1) > 4
  ORDER BY c.session_id DESC


-- контроль "несжатости"
SELECT DB_NAME() [DbName],
       SCHEMA_NAME(tbl.schema_id) [SchemaName],
       tbl.name [TableName],
       i.name [IndexName],
       p.partition_number AS [PartitionNumber],
       p.data_compression_desc AS [DataCompression],
       p.rows AS [RowCount],
       'EXEC sys.sp_estimate_data_compression_savings ' + '''' + SCHEMA_NAME(tbl.schema_id) + ''', ''' + tbl.name
       + +''', ' + CAST(i.index_id AS VARCHAR(16)) + ', NULL, ''PAGE''' [CompressionForecast],
       'ALTER INDEX [' + i.name + '] ON [' + SCHEMA_NAME(tbl.schema_id) + '].[' + tbl.name
       + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' [CopmressionScript]
FROM sys.tables AS tbl
LEFT JOIN sys.indexes AS i ON (i.index_id > 0 AND i.is_hypothetical = 0)  AND (i.object_id = tbl.object_id)
JOIN sys.partitions AS p ON p.object_id = CAST(tbl.object_id AS INT) AND p.index_id = CAST(i.index_id AS INT)
WHERE p.data_compression_desc <> 'PAGE'
      AND p.rows >= 1000000
      AND i.type NOT IN ( 5, 6 )
ORDER BY p.rows DESC,
         SCHEMA_NAME(tbl.schema_id),
         i.name;




-- статистика по операциям в БД
SELECT t.name AS [TableName],
       fi.page_count AS [Pages],
       fi.record_count AS [Rows],
       CAST(fi.avg_record_size_in_bytes AS int) AS [AverageRecordBytes],
       CAST(fi.avg_fragmentation_in_percent AS int) AS [AverageFragmentationPercent],
       SUM(iop.leaf_insert_count) AS [Inserts],
       SUM(iop.leaf_delete_count) AS [Deletes],
       SUM(iop.leaf_update_count) AS [Updates],
       SUM(iop.row_lock_count) AS [RowLocks],
       SUM(iop.page_lock_count) AS [PageLocks]
  FROM sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) AS iop
  JOIN sys.indexes AS i ON iop.index_id = i.index_id AND
                           iop.object_id = i.object_id
  JOIN sys.tables AS t ON i.object_id = t.object_id AND
                          i.type_desc IN ('CLUSTERED', 'HEAP')
  JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS fi ON fi.object_id=CAST(t.object_id AS int) AND
                                                                                     fi.index_id=CAST(i.index_id AS int)
  GROUP BY t.name, fi.page_count, fi.record_count, fi.avg_record_size_in_bytes, fi.avg_fragmentation_in_percent
  ORDER BY [RowLocks] desc



-- дата обновления статистики
SELECT STATS_DATE(t1.object_id, stats_id), 'UPDATE STATISTICS [' + object_name(t1.object_id) + ']([' + t1.name + ']) WITH FULLSCAN',
       i1.rows
  FROM sys.stats as t1
  inner join sys.sysobjects as t2 on t1.object_id = t2.id
  left join sysindexes as i1 on i1.id = t1.object_id and
                                i1.indid = 1
  where xtype = 'U' and
        STATS_DATE(t1.object_id, stats_id) < GETDATE()-5 and
        -- не учитываем: мусор, постоянные данные, таблицы на удаление
        t1.name not like 'disable%' and
        object_name(t1.object_id) not like '[__]%' and
        object_name(t1.object_id) not like 'T[_]%' and
        object_name(t1.object_id) not like 'OSMP%' and
        -- исключаем автостатистику,
        -- она создана по ad-hoc запросам, поэтому не является необходимой
        -- во время ночных расчетов
         t1.name not like '[_]WA[_]Sys[_]%'
  order by STATS_DATE(t1.object_id, stats_id)





-- i/o-нагрузка на файлы
SELECT TOP 10 DB_NAME(saf.dbid) AS [База данных],
       saf.name AS [Логическое имя],
       vfs.BytesRead/1048576 AS [Прочитано (Мб)],
       vfs.BytesWritten/1048576 AS [Записано (Мб)],
       saf.filename AS [Путь к файлу]
  FROM master..sysaltfiles AS saf
  JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
                                                  vfs.fileid = saf.fileid AND
                                                  saf.dbid NOT IN (1,3,4)
  ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC



-- i/o-нагрузка на диски
SELECT SUBSTRING(saf.physical_name, 1, 1)    AS [Диск],
       SUM(vfs.num_of_bytes_read/1048576)    AS [Прочитано (Мб)],
       SUM(vfs.num_of_bytes_written/1048576) AS [Записано (Мб)]
  FROM sys.master_files AS saf
  JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS vfs ON vfs.database_id = saf.database_id AND
                                                         vfs.file_id = saf.file_id AND
                                                         saf.database_id NOT IN (1,3,4) AND
                                                         saf.type < 2
  GROUP BY SUBSTRING(saf.physical_name, 1, 1)
  ORDER BY [Диск]



-- Занимаемое на диске место
SELECT TOP 1000
       (row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1,
       a3.name AS [schemaname],
       a2.name AS [tablename],
       a1.rows as row_count,
      (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved,
       a1.data * 8 AS data,
      (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
      (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused,
      'ALTER TABLE [' + a2.name  + '] REBUILD' as [sql]
  FROM (SELECT ps.object_id,
               SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
               SUM(ps.reserved_page_count) AS reserved,
               SUM(CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data,
               SUM(ps.used_page_count) AS used
          FROM sys.dm_db_partition_stats ps
          GROUP BY ps.object_id
       ) AS a1
  LEFT JOIN (SELECT it.parent_id,
                    SUM(ps.reserved_page_count) AS reserved,
                    SUM(ps.used_page_count) AS used
               FROM sys.dm_db_partition_stats ps
               INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
               WHERE it.internal_type IN (202,204)
               GROUP BY it.parent_id
            ) AS a4 ON (a4.parent_id = a1.object_id)
  INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
  INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
  WHERE a2.type <> N'S' and a2.type <> N'IT'
  ORDER BY 8 DESC


-- под какие объекты выделена память 
select count(*)as cached_pages_count,
       obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid
  from sys.dm_os_buffer_descriptors as bd
  inner join (select object_id as objectid,
                     object_name(object_id) as name,
                     index_id,allocation_unit_id
                from sys.allocation_units as au
                inner join sys.partitions as p on au.container_id = p.hobt_id and (au.type = 1 or au.type = 3)
                union all
                select object_id as objectid,
                       object_name(object_id) as name,
                       index_id,allocation_unit_id
                  from sys.allocation_units as au
                  inner join sys.partitions as p on au.container_id = p.partition_id and au.type = 2
             ) as obj on bd.allocation_unit_id = obj.allocation_unit_id
  left outer join sys.indexes ind on obj.objectid = ind.object_id and
                                     obj.index_id = ind.index_id
  where bd.database_id = db_id() and
        bd.page_type in ('data_page', 'index_page')
  group by obj.name, ind.name, obj.index_id
  order by cached_pages_count desc
