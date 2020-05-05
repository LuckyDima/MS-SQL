--original and current costs of cache entries
select 
 q.Text as [SQL], p.objtype, p.usecounts, p.size_in_bytes, mce.Type as [Cache Store] 
 ,mce.original_cost, mce.current_cost, mce.disk_ios_count 
 ,mce.pages_kb /* Use pages_allocation_count in SQL Server prior 2012 */ 
 ,mce.context_switches_count, qp.query_plan
from 
 sys.dm_exec_cached_plans p with (nolock) join 
 sys.dm_os_memory_cache_entries mce with (nolock) on 
 p.memory_object_address = mce.memory_object_address 
 cross apply sys.dm_exec_sql_text(p.plan_handle) q 
 cross apply sys.dm_exec_query_plan(p.plan_handle) qp 
where 
 p.cacheobjtype = 'Compiled plan' and 
 mce.type in (N'CACHESTORE_SQLCP',N'CACHESTORE_OBJCP') 
order by 
 p.usecounts desc