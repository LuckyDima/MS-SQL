
DECLARE @alertName NVARCHAR(200);
DECLARE @dbName NVARCHAR(128);
SET @dbName = 'InfoFlowServices';
-- Create [DBM Perf: Mirror Commit Overhead Threshold (<dbname>]
SET @alertName='Mirror Commit Overhead Threshold' + ' (' + @dbName + ')';
EXEC msdb.dbo.sp_add_alert 
   @name=@alertName, 
   --@category_name=N'Database Mirroring',
   @database_name = @dbName,
   @message_id=32044, 
   @severity=0, 
   @delay_between_responses=1800, 
   @include_event_description_in=0,
   @enabled=0;
   
   -- Create [DBM Perf: Unrestored Log Threshold (<dbname>]

SET @alertName='Mirror Unrestored Log Threshold' + ' (' + @dbName + ')';
EXEC msdb.dbo.sp_add_alert 
   @name=@alertName, 
   --@category_name=N'Database Mirroring',
   @database_name = @dbName,
   @message_id=32043, 
   @severity=0, 
   @delay_between_responses=1800, 
   @include_event_description_in=0,
   @enabled=0;
   
   -- Create [DBM Perf: Unsent Log Threshold (<dbname>]
   
SET @alertName='Mirror Unsent Log Threshold' + ' (' + @dbName + ')';
EXEC msdb.dbo.sp_add_alert 
   @name=@alertName, 
   --@category_name=N'Database Mirroring',
   @database_name = @dbName,
   @message_id=32042, 
   @severity=0, 
   @delay_between_responses=1800, 
   @include_event_description_in=0,
   @enabled=0;

-- Create [DBM Perf: Oldest Unsent Transaction Threshold (<dbname>]

SET @alertName='Mirror Oldest Unsent Transaction Threshold' + ' (' + @dbName + ')';
EXEC msdb.dbo.sp_add_alert 
   @name=@alertName, 
   --@category_name=N'Database Mirroring',
   @database_name = @dbName,
   @message_id=32040, 
   @severity=0, 
   @delay_between_responses=1800, 
   @include_event_description_in=0,
   @enabled=0;

