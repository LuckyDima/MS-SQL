DECLARE @JobName varchar(max)
SELECT @JobName = [name]

FROM msdb.dbo.sysjobs
WHERE job_id = cast(0x3BC80A1532DECB40A26E3DB919F97900 AS uniqueidentifier)

EXECUTE msdb..sp_help_job @job_name = @JobName

EXECUTE msdb..sp_help_jobstep @job_name = @JobName