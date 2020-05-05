SELECT  name, physical_name, database_id, file_id, state_desc, size
FROM sys.master_files

---------------


SELECT d.NAME, mf.physical_name
,ROUND(SUM(mf.size) * 8 / 1024, 0) Size_MBs
,(SUM(mf.size) * 8 / 1024) / 1024 AS Size_GBs
,max(mf.growth) as growth
,mf.is_percent_growth
   
FROM sys.master_files mf
INNER JOIN sys.databases d ON d.database_id = mf.database_id
--WHERE d.database_id > 4 -- Skip system databases
GROUP BY d.NAME, mf.physical_name, mf.is_percent_growth
ORDER BY 2
