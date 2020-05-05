create event session [TempDB Spills] 
on server 
add event sqlserver.hash_warning 
( 
 action ( sqlserver.session_id, sqlserver.plan_handle, sqlserver.sql_text ) 
 where ( sqlserver.is_system=0 ) 
), 
add event sqlserver.sort_warning 
( 
 action ( sqlserver.session_id, sqlserver.plan_handle, sqlserver.sql_text ) 
 where ( sqlserver.is_system=0 ) 
) 
add target package0.event_file 
( set filename='c:\ExtEvents\TempDB_Spiils.xel', max_file_size=25 ), 
add target package0.ring_buffer 
( set max_memory=4096 ) 
with -- Extended Events session properties 
( 
 max_memory=4096KB 
 ,event_retention_mode=allow_single_event_loss 
 ,max_dispatch_latency=15 seconds 
 ,track_causality=off 
 ,memory_partition_mode=none 
 ,startup_state=off 
);