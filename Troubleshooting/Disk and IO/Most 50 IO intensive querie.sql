--50 most I/O-intensive querie
select top 50 
 substring(qt.text, (qs.statement_start_offset/2)+1, 
 (( 
 case qs.statement_end_offset 
 when -1 then datalength(qt.text) 
 else qs.statement_end_offset 
 end - qs.statement_start_offset)/2)+1) as SQL 
 ,qp.query_plan as [Query Plan] 
 ,qs.execution_count as [Exec Cnt] 
 ,(qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count as [Avg IO] 
 ,qs.total_logical_reads as [Total Reads], qs.last_logical_reads as [Last Reads] 
 ,qs.total_logical_writes as [Total Writes], qs.last_logical_writes as [Last Writes] 
 ,qs.total_worker_time as [Total Worker Time], qs.last_worker_time as [Last Worker Time] 
 ,qs.total_elapsed_time / 1000 as [Total Elapsed Time] 
 ,qs.last_elapsed_time / 1000 as [Last Elapsed Time] 
 ,qs.last_execution_time as [Last Exec Time] 
 ,qs.total_rows as [Total Rows], qs.last_rows as [Last Rows] 
 ,qs.min_rows as [Min Rows], qs.max_rows as [Max Rows] 
from 
 sys.dm_exec_query_stats qs with (nolock) 
 cross apply sys.dm_exec_sql_text(qs.sql_handle) qt 
 cross apply sys.dm_exec_query_plan(qs.plan_handle) qp 
order by 
 [Avg IO] desc



--Above 2008

select top 50 
 db_name(ps.database_id) as [DB] 
 ,object_name(ps.object_id, ps.database_id) as [Proc Name] 
 ,ps.type_desc as [Type] 
 ,qp.query_plan as [Plan] 
 ,ps.execution_count as [Exec Count] 
 ,(ps.total_logical_reads + ps.total_logical_writes) / ps.execution_count as [Avg IO] 
 ,ps.total_logical_reads as [Total Reads], ps.last_logical_reads as [Last Reads] 
 ,ps.total_logical_writes as [Total Writes], ps.last_logical_writes as [Last Writes] 
 ,ps.total_worker_time as [Total Worker Time], ps.last_worker_time as [Last Worker Time] 
 ,ps.total_elapsed_time / 1000 as [Total Elapsed Time] 
 ,ps.last_elapsed_time / 1000 as [Last Elapsed Time] 
 ,ps.last_execution_time as [Last Exec Time] 
from 
 sys.dm_exec_procedure_stats ps with (nolock) 
 cross apply sys.dm_exec_query_plan(ps.plan_handle) qp 
order by 
 [Avg IO] desc

--sys.dm_exec_function_stats return the statistics about execution scalar udf