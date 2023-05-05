SELECT 
   [st].*, 
   [s].[session_id], 
   [s].[original_login_name], 
   [s].[status], 
   [s].[login_time]
FROM (
   SELECT DB_NAME(ISNULL([t].[dbid], 
         (SELECT 
             CAST([value] AS SMALLINT) FROM [sys].[dm_exec_plan_attributes]([st].[plan_handle]) WHERE [attribute] = 'dbid'))) [DatabaseName],
             ISNULL(OBJECT_NAME([t].[objectid], [t].[dbid]),'{AdHocQuery}') [Proc/Func],
             MIN(SUBSTRING([t].[text], ([st].[statement_start_offset]/2)+1, ((CASE [st].[statement_end_offset] WHEN -1 THEN DATALENGTH([t].[text]) ELSE [st].[statement_end_offset] END - [st].[statement_start_offset])/2)+1)) [Text],
             MAX([st].[max_rows]) [Rows],
             SUM([st].[execution_count])/(SELECT MAX(v) FROM (VALUES (DATEDIFF(ss,MIN([st].[creation_time]),GETDATE())), (1)) AS VALUE(v)) [Calls/Sec],
             MAX([st].[max_elapsed_time])/1000000 [TimeSec],
             MAX([st].[max_worker_time])/1000000 [CpuTimeSec],
             MAX([st].[max_logical_reads]+[st].[max_logical_writes])*8/1024/1024 [IOinGB],
             MAX([st].[max_dop]) [DOP],
             MAX([st].[max_reserved_threads])-MAX([st].[max_used_threads]) [ThreadsExceeded],
             (MAX([st].[max_grant_kb])-MAX([st].[max_used_grant_kb]))/1024 [MemoryExceededMb],
             'SELECT [query_plan] FROM [sys].[dm_exec_query_plan](0x'+CONVERT(VARCHAR(MAX),[st].[plan_handle],2)+')' [ViewPlan],
             [st].[sql_handle]
          FROM [sys].[dm_exec_query_stats] [st]
          CROSS APPLY [sys].[dm_exec_sql_text]([st].[sql_handle]) [t]
          GROUP BY [st].[sql_handle], [st].[query_hash], [st].[plan_handle], [t].[dbid], [t].[objectid]) [st]
   INNER JOIN [sys].[dm_exec_connections] [c] ON [c].[most_recent_sql_handle]=[st].[sql_handle]
   INNER JOIN [sys].[dm_exec_sessions] [s] ON [s].[session_id]=[c].[most_recent_session_id]
ORDER BY (
   SELECT MAX(v) 
   FROM (VALUES ([Calls/Sec]), ([TimeSec]), ([CpuTimeSec]), ([IOinGB]), ([DOP]), ([ThreadsExceeded]), ([MemoryExceededMb])) AS VALUE(v)) DESC,
   [s].[login_time];
