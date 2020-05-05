--memory grant trouble shooting

select 
 mg.session_id, t.text as [SQL], qp.query_plan as [Plan], mg.is_small, mg.dop 
 ,mg.query_cost, mg.request_time, mg.required_memory_kb, mg.requested_memory_kb 
 ,mg.wait_time_ms, mg.grant_time, mg.granted_memory_kb, mg.used_memory_kb
,mg.max_used_memory_kb 
from 
 sys.dm_exec_query_memory_grants mg with (nolock) 
 cross apply sys.dm_exec_sql_text(mg.sql_handle) t 
 cross apply sys.dm_exec_query_plan(mg.plan_handle) as qp

--Or their for okv versions

;with xmlnamespaces(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
,Statements(PlanHandle, ObjType, UseCount, StmtSimple) 
as 
( 
 select cp.plan_handle, cp.objtype, cp.usecounts, nodes.stmt.query('.') 
 from sys.dm_exec_cached_plans cp with (nolock) 
 cross apply sys.dm_exec_query_plan(cp.plan_handle) qp 
 cross apply qp.query_plan.nodes('//StmtSimple') nodes(stmt) 
) 
select top 50 
 s.PlanHandle, s.ObjType, s.UseCount 
 ,p.qp.value('@CachedPlanSize','int') as CachedPlanSize 
 ,mg.mg.value('@SerialRequiredMemory','int') as [SerialRequiredMemory KB] 
 ,mg.mg.value('@SerialDesiredMemory','int') as [SerialDesiredMemory KB] 
from Statements s 
 cross apply s.StmtSimple.nodes('.//QueryPlan') p(qp) 
 cross apply p.qp.nodes('.//MemoryGrantInfo') mg(mg) 
order by 
 mg.mg.value('@SerialRequiredMemory','int') desc


/*
In SQL Server prior to 2016, you can 
use startup trace flag T8048 to switch per-NUMA node to per-CPU partitioning, which can help reduce 
CXMEMTHREAD waits at the cost of extra memory usage. SQL Server 2016, on the other hand, promotes such 
partitioning to the per-NUMA level and then to the per-CPU level automatically when it detects contention, 
and therefore T8048 is not required
*/

--Analyzing memory-object partitioning and memory usage 
select type, pages_in_bytes 
 ,case 
 when (creation_options & 0x20 = 0x20) 
 then 'Global PMO. Cannot be partitioned by CPU/NUMA Node. T8048 not applicable.' 
 when (creation_options & 0x40 = 0x40) 
 then 'Partitioned by CPU. T8048 not applicable.' 
 when (creation_options & 0x80 = 0x80) 
 then 'Partitioned by Node. Use T8048 to further partition by CPU.' 
 else 'Unknown' 
 end as [Partitioning Type] 
from sys.dm_os_memory_objects 
order by pages_in_bytes desc