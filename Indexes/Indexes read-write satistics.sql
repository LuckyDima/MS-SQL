select top 100
object_name(s.object_id) as object_name,
i.name as index_name,
i.index_id,
(user_seeks + user_scans + user_lookups) as reads,
user_updates as writes
from sys.dm_db_index_usage_stats as s
inner join sys.indexes as i
on s.object_id = i.object_id
and i.index_id = s.index_id
where objectproperty(s.object_id,'IsUserTable') = 1
and s.database_id = db_id()
and (user_seeks + user_scans + user_lookups) < 1000
order by writes desc, reads asc
go