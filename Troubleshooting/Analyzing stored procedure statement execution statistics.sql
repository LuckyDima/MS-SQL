--Analyzing stored procedure statement execution statistics
select top 50 
 substring(qt.text, (qs.statement_start_offset/2)+1, 
 (( case qs.statement_end_offset 
 when -1 then datalength(qt.text) 
 else qs.statement_end_offset 
 end - qs.statement_start_offset)/2)+1) as [SQL] 
 ,qs.execution_count as [Exec Cnt] 
 ,qs.total_worker_time as [Total CPU] 
 ,convert(int,qs.total_worker_time / 1000 / qs.execution_count) as [Avg CPU] 
 ,total_elapsed_time as [Total Elps] 
 ,convert(int,qs.total_elapsed_time / 1000 / qs.execution_count) as [Avg Elps] 
 ,qs.creation_time as [Cached] 
 ,last_execution_time as [Last Exec Time] 
 ,qs.plan_handle 
 ,qs.total_logical_reads as [Reads] 
 ,qs.total_logical_writes as [Writes] 
from 
 sys.dm_exec_query_stats qs 
 cross apply sys.dm_exec_sql_text(qs.sql_handle) qt 
where 
 qs.plan_generation_num is null 
order by 
 [Avg CPU] desc