select  
    r.session_id,
	s.login_name,
	s.host_name,
	s.program_name,
	c.connect_time,
    r.start_time,  
    r.status,  
    r.command,  
    db_name(r.database_id) as db,  
    r.blocking_session_id,  
    r.wait_type,  
    r.wait_time,  
    r.wait_resource,  
    r.percent_complete,  
    r.estimated_completion_time/1024/60 as RemainMinutes,  
    r.cpu_time,  
    r.total_elapsed_time,  
    r.scheduler_id,  
    r.reads,  
    r.writes,  
    r.logical_reads,  
    r.row_count,  
    r.granted_query_memory,  
    case r.statement_end_offset  
    when -1 then NULL  
    else object_name(s2.objectid, s2.dbid)  
    end as ProcedureName,  
    case r.statement_end_offset  
    when -1 then s2.text  
    else substring(s2.text, r.statement_start_offset/2, (r.statement_end_offset/2) - (r.statement_start_offset/2))  
    end as Text,  
    s3.query_plan  
from sys.dm_exec_requests r  
	inner join sys.dm_exec_sessions s on s.session_id=r.session_id 
	inner join sys.dm_exec_connections c on c.session_id=r.session_id 
    cross apply sys.dm_exec_sql_text(r.sql_handle) as s2  
    cross apply sys.dm_exec_query_plan (r.plan_handle) as s3  
where r.status <> 'background'  
    and r.command <> 'task manager'  
    and r.session_id <> @@SPID  
    and r.database_id <> db_id('msdb')  
order by r.cpu_time desc  