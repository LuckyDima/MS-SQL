--Create table
USE [master]
GO
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_ClusterFailoverMonitor_Date]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[ClusterFailoverMonitor] DROP CONSTRAINT [DF_ClusterFailoverMonitor_Date]
END

GO
USE [master]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ClusterFailoverMonitor]') AND type in (N'U'))
DROP TABLE [dbo].[ClusterFailoverMonitor]
GO

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClusterFailoverMonitor](
	[Previous_Active_Node] [varchar](30) NULL,
	[Current_Active_Node] [varchar](30) NULL,
	[Date] [datetime2](7) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[ClusterFailoverMonitor] ADD  CONSTRAINT [DF_ClusterFailoverMonitor_Date]  DEFAULT (getdate()) FOR [Date]
GO

--if table is null then insert values active node
DECLARE @var1 VARCHAR(30), @var11 VARCHAR(30), @var2 VARCHAR(30)
CREATE TABLE #PhysicalHostName ([Value]  VARCHAR(30), [Current_Active_Node] VARCHAR(30))
INSERT INTO #PhysicalHostName
EXEC master..xp_regread 'HKEY_LOCAL_Machine',
'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\',
'ComputerName'
SELECT @var1= [Previous_Active_Node] FROM dbo.ClusterFailoverMonitor
SELECT @var11= [Current_Active_Node] FROM dbo.ClusterFailoverMonitor
SELECT @var2= [Current_Active_Node] FROM #PhysicalHostName
IF @var1 IS NULL AND @var11 IS NULL
BEGIN
INSERT INTO dbo.ClusterFailoverMonitor ([Previous_Active_Node],[Current_Active_Node]) VALUES (@var2,@var2)
END
DROP TABLE #PhysicalHostName



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.Check_Failover
AS
BEGIN

	SET NOCOUNT ON;

DECLARE @var1 VARCHAR(30), @var2 VARCHAR(30)
CREATE TABLE #PhysicalHostName ([Value]  VARCHAR(30), [Current_Active_Node] VARCHAR(30))
INSERT INTO #PhysicalHostName
EXEC master..xp_regread 'HKEY_LOCAL_Machine',
'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\',
'ComputerName'

SELECT @var1= [Previous_Active_Node] FROM dbo.ClusterFailoverMonitor
SELECT @var2= [Current_Active_Node] FROM #PhysicalHostName

IF @var1<>@var2
	BEGIN
		EXEC msdb..sp_send_dbmail @profile_name='Planet3',
		@recipients='idimas@i-free.com',
		@subject=' Failover occurrence notification - SQLExample',
		@body='Cluster failover has occured for instance SQLExample. Below given are the previous and current active nodes.',
		@QUERY='SET NOCOUNT ON; SELECT [Current_Active_Node] FROM #PhysicalHostName; SELECT [Previous_Active_Node],[Date] FROM [dbo].[ClusterFailoverMonitor]; SET NOCOUNT OFF'
		UPDATE dbo.ClusterFailoverMonitor SET [Previous_Active_Node] = @var2
		UPDATE dbo.ClusterFailoverMonitor SET [Current_Active_Node] = @var2
	END
DROP TABLE #PhysicalHostName	

END
GO
