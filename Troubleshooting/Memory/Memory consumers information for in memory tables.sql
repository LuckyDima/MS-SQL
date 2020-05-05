--Memory consumers information for in memory tables

select 
 i.name as [Index], i.index_id, a.xtp_object_id, a.type_desc, a.minor_id 
 ,c.memory_consumer_id, c.memory_consumer_type_desc as [mc type] 
 ,c.memory_consumer_desc as [description], c.allocation_count as [allocs] 
 ,c.allocated_bytes, c.used_bytes 
from 
 sys.dm_db_xtp_memory_consumers c join 
 sys.memory_optimized_tables_internal_attributes a on 
 a.object_id = c.object_id and a.xtp_object_id = c.xtp_object_id 
 left outer join sys.indexes i on 
 c.object_id = i.object_id and 
 c.index_id = i.index_id and 
 a.minor_id = 0 
where 
 c.object_id = object_id('dbo.MemoryConsumers');