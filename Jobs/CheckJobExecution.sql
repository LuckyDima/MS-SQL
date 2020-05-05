CREATE TABLE [dbo].[JOBsExecutionCheckLog](
	[ServerName] [varchar](255) NULL,
	[JobName] [varchar](512) NULL,
	[run_date] [datetime] NULL,
	[EmailSendTime] [datetime] NULL
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[JOBsExecutionTimeBenchmarks](
	[ServerName] [varchar](255) NOT NULL,
	[JobName] [varchar](512) NOT NULL,
	[Approximate running time] [int] NOT NULL,
	[min_execution_time] [int] NULL,
	[max_execution_time] [int] NULL
) ON [PRIMARY]

GO





SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Needed rights for linked server

USE [msdb]
GO

CREATE ROLE [check JOB]
GO

GRANT SELECT ON [dbo].[sysjobs] TO [check JOB]
GO

GRANT SELECT ON [dbo].[sysjobhistory] TO [check JOB]
GO

ALTER ROLE [check JOB] ADD MEMBER [Readonly]
GO

*/


ALTER PROCEDURE [dbo].[CheckJobExecution] 
(	@recipients VARCHAR(MAX) = 'email',
	@copy_recipients VARCHAR(MAX) = '',
	@profile_name1 sysname = ''	,
	@show_all bit = 0,
	@server_list varchar(max)	= 'servername'
)
AS
set nocount on

declare @html nvarchar(max),		
		@MailSubject NVARCHAR(255),
		@Importance VARCHAR(6) = 'Normal'

declare  @server_list_table table
(
	ServerId int identity(1, 1)
	, ServerName varchar(255)
)

insert into @server_list_table
select [Data] from [DbAdmin].[dbo].[SplitByDelim](@server_list, ',')
where [Data] <> @@SERVERNAME

declare @job_hystory table
(
	[server] varchar(max) NOT NULL,	
	[job_id] uniqueidentifier NOT NULL,
	[job_name] varchar(max) NOT NULL,
	[run_status] int NOT NULL,
	[run_date] int NOT NULL,
	[run_time] int NOT NULL,
	[run_duration] int NOT NULL,
	[message] varchar(max) NOT NULL,
	[operator_emailed] int NULL,
	[operator_netsend] int NULL,
	[operator_paged] int NULL,
	[retries_attempted] int NOT NULL	
)

declare @job_hystory_small table
(
	[server] varchar(max) NOT NULL,
	[job_id] uniqueidentifier NOT NULL,
	[job_name] varchar(max) NOT NULL,
	[run_status] int NOT NULL,
	[run_date] datetime NOT NULL,
	[seconds_elapsed] float NOT NULL,	
	[message] varchar(max) NOT NULL
)

declare @job_running table
(
	[server] varchar(max) NOT NULL,
	[job_name] uniqueidentifier NOT NULL,
	[running_sec] int
)

insert into @job_running
(
	[server]
	, [job_name]
	, [running_sec]
)
SELECT 
	[server]
	, [JobName]
	, datediff(SECOND, StartDate, getdate()) as running_sec
FROM
(
	SELECT 
		@@SERVERNAME as [server]
		, JobName     = sj.job_id 
		, StartDate = sja.start_execution_date 
		, EndDate   = sja.stop_execution_date 
		, Status    = CASE  
						WHEN ISNULL(sjh.run_status,-1) = -1 AND sja.start_execution_date IS NULL AND sja.stop_execution_date IS NULL THEN 'Idle' 
						WHEN ISNULL(sjh.run_status,-1) = -1 AND sja.start_execution_date IS NOT NULL AND sja.stop_execution_date IS NULL THEN 'Running' 
						WHEN ISNULL(sjh.run_status,-1) =0  THEN 'Failed' 
						WHEN ISNULL(sjh.run_status,-1) =1  THEN 'Succeeded' 
						WHEN ISNULL(sjh.run_status,-1) =2  THEN 'Retry' 
						WHEN ISNULL(sjh.run_status,-1) =3  THEN 'Canceled' 
					  END 
	FROM MSDB.DBO.sysjobs sj 
	JOIN MSDB.DBO.sysjobactivity sja 
		ON sj.job_id = sja.job_id  
	JOIN (SELECT MaxSessionid = MAX(Session_id) FROM MSDB.DBO.syssessions) ss 
		ON ss.MaxSessionid = sja.session_id 
	LEFT JOIN MSDB.DBO.sysjobhistory sjh 
		ON sjh.instance_id = sja.job_history_id
) running_jobs
where [Status] = 'Running'

declare @job_exec_time_average table
(
	[server] varchar(max) NOT NULL,
	[job_id] uniqueidentifier NOT NULL,
	[seconds_elapsed_average] float NOT NULL
)

declare @job_error_list table
(
	[server] varchar(max) NOT NULL,
	[job_id] uniqueidentifier NOT NULL,
	[job_name] varchar(max) NOT NULL,
	[run_status] int NOT NULL,
	[run_date] datetime NOT NULL,
	[seconds_elapsed] float NOT NULL,
	[message] varchar(max) NOT NULL,	
	[seconds_elapsed_average] float NOT NULL,
	[error_description] varchar(max) NOT NULL
)

-- load hystory from current server
INSERT INTO @job_hystory
(
	[server], [job_id], [job_name],	[run_status], [run_date], [run_time], 
	[run_duration], [message], [operator_emailed], [operator_netsend], [operator_paged], [retries_attempted]
)
--exec msdb..sp_help_jobhistory
SELECT 
	[server],
	sjh.[job_id],
	sj.[name] AS [job_name],
	[run_status],
	[run_date],
	[run_time],    
    [run_duration],
    [message],
    [operator_id_emailed],
    [operator_id_netsent],
    [operator_id_paged],
    [retries_attempted]
FROM [msdb].[dbo].[sysjobhistory] sjh
LEFT JOIN [msdb].[dbo].[sysjobs] sj
	ON sjh.[job_id] = sj.[job_id] 
WHERE [step_id] = 0

-- load hystory from linked servers
declare @cmd varchar(max)
declare @sid int = 1
while @sid<= (select max(ServerId) from @server_list_table)
begin
	
	set @cmd = 'SELECT 
					[server]
					, sjh.[job_id]
					, sj.[name] AS [job_name]
					, [run_status]
					, [run_date]
					, [run_time]    
					, [run_duration]
					, [message]
					, [operator_id_emailed]
					, [operator_id_netsent]
					, [operator_id_paged]
					, [retries_attempted]
				FROM '+(select ServerName from @server_list_table where ServerId = @sid)+'.[msdb].[dbo].[sysjobhistory] sjh
				LEFT JOIN '+(select ServerName from @server_list_table where ServerId = @sid)+'.[msdb].[dbo].[sysjobs] sj
					ON sjh.[job_id] = sj.[job_id] 
				WHERE [step_id] = 0'
	
	insert into @job_hystory
	exec(@cmd)
	
	set @cmd = 
	'SELECT 
		[server]
		, [JobName]
		, datediff(SECOND, StartDate, getdate()) as running_sec
	FROM
	(
		SELECT 
			@@SERVERNAME as [server]
			, JobName     = sj.job_id
			, StartDate = sja.start_execution_date 
			, EndDate   = sja.stop_execution_date 
			, Status    = CASE  
							WHEN ISNULL(sjh.run_status,-1) = -1 AND sja.start_execution_date IS NULL AND sja.stop_execution_date IS NULL THEN ''Idle''
							WHEN ISNULL(sjh.run_status,-1) = -1 AND sja.start_execution_date IS NOT NULL AND sja.stop_execution_date IS NULL THEN ''Running'' 
							WHEN ISNULL(sjh.run_status,-1) =0  THEN ''Failed'' 
							WHEN ISNULL(sjh.run_status,-1) =1  THEN ''Succeeded'' 
							WHEN ISNULL(sjh.run_status,-1) =2  THEN ''Retry'' 
							WHEN ISNULL(sjh.run_status,-1) =3  THEN ''Canceled'' 
						  END 
		FROM MSDB.DBO.sysjobs sj 
		JOIN MSDB.DBO.sysjobactivity sja 
			ON sj.job_id = sja.job_id  
		JOIN (SELECT MaxSessionid = MAX(Session_id) FROM MSDB.DBO.syssessions) ss 
			ON ss.MaxSessionid = sja.session_id 
		LEFT JOIN MSDB.DBO.sysjobhistory sjh 
			ON sjh.instance_id = sja.job_history_id
	) running_jobs
	where [Status] = ''Running'''

	insert into @job_running
	(
		[server]
		, [job_name]
		, [running_sec]
	)
	exec(@cmd)

	set @sid = @sid+1
end

-- aggregate information
INSERT INTO @job_hystory_small
(
	[server], [job_id], [job_name],	[run_status], [run_date], [seconds_elapsed], [message]
)
SELECT 
	[server],
	[job_id],
	[job_name],
	[run_status],
	DATEADD(SS,
	(([run_time] % 1000000) / 10000) * 3600 +
	(([run_time] % 10000) / 100) * 60 + 
	([run_time] % 100)
	,CONVERT(datetime,(CONVERT(VARCHAR,[run_date])),104)) AS [run_date],
	(([run_duration] % 1000000) / 10000) * 3600 +
	(([run_duration] % 10000) / 100) * 60 + 
	([run_duration] % 100) AS [SECONDS_ELAPSED]
	,[message]
FROM @job_hystory
where job_name <> 'CkeckJobActivity'
GROUP BY
	[job_id],
	[job_name],
	[run_status],
	[run_date],
	[run_time],
	[run_duration],
	[server],
	[message]

-- get average info about working-time of JOB`s.
INSERT INTO @job_exec_time_average	
SELECT
	[server],
	[job_id],
	SUM(CASE [run_status]
			WHEN 1 THEN 1
			ELSE 0
		END	* [seconds_elapsed]) 
	/
	CASE WHEN SUM(CASE [run_status]
			WHEN 1 THEN 1
			ELSE 0
		END) = 0 THEN 0.0000001
	ELSE SUM(CASE [run_status]
			WHEN 1 THEN 1
			ELSE 0
		END)
	END AS [seconds_elapsed_average_weighted]
FROM @job_hystory_small
WHERE 
	DATEDIFF(dd,[run_date],GETDATE()) >= 1
GROUP BY
	[server],
	[job_id]


-- Find Errors and exceptions
INSERT INTO @job_error_list
SELECT 
	jh.*, 
	ISNULL(jt.[seconds_elapsed_average],0), 
	CASE
		WHEN jh.[run_status] = 0 THEN 'There are errors in JOB.'
		WHEN jh.[run_status] = 2 THEN 'One of steps was reruning'
		WHEN jh.[run_status] = 3 THEN 'Job was cancelled'
		WHEN jh.[run_status] = 5 THEN 'Unknown status'
		WHEN jh.[run_status] = 1 AND 
		    jh.[seconds_elapsed] / 
			CASE 
				WHEN ISNULL(jt.[seconds_elapsed_average],0) = 0 THEN 0.0000001 
				ELSE jt.[seconds_elapsed_average] 
			END >= 1.2 and jh.[seconds_elapsed]<> 0 and ISNULL(jt.[seconds_elapsed_average],0) <> 0 and (select isnull(min_execution_time, max_execution_time) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name) is null
			THEN 'Job was working more time then offen'
		WHEN jh.[run_status] = 1 AND 
		   jh.[seconds_elapsed] / 
			CASE 
				WHEN ISNULL(jt.[seconds_elapsed_average],0) = 0 THEN 0.0000001 
				ELSE jt.[seconds_elapsed_average] 
			END <= 0.8  and jh.[seconds_elapsed]<> 0 and ISNULL(jt.[seconds_elapsed_average],0) <> 0 and (select isnull(min_execution_time, max_execution_time) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name) is null
			THEN 'Job was working less time then offen'
		WHEN jh.[run_status] = 1 AND 
		    jh.[seconds_elapsed] not between (select min_execution_time from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name) and (select max_execution_time from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name) 			
			THEN 'greater then Approximate'
		ELSE 'Succesfull'
	END AS [error_description]
FROM @job_hystory_small jh
LEFT JOIN @job_exec_time_average jt
	ON jh.[server] = jt.[server] AND
	   jh.[job_id] = jt.[job_id]
WHERE 
	jh.[run_date] = (SELECT MAX([run_date]) FROM @job_hystory_small t
					 WHERE 
						t.[server] = jh.[server] AND 
						t.[job_id] = jh.[job_id] )
						
insert into @job_error_list
(
	[server],
	[job_name],
	[error_description] 
)
select 
	jh.[server]
	, jh.job_name
	, 'job is running now, but it very long'
from @job_running jh
LEFT JOIN @job_exec_time_average jt
	ON jh.[server] = jt.[server] AND
	   jh.job_name = jt.[job_id]
where jh.running_sec - jt.seconds_elapsed_average < 0

UPDATE @job_error_list
SET [run_status] = 2, [error_description] = 'One of steps was reruning'
FROM @job_error_list el
WHERE EXISTS(SELECT * FROM [msdb].[dbo].[sysjobhistory] sjh 
             WHERE 
				sjh.[server] = el.[server] AND
				sjh.[job_id] = el.[job_id] AND
				(sjh.[run_date] = YEAR(el.[run_date]) * 10000 + MONTH(el.[run_date]) * 100 + DAY(el.[run_date])) AND
				sjh.[run_status] = 2)


select distinct [server], [job_id] 
into #t
from @job_error_list
WHERE run_status in (0, 2)


select 
					[run_date]
					, [message]
					, [server]
					, [job_id]
					, [step_id]
					, [run_status] 
					into #errors
				from [server].[msdb].[dbo].[sysjobhistory] 	
				where [job_id] in (select [job_id] from #t where [server] =  @@servername )

set @sid = 1
while @sid<= (select max(ServerId) from @server_list_table)
begin



	set @cmd = 'select 
					[run_date]
					, [message]
					, [server]
					, [job_id]
					, [step_id]
					, [run_status] 
				from '+(select ServerName from @server_list_table where ServerId = @sid)+'.[msdb].[dbo].[sysjobhistory] 	
				where [job_id] in (select [job_id] from #t where [server] = '''+(select ServerName from @server_list_table where ServerId = @sid)+''' )' 
	insert into #errors
	exec (@cmd)
	
	set @sid = @sid+1
end

SET @MailSubject = N'Status of JOB`s working time.'-- + case when (SELECT COUNT(*) FROM @job_error_list WHERE [run_status] = 0) > 0 then ' Critical errors was finded!'	 else ' Trere are no critical' end



--select * from @job_error_list return



IF (SELECT COUNT(*) FROM @job_error_list) > 0 
BEGIN

if @show_all = 0
begin
	delete from @job_error_list where [run_status] = 1 AND [error_description] like '%succesful%'
end

        SET @html = 
        N'<table border="0" style="margin-left: auto; margin-right: auto; margin-top: 0px; max-width: 800px; padding: 70px 30px 50px 30px; background-color: white;"><tr><td>' +
        N'<table border="0"><tr><td><img src="http://servicedesk:8080/custom/customimages/Custom_HeadLogo.gif?1493304584540" width="200" height="58" style="margin: 7px 7px 7px 0;"></td><td style="padding: 10px 0px 0px 20px;"><h1><font face="Cambria" color="#383484" size="4">JOB`s working time and problems</font></h1></td></tr></table>' +
        N'<h2><font face="Calibri" color="#000000" size="3" style="font-weight: normal;">During the scheduled check of the correctness of the SQL Server Agent service execution, the following deviations were detected:</font></h2>' +
        N'<table border="1" bordercolor="#a6a6a6" cellpadding="0" cellspacing="0" style="font:12pt sans-serif; font-family: Calibri, Arial;">' +
        N'<tr>' +
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Server name</th>' +
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">JOB name</th>' +
                --N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Status</th>' +				
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Begin time</th>' +
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Time elapsed, sec</th>' +
				N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">TimeBenchmark, sec</th>' +
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Average time by 10 last runs, sec</th>' +
				N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Pass Approximate (Y/N)</th>' +
                N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Result</th>' +
				
        N'</tr>' + 
        isnull(replace(replace(CAST(
        (SELECT
                N'<td style="padding: 5px;">' + ISNULL([server], N'') + N'</td>' +
                N'<td style="padding: 5px;">' + ISNULL([job_name], N'') + N'</td>' +
                --N'<td style="padding: 5px;">' + CASE 
                --        WHEN [run_status] = 0 THEN N'With errors'
                --        WHEN [run_status] = 2 THEN N'One of step was reruned'
                --        WHEN [run_status] = 3 THEN N'Cancelled'
                --        WHEN [run_status] = 5 THEN N'Unknown'
                --        ELSE N'With out errors'
                --END + N'</td>' +				
                N'<td style="padding: 5px;">' + ISNULL(CONVERT(nvarchar,[run_date],120), N'') + N'</td>' +
                N'<td style="padding: 5px; text-align: center;">' + ISNULL(CONVERT(nvarchar,round([seconds_elapsed],2)), N'') + N'</td>' +
				N'<td style="padding: 5px; text-align: center;">' + concat((select CONVERT(nvarchar,[min_execution_time]) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name), ' - ', (select CONVERT(nvarchar,[max_execution_time]) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name)) + N'</td>' +
                N'<td style="padding: 5px; text-align: center;">' + ISNULL(CONVERT(nvarchar,round([seconds_elapsed_average],2)), N'') + N'</td>' +
                N'<td style="padding: 5px; text-align: center;">' + case 
																		when [run_status] = 1 AND [error_description] like '%Approximate%' then N'NO' 
																		when [run_status] = 1 AND [error_description] not like '%Approximate%' and concat((select CONVERT(nvarchar,[min_execution_time]) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name), ' - ', (select CONVERT(nvarchar,[max_execution_time]) from [DbAdmin].[dbo].[JOBsExecutionTimeBenchmarks] JE with (nolock) where JE.ServerName = jh.[server] and JE.JobName = jh.job_name)) = N' - ' THEN N'Unknown'																		
																		when [run_status] <> 1 then N'errors'
																		ELSE N'YES' END + N'</td>' +
                CASE 
                        WHEN [run_status] = 0 THEN N'<td style="padding: 5px; color: #ac0c0c;" bgcolor="#fb8484"><b>' + [error_description] + N'</b></td>'
                        WHEN [run_status] = 2 THEN N'<td style="padding: 5px;" bgcolor="#f2f09d">' + [error_description] + N'</td>'
                        WHEN [run_status] = 3 THEN N'<td style="padding: 5px; color: #ac0c0c;" bgcolor="#fb8484"><b>' + [error_description] + N'</b></td>'
                        WHEN [run_status] = 5 THEN N'<td style="padding: 5px; color: #ac0c0c;" bgcolor="#fb8484"><b>' + [error_description] + N'</b></td>'
						WHEN [run_status] = 1 AND [error_description] like '%succesful%' THEN N'<td style="padding: 5px; color: #000000;" bgcolor="#98FB98"><b>' + [error_description] + N'</b></td>'
                        WHEN [run_status] = 1 AND [error_description] like '%less%' THEN N'<td style="padding: 5px;" bgcolor="#f2f09d">' + [error_description] + N'</td>'
                        WHEN [run_status] = 1 AND [error_description] like '%error%' THEN N'<td style="padding: 5px;" bgcolor="#b7f29d">' + [error_description] + N'</td>'		
						WHEN [run_status] = 1 AND [error_description] like '%Approximate%' THEN N'<td style="padding: 5px;" bgcolor="#B0E0E6">' + [error_description] + N'</td>'					
                        WHEN [run_status] = 1 AND [error_description] like '%more%' THEN N'<td style="padding: 5px; color: #000000;" bgcolor="#FFDAB9"><b>' + [error_description] + N'</b></td>'
                END 
				
        FROM @job_error_list jh
        WHERE [run_status] <> 4
		and not exists (
				select top 1 1 from [DbAdmin].[dbo].[JOBsExecutionCheckLog] t (nolock) where t.[ServerName] = jh.[server] and t.[JobName] = jh.job_name and t.[run_date] = jh.[run_date]
				)
		
        FOR XML PATH('tr'), TYPE)
        AS NVARCHAR(MAX)), '&gt;', '>'), '&lt;', '<'), N'') +
        N'</table>'
        
		

		if exists( select top 1 1  
		FROM @job_error_list el
                LEFT JOIN #errors sjh ON
                        el.[server] = sjh.[server] AND
                        el.[job_id] = sjh.[job_id] AND
                        YEAR(el.[run_date]) * 10000 + MONTH(el.[run_date]) * 100 + DAY(el.[run_date]) = sjh.[run_date]
                WHERE 
                        el.[run_status] = 0 AND
                        sjh.[run_status] = 0 AND
                        sjh.[step_id] > 0
				and not exists (
						select top 1 1 from [DbAdmin].[dbo].[JOBsExecutionCheckLog] t (nolock) where t.[ServerName] = el.[server] and t.[JobName] = el.job_name and t.[run_date] = el.[run_date]
						)
					)
		begin

			IF (SELECT COUNT(*) FROM @job_error_list WHERE [run_status] = 0) > 0
			BEGIN

					SET @Importance = 'High'
                
					SET @html += 
					N'<h2><font face="Calibri" color="#000000" size="3" style="font-weight: normal;">Text of critical errors:</font></h2>' +
					N'<table border="1" bordercolor="#a6a6a6" cellpadding="0" cellspacing="0" style="font:12pt sans-serif; max-width: 800px; font-family: Calibri, Arial;">' +
					N'<tr>' +
							N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Server Name</th>' +
							N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">JOB name</th>' +
							N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Error text</th>' +
							N'<th bgcolor="#f1f1f1" style="padding: 5px; font-weight: normal;">Error text from last step</th>' +
					N'</tr>' + 
					isnull(replace(replace(CAST(
					(SELECT
							N'<td style="padding: 5px;">' + ISNULL(el.[server], N'') + N'</td>' +
							N'<td style="padding: 5px;">' + ISNULL(el.[job_name], N'') + N'</td>' + 
							N'<td style="padding: 5px;">' + ISNULL(el.[message], N'') + N'</td>' +
							N'<td style="padding: 5px;">' + ISNULL(sjh.[message], N'') + N'</td>' 
					FROM @job_error_list el
					LEFT JOIN #errors sjh ON
							el.[server] = sjh.[server] AND
							el.[job_id] = sjh.[job_id] AND
							YEAR(el.[run_date]) * 10000 + MONTH(el.[run_date]) * 100 + DAY(el.[run_date]) = sjh.[run_date]
					WHERE 
							el.[run_status] = 0 AND
							sjh.[run_status] = 0 AND
							sjh.[step_id] > 0
					and not exists (
							select top 1 1 from [DbAdmin].[dbo].[JOBsExecutionCheckLog] t (nolock) where t.[ServerName] = el.[server] and t.[JobName] = el.job_name and t.[run_date] = el.[run_date]
							)
					FOR XML PATH('tr'), TYPE)
					AS NVARCHAR(MAX)), '&gt;', '>'), '&lt;', '<'), N'') +
					N'</table>'
			END
		end
        SET @html += N'<hr color="#e9e9e9" style="margin-top: 40px;"/>' +
                     N'<table border="0"><tr><td><font face="Calibri" color="#000000" size="3" style="font-weight: normal;">Contact email: InfrastructureDBA@travelrepublic.co.uk</font></td></tr>' +
                     N'<tr><td><font face="Calibri" color="#000000" size="3" style="font-weight: normal;">Telephone: +7 (911) 144-56-65  (Vladimir)</font></td></tr></table>' +
                     N'</td></tr></table>'
END
ELSE BEGIN
	RETURN
END     

DECLARE @MyTableVar TABLE  
(  
	[ServerName] varchar(255)
	, [JobName] varchar(512)
	, [run_date] datetime
	, [EmailSendTime] datetime
); 

		insert into [DbAdmin].[dbo].[JOBsExecutionCheckLog]

		(
			[ServerName]
			, [JobName]
			, [run_date]
			, [EmailSendTime]
		)
		output inserted.* into @MyTableVar	
		select 
			jh.[server]
			, jh.job_name
			, jh.run_date
			, getdate()

        FROM @job_error_list jh


        WHERE [run_status] <> 4
		and not exists (
						select top 1 1 from [DbAdmin].[dbo].[JOBsExecutionCheckLog] t (nolock) where t.[ServerName] = jh.[server] and t.[JobName] = jh.job_name and t.[run_date] = jh.[run_date]
						)
		


IF @profile_name1 = '' SET @profile_name1 = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile)

if exists (
			select top 1 1 from @MyTableVar
		  )
begin

	EXEC msdb..sp_send_dbmail
		@recipients = @recipients,
		@copy_recipients = @copy_recipients,
		@subject = @MailSubject,
		@body = @html,
		@body_format = 'HTML',
		@profile_name = @profile_name1,
		@importance = @Importance

		print 'mail was send!'
end
