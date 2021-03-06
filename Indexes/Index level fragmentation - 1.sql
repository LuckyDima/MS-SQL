-- ��������� ������� ������������ ��������
SELECT OBJECT_NAME(dt.object_id), si.name,
dt.avg_fragmentation_in_percent, dt.avg_page_space_used_in_percent
FROM
(SELECT object_id, index_id, avg_fragmentation_in_percent,
avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID('NAV'), -- ��� �� ������ �� ����
NULL, NULL, NULL, 'DETAILED')
WHERE index_id <> 0 ) as dt 
INNER JOIN sys.indexes AS si
ON si.object_id = dt.object_id
AND si.index_id = dt.index_id