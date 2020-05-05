--get info about column store index segments
select p.partition_number as [partition], c.name as [column], s.column_id, s.segment_id 
 ,p.data_compression_desc as [compression], s.version, s.encoding_type, s.row_count 
 , s.has_nulls, s.magnitude,s.primary_dictionary_id, s.secondary_dictionary_id, 
 , s.min_data_id, s.max_data_id, s.null_value 
 , convert(decimal(12,3),s.on_disk_size / 1024.0 / 1024.0) as [Size MB] 
from sys.column_store_segments s join sys.partitions p on 
 p.partition_id = s.partition_id 
 join sys.indexes i on 
 p.object_id = i.object_id 
 left join sys.index_columns ic on 
 i.index_id = ic.index_id and 
 i.object_id = ic.object_id and 
 s.column_id = ic.index_column_id 
 left join sys.columns c on 
 ic.column_id = c.column_id and 
 ic.object_id = c.object_id 
where i.name = '<index name>' 
order by p.partition_number, s.segment_id, s.column_id