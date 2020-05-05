SELECT /*
           SUBSTRING(dest.text, (deqs.statement_start_offset / 2) + 1, ((CASE deqs.statement_end_offset
                                                                         WHEN -1 THEN datalength(dest.text)
                                                                         ELSE deqs.statement_end_offset
                                                                         END - deqs.statement_start_offset) / 2) + 1) AS statement_text
       */
       dest.text
      ,deqs.statement_start_offset
      ,deqs.execution_count
      ,(deqs.total_logical_reads + deqs.total_logical_writes) / deqs.execution_count AS average_logical_io
      ,deqp.query_plan
      ,decp.objtype
      ,decp.cacheobjtype
      ,deqs.total_logical_reads
      ,deqs.last_logical_reads
      ,deqs.total_logical_writes
      ,deqs.last_logical_writes
      ,deqs.total_worker_time
      ,deqs.last_worker_time
      ,deqs.total_elapsed_time / 1000 AS total_elapsed_time
      ,deqs.last_elapsed_time / 1000 AS last_elapsed_time
      ,deqs.creation_time
      ,deqs.last_execution_time
FROM   sys.dm_exec_cached_plans AS decp
       INNER JOIN sys.dm_exec_query_stats AS deqs
               ON decp.plan_handle = decp.plan_handle
       CROSS APPLY sys.dm_exec_sql_text(decp.plan_handle) AS dest
       CROSS APPLY sys.dm_exec_query_plan(decp.plan_handle) AS deqp
OPTION (RECOMPILE);