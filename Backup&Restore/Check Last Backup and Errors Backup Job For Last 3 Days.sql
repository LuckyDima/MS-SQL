
/****** Object:  StoredProcedure [dbo].[CheckBackupForAllDB]    Script Date: 22/08/2017 10:24:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dmitriy Ivanov
-- Create date: 21.07.2107
-- Update: 23.07.2017 Add info about backup job erros for last 3 days
-- Description:	Check Last Backup
-- =============================================
ALTER PROCEDURE [dbo].[CheckBackupForAllDB] 
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#tmp_') IS NOT NULL
    DROP TABLE #tmp_;
IF OBJECT_ID('tempdb..#tmp_2') IS NOT NULL
    DROP TABLE #tmp_2;
IF OBJECT_ID('tempdb..#TmpLastBackupJobFailed') IS NOT NULL
    DROP TABLE #TmpLastBackupJobFailed;
IF OBJECT_ID('tempdb..#JobErrorLog') IS NOT NULL
    DROP TABLE #JobErrorLog;

DECLARE @job_id UNIQUEIDENTIFIER;
DECLARE @step_id INT;
DECLARE @i INT;
DECLARE @tableHTML VARCHAR(MAX);
DECLARE @tableHTML2 VARCHAR(MAX);
DECLARE @CONStableHTML NVARCHAR(MAX) ;

CREATE TABLE #JobErrorLog (
    JobId UNIQUEIDENTIFIER,
    JobName NVARCHAR(256),
    StepId INT,
    StepName NVARCHAR(512),
    StepUID UNIQUEIDENTIFIER,
    DateCreate DATETIME,
    DateModified DATETIME,
    LogSize BIGINT,
    Log NVARCHAR(MAX));


SELECT @@SERVERNAME AS 'Server Name',
       s.name AS 'DB Name',
       s2.recovery_model_desc AS 'Recovery Model',
       b.backup_start_date AS 'Full DB Backup Status',
       c.backup_start_date AS 'Differential DB Backup Status',
       d.backup_start_date AS 'Transaction Log Backup Status'
INTO   #tmp_
  FROM master.dbo.sysdatabases s
  JOIN master.sys.databases s2
    ON s.dbid              = s2.database_id
  LEFT JOIN msdb.dbo.backupset b
    ON s.name              = b.database_name
   AND b.backup_start_date = (   SELECT MAX(backup_start_date) AS 'Full DB Backup Status'
                                   FROM msdb.dbo.backupset
                                  WHERE database_name = b.database_name
                                    AND type          = 'D') --full database backups only, not log backups
  LEFT JOIN msdb.dbo.backupset c
    ON s.name              = c.database_name
   AND c.backup_start_date = (   SELECT MAX(backup_start_date) 'Differential DB Backup Status'
                                   FROM msdb.dbo.backupset
                                  WHERE database_name = c.database_name
                                    AND type          = 'I')
  LEFT JOIN msdb.dbo.backupset d
    ON s.name              = d.database_name
   AND d.backup_start_date = (   SELECT MAX(backup_start_date) 'Transaction Log Backup Status'
                                   FROM msdb.dbo.backupset
                                  WHERE database_name = d.database_name
                                    AND type          = 'L')
 WHERE s.name <> 'tempdb'
 ORDER BY s.name;


SET @tableHTML
    = N'<H3>Last Backup message</H3>' + N'<font FACE="verdana" SIZE="10"> '
      + N'<table BORDER="1" BORDERCOLOR="#C7C7C7" CELLPADDING="1" > ' 
	  + N'<TR BGCOLOR="#99CCFF"><th>Server Name</th>'
      + N'<th>DB Name</th>' 
	  + N'<th>Recovery Model</th>' 
	  + N'<th>Full DB Backup Status</th>'
      + N'<th>Differential DB Backup Status</th>' 
	  + N'<th>Transaction Log Backup Status</th></tr>'
      + CAST((   SELECT td = ISNULL([Server Name],'N/A'),
                        '',
                        td = ISNULL([DB Name],'N/A'),
                        '',
                        td = [Recovery Model],
                        '',
                        td = ISNULL(CAST([Full DB Backup Status] AS VARCHAR(24)), 'N/A'),
                        '',
                        td = ISNULL(CAST([Differential DB Backup Status] AS VARCHAR(24)), 'N/A'),
                        '',
                        td = ISNULL(CAST([Transaction Log Backup Status] AS VARCHAR(24)), 'N/A'),
                        ''
                   FROM #tmp_
                 FOR XML PATH('tr'), TYPE) AS VARCHAR(MAX)) + N'</table></font>';


SELECT TOP 10 name,
       [message],
       [Status] = CASE
                       WHEN run_status = 0 THEN 'Failed'
                       WHEN run_status = 1 THEN 'Succeeded'
                       WHEN run_status = 2 THEN 'Retry'
                       WHEN run_status = 3 THEN 'Canceled' END,
       run_date,
       sj.job_id,
       os.step_id,
       ROW_NUMBER() OVER (ORDER BY run_date DESC) AS rvn
INTO   #TmpLastBackupJobFailed
  FROM msdb.dbo.sysjobhistory sjh (NOLOCK)
  JOIN msdb.dbo.sysjobs sj (NOLOCK)
    ON sj.job_id   = sjh.job_id
  JOIN msdb.dbo.sysjobsteps os (NOLOCK)
    ON os.job_id   = sjh.job_id
   AND os.step_id  = sjh.step_id
  LEFT JOIN msdb.dbo.sysjobstepslogs ol (NOLOCK)
    ON os.step_uid = ol.step_uid
 WHERE run_date >= CAST(CONVERT(VARCHAR(8), DATEADD(DAY, -3, GETDATE()), 112) AS INT)
   AND name LIKE '%DatabaseBackup%'
   AND run_status IN ( 0, 3 )
   AND enabled  = 1;

   SELECT @i = COUNT(*) FROM #TmpLastBackupJobFailed

WHILE @i > 0
BEGIN
    SELECT @job_id = job_id,
           @step_id = step_id
      FROM #TmpLastBackupJobFailed
     WHERE rvn = @i;

    INSERT INTO #JobErrorLog
    EXEC msdb.dbo.sp_help_jobsteplog @job_id = @job_id, @step_id = @step_id;

    SET @i = @i - 1;
END;


SELECT COALESCE(e.JobName, f.name,'N/A') AS 'JobName',
       COALESCE(e.StepId, f.step_id,'N/A') AS 'StepID',
       COALESCE(e.Log, f.message,'N/A') AS 'Error',
       ISNULL(f.Status,'N/A') AS 'Status',
       ISNULL(f.run_date,'N/A') AS 'ErrorDate'
INTO #tmp_2
  FROM #JobErrorLog e
 RIGHT JOIN #TmpLastBackupJobFailed f
    ON e.JobId  = f.job_id
   AND e.StepId = f.step_id;

SET @tableHTML2
    = N'<H3>Last 3 Days Backup Errors</H3>' + N'<font FACE="verdana" SIZE="10"> '
      + N'<table BORDER="1" BORDERCOLOR="#C7C7C7" CELLPADDING="1" > ' 
	  + N'<TR BGCOLOR="#99CCFF"><th>JobName</th>'
	  + N'<th>StepID</th>' 
	  + N'<th>Error</th>'
      + N'<th>Status</th>' 
	  + N'<th>ErrorDate</th></tr>'
      + CAST((   SELECT td = [JobName],
                        '',
                        td = [StepID],
                        '',
                        td = ISNULL(CAST([Error] AS VARCHAR(MAX)), 'N/A'),
                        '',
                        td = ISNULL(CAST([Status] AS VARCHAR(24)), 'N/A'),
                        '',
                        td = ISNULL(CAST([ErrorDate] AS VARCHAR(24)), 'N/A'),
                        ''
                   FROM #tmp_2
                 FOR XML PATH('tr'), TYPE) AS VARCHAR(MAX)) + N'</table></font>';



SET @CONStableHTML = @tableHTML + ISNULL(@tableHTML2,'')

EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SQL Mail',
                             @recipients = 'email@email.ru',
                             @body = @CONStableHTML,
                             @query = '',
                             @subject = 'Check Last Backup and Errors Backup Job For Last 3 Days',
                             @body_format = 'HTML';
END

