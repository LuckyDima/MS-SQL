--Using sys.dm_io_virtual_file_stats
select 
 fs.database_id as [DB ID], fs.file_id as [File Id], mf.name as [File Name] 
 ,mf.physical_name as [File Path], mf.type_desc as [Type], fs.sample_ms as [Time] 
 ,fs.num_of_reads as [Reads], fs.num_of_bytes_read as [Read Bytes] 
 ,fs.num_of_writes as [Writes], fs.num_of_bytes_written as [Written Bytes]
,fs.num_of_reads + fs.num_of_writes as [IO Count] 
 ,convert(decimal(5,2),100.0 * fs.num_of_bytes_read / 
 (fs.num_of_bytes_read + fs.num_of_bytes_written)) as [Read %] 
 ,convert(decimal(5,2),100.0 * fs.num_of_bytes_written / 
 (fs.num_of_bytes_read + fs.num_of_bytes_written)) as [Write %] 
 ,fs.io_stall_read_ms as [Read Stall], fs.io_stall_write_ms as [Write Stall] 
 ,case when fs.num_of_reads = 0 
 then 0.000 
 else convert(decimal(12,3),1.0 * fs.io_stall_read_ms / fs.num_of_reads) 
 end as [Avg Read Stall] 
 ,case when fs.num_of_writes = 0 
 then 0.000 
 else convert(decimal(12,3),1.0 * fs.io_stall_write_ms / fs.num_of_writes) 
 end as [Avg Write Stall] 
from 
 sys.dm_io_virtual_file_stats(null,null) fs join 
 sys.master_files mf with (nolock) on 
 fs.database_id = mf.database_id and fs.file_id = mf.file_id 
 join sys.databases d with (nolock) on 
 d.database_id = fs.database_id 
where 
 fs.num_of_reads + fs.num_of_writes > 0;