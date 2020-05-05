create event session PageSplits_Tracking 
on server 
add event sqlserver.transaction_log 
( 
 where operation = 11 -- lop_delete_split 
 and database_id = 17 
) 
add target package0.histogram 
( 
 set 
 filtering_event_name = 'sqlserver.transaction_log', 
 source_type = 0, -- event column 
 source = 'alloc_unit_id' 
)


--------------------


--Analyzing page-split information 
;with Data(alloc_unit_id, splits) 
as 
( 
 sel ect c.n.value('(value)[1]', 'bigint') as alloc_unit_id, c.n.value('(@count)[1]'
,'bigint') as splits 
 from 
 ( 
 select convert(xml,target_data) target_data 
 from sys.dm_xe_sessions s with (nolock) join sys.dm_xe_session_targets t on 
 s.address = t.event_session_address 
 where s.name = 'PageSplits_Tracking' and t.target_name = 'histogram' 
 ) as d cross apply 
 target_data.nodes('HistogramTarget/Slot') as c(n) 
) 
select 
 s.name + '.' + o.name as [Table], i.index_id, i.name as [Index] 
 ,d.Splits, i.fill_factor as [Fill Factor] 
from 
 Data d join sys.allocation_units au with (nolock) on 
 d.alloc_unit_id = au.allocation_unit_id 
 join sys.partitions p with (nolock) on 
 au.container_id = p.partition_id 
 join sys.indexes i with (nolock) on 
 p.object_id = i.object_id and p.index_id = i.index_id 
 join sys.objects o with (nolock) on 
 i.object_id = o.object_id 
 join sys.schemas s on 
 o.schema_id = s.schema_id