DECLARE @DbName sysname = 'YourDbName';
SELECT TOP (10)
	 backup_size/compressed_backup_size compression_rate
	,backup_start_date
	,backup_finish_date 
	,backup_size
	,database_name
	,server_name
	,machine_name
	,compressed_backup_size
	,user_name
	,CASE 
		WHEN type = 'D' THEN 'FULL'
		WHEN type = 'I' THEN 'DIFF'
		WHEN type = 'L' THEN 'LOG'
		ELSE 'UNKNOWN'
	END
FROM msdb.dbo.backupset 
WHERE database_name = @DbName AND type IN ('D','I')
ORDER BY backup_finish_date DESC;

