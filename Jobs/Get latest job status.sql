DECLARE @job_id UNIQUEIDENTIFIER 
            ,@job_name  VARCHAR(256)
			,@statusjob VARCHAR(32)

    SET @job_id = 'BFA5BC77-3098-471E-9003-5AD687825EF2'
    SET @job_name = 'syspolicy_purge_history'


    --search for job_id if none was provided
    SELECT  @job_id = COALESCE(@job_id,job_id)
    FROM    msdb.dbo.sysjobs 
    WHERE   name = @job_name

  ;WITH cte AS
  (
			 SELECT  t2.instance_id
            ,t1.name as JobName
            ,t2.step_id as StepID
            ,t2.step_name as StepName
            ,CONVERT(CHAR(10), CAST(STR(t2.run_date,8, 0) AS DATETIME), 111) as RunDate
            ,STUFF(STUFF(RIGHT('000000' + CAST ( t2.run_time AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') as RunTime
            ,t2.run_duration
            ,CASE t2.run_status WHEN 0 THEN 'Failed'
                                WHEN 1 THEN 'Succeeded' 
                                WHEN 2 THEN 'Retry' 
                                WHEN 3 THEN 'Cancelled' 
                                WHEN 4 THEN 'In Progress' 
                                END as ExecutionStatus
            ,t2.message as MessageGenerated    
    FROM    msdb.dbo.sysjobs t1
    JOIN    msdb.dbo.sysjobhistory t2
            ON t1.job_id = t2.job_id   
            --Join to pull most recent job activity per job, not job step
    JOIN    (
            SELECT  TOP 1
                    t1.job_id
                    ,t1.start_execution_date
                    ,t1.stop_execution_date
            FROM    msdb.dbo.sysjobactivity t1
            --If no job_id detected, return last run job
            WHERE   t1.job_id = COALESCE(@job_id,t1.job_id)
            ORDER 
            BY      last_executed_step_date DESC
            ) t3
            --Filter on the most recent job_id
            ON t1.job_id = t3.job_Id
            --Filter out job steps that do not fall between start_execution_date and stop_execution_date
            AND CONVERT(DATETIME, CONVERT(CHAR(8), t2.run_date, 112) + ' ' 
            + STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), t2.run_time), 6), 5, 0, ':'), 3, 0, ':'), 121)  
            BETWEEN t3.start_execution_date AND t3.stop_execution_date
	) 
	SELECT @statusjob = (SELECT TOP 1 ExecutionStatus FROM  cte ORDER BY 1 DESC)

	IF @statusjob != 'Succeeded'
	BEGIN 
		EXEC msdb.dbo.sp_attach_schedule @job_id=N'bfa5bc77-3098-471e-9003-5ad687825ef2',@schedule_id=71
	END 
	ELSE 
	BEGIN 
		EXEC msdb.dbo.sp_detach_schedule @job_id=N'bfa5bc77-3098-471e-9003-5ad687825ef2',@schedule_id=71
	END
