select partition_number as PartitionNumber,
index_type_desc	as IndexType,
index_depth as Depth,
avg_fragmentation_in_percent as AverageFragmentation,
page_count	as Pages,
avg_page_space_used_in_percent	as AveragePageDensity,
record_count as Rows,
ghost_record_count	as GhostRows,
version_ghost_record_count	as VersionGhostRows,
min_record_size_in_bytes as MinimumRecordSize,
max_record_size_in_bytes as MaximumRecordSize,
avg_record_size_in_bytes as AverageRecordSize,
forwarded_record_count as ForwardedRecords 
from sys.dm_db_index_physical_stats(9, 15339119, 14, NULL, 'SAMPLED')