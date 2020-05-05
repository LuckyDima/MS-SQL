--Oldest not committed transaction
select top 5 
 ses_tran.session_id as [Session Id], es.login_name as [Login], es.host_name as [Host] 
 ,es.program_name as [Program], es.login_time as [Login Time] 
 ,db_tran.database_transaction_begin_time as [Tran Begin Time] 
 ,db_tran.database_transaction_log_record_count as [Log Records] 
 ,db_tran.[database_transaction_log_bytes_used] as [Log Used] 
 ,db_tran.[database_transaction_log_bytes_reserved] as [Log Rsrvd] 
 ,sqlText.text as [SQL], qp.query_plan as [Plan] 
from 
 sys.dm_tran_database_transactions db_tran join 
 sys.dm_tran_session_transactions ses_tran on 
 db_tran.transaction_id = ses_tran.transaction_id 
 join sys.dm_exec_sessions es on 
 es.[session_id] = ses_tran.[session_id] 
 left outer join sys.dm_exec_requests er on 
 er.session_id = ses_tran.session_id 
 join sys.dm_exec_connections ec on 
 ec.session_id = ses_tran.session_id 
 cross apply 
 sys.dm_exec_sql_text (ec.most_recent_sql_handle) sqlText 
 cross apply 
 sys.dm_exec_query_plan (er.plan_handle) qp 
where 
 db_tran.database_id = DB_ID() 
order by 
 db_tran.database_transaction_begin_time;