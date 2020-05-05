--Column store index dictionaries
select p.partition_number as [partition], c.name as [column], d.column_id, d.dictionary_id 
 ,d.version, d.type, d.last_id, d.entry_count 
 ,convert(decimal(12,3),d.on_disk_size / 1024.0 / 1024.0) as [Size MB] 
from sys.column_store_dictionaries d join sys.partitions p on 
 p.partition_id = d.partition_id 
 join sys.indexes i on 
 p.object_id = i.object_id 
 left join sys.index_columns ic on 
 i.index_id = ic.index_id and 
 i.object_id = ic.object_id and 
 d.column_id = ic.index_column_id 
 left join sys.columns c on 
 ic.column_id = c.column_id and 
 ic.object_id = c.object_id 
where i.name = '<index name>' 
order by p.partition_number, d.column_id