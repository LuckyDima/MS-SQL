select q.query_hash, 
	q.number_of_entries, 
	q.distinct_plans,
	t.text as sample_query, 
	p.query_plan as sample_plan
from (select top 100 query_hash, 
			count(*) as number_of_entries, 
			count(distinct query_plan_hash) as distinct_plans,
			min(sql_handle) as sample_sql_handle, 
			min(plan_handle) as sample_plan_handle
		from sys.dm_exec_query_stats
		group by query_hash
		having count(*) > 1
		order by count(*) desc) as q
	cross apply sys.dm_exec_sql_text(q.sample_sql_handle) as t
	cross apply sys.dm_exec_query_plan(q.sample_plan_handle) as p
	go
