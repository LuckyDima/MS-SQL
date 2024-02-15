-- Variant 1
DECLARE @pagesizeKB int
SELECT @pagesizeKB = low / 1024 FROM master.dbo.spt_values
WHERE number = 1 AND type = 'E'

SELECT OBJECT_NAME(o.id) 'Name',
       i1.rowcnt 'Rows',
       (ISNULL(SUM(i1.reserved), 0) + ISNULL(SUM(i2.reserved), 0)) * @pagesizeKB 'Reserved(KB)',
       (ISNULL(SUM(i1.dpages), 0) + ISNULL(SUM(i2.used), 0)) * @pagesizeKB 'Data(KB)',
       ((ISNULL(SUM(i1.used), 0) + ISNULL(SUM(i2.used), 0)) - (ISNULL(SUM(i1.dpages), 0) + ISNULL(SUM(i2.used), 0))) * @pagesizeKB 'Index(KB)',
       ((ISNULL(SUM(i1.reserved), 0) + ISNULL(SUM(i2.reserved), 0)) - (ISNULL(SUM(i1.used), 0) + ISNULL(SUM(i2.used), 0))) * @pagesizeKB 'Unused(KB)'
FROM sysobjects o
LEFT JOIN sysindexes i1 ON i1.id = o.id AND i1.indid < 2
LEFT JOIN sysindexes i2 ON i2.id = o.id AND i2.indid = 255
WHERE OBJECTPROPERTY(o.id, N'IsUserTable') = 1 --same as: o.xtype = 'IsView'
OR (OBJECTPROPERTY(o.id, N'IsView') = 1 AND OBJECTPROPERTY(o.id, N'IsIndexed') = 1)
GROUP BY o.id, i1.rowcnt
ORDER BY 'Unused(KB)' DESC;

-- Variant 2

SELECT ISNULL(OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id),'TOTAL:  ---->>>>') 'Name', 
       SUM(IIF(index_id<2,row_count,0)) 'Rows', 
       SUM(reserved_page_count)/128. 'Reserved(MB)', 
       SUM(IIF(index_id<2,in_row_data_page_count+lob_used_page_count+row_overflow_used_page_count,lob_used_page_count+row_overflow_used_page_count))/128. 'Data(MB)', 
       (SUM(used_page_count)-SUM(IIF(index_id<2,in_row_data_page_count+lob_used_page_count+row_overflow_used_page_count,lob_used_page_count+row_overflow_used_page_count)))/128. 'Index(MB)', 
       SUM(reserved_page_count-used_page_count)/128 'Unused(MB)'
FROM sys.dm_db_partition_stats 
WHERE OBJECTPROPERTY(object_id, N'IsUserTable') = 1 
OR (OBJECTPROPERTY(object_id, N'IsView') = 1 AND OBJECTPROPERTY(object_id, N'IsIndexed') = 1)
GROUP BY GROUPING SETS (object_id,())
ORDER BY 'Unused(MB)' DESC;
