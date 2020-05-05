create event session DB_Usage 
on server 
add event sqlserver.lock_acquired 
( 
 where 
 database_id > 4 and -- Users DB 
 owner_type = 4 and -- SharedXactWorkspace 
 resource_type = 2 and -- DB-level lock 
 sqlserver.is_system = 0 
) 
add target package0.histogram 
( 
 set 
 slots = 32 -- Based on # of DB 
 ,filtering_event_name = 'sqlserver.lock_acquired' 
 ,source_type = 0 -- event data column 
 ,source = 'database_id' -- grouping column 
) 
with 
( 
 event_retention_mode=allow_single_event_loss 
 ,max_dispatch_latency=30 seconds 
); 
