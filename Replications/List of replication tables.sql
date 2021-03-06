select @@SERVERNAME as PublisherServerName, sc.name as PublisherSchema, o.name as PublisherTable, sa.filter_clause as PublisherFilter,
ss.srvname as DestinationServerName, ss.dest_db as DestinationDBName, sa.dest_owner as DestinationSchema, sa.dest_table as DestinationTable
from sys.objects as o 
inner join sys.schemas as sc
on o.schema_id = sc.schema_id
inner join dbo.sysarticles as sa
on o.name = sa.name
inner join dbo.syspublications as sp
on sa.pubid = sp.pubid
inner join dbo.syssubscriptions as ss
on sa.artid = ss.artid
where o.type = 'U' and o.is_published = 1 and
 sp.name = 'ws2bknd'