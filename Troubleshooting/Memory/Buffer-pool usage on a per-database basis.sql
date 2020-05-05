--Buffer-pool usage on a per-database basis 
select database_id as [DB ID], db_name(database_id) as [DB Name] 
 ,convert(decimal(11,3),count(*) * 8 / 1024.0) as [Buffer Pool Size (MB)] 
from sys.dm_os_buffer_descriptors with (nolock) 
group by database_id 
order by [Buffer Pool Size (MB)] desc;