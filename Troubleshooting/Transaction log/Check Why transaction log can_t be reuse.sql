--Check log_reuse_wait_desc for users’ databases
select database_id, name, recovery_model_desc, log_reuse_wait_desc 
from sys.databases 
where database_id >= 5