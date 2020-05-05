--Delta store and delete bitmap: Analyzing page allocations 

select object_id, index_id, partition_id, allocation_unit_type_desc as [Type] 
,is_allocated,is_iam_page,page_type,page_type_desc 
 ,allocated_page_file_id as [FileId] 
 ,allocated_page_page_id as [PageId] 
from sys.dm_db_database_page_allocations(db_id(),object_id('<table name>'),null,null,'DETAILED')