WITH backupCTE AS (SELECT name, recovery_model_desc, d AS 'Last Full Backup', i AS 'Last Differential Backup', l AS 'Last Tlog Backup' FROM
( SELECT db.name, db.recovery_model_desc,type, backup_finish_date
FROM master.sys.databases db
LEFT OUTER JOIN msdb.dbo.backupset a
ON a.database_name = db.name
WHERE db.state_desc = 'ONLINE'
 ) AS Sourcetable
PIVOT
 (MAX (backup_finish_date) FOR type IN (D,I,L) ) AS MostRecentBackup )
 SELECT * FROM backupCTE





/*
-- ie database has never been backed up..
WHERE [Last Full Backup] IS NULL) 
--transction log not backed up in last 60 minutes.
 WHERE [Last Tlog Backup] < DATEDIFF(mm,GETDATE(),-60) AND recovery_model_desc <> 'SIMPLE') - 
-- no backup in last day.
 WHERE [Last Full Backup] < DATEDIFF(dd,GETDATE(),-1) AND [Last Differential Backup] < [Last Full Backup]) 
-- no differential backup in last day when last full backup is over 8 days old.
 WHERE [Last Differential Backup] < DATEDIFF(dd,GETDATE(),-1) AND [Last Full Backup] < DATEDIFF(dd,GETDATE(),-8) )
 */