CREATE OR ALTER PROCEDURE [policy].[FixDbSettings]
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS(SELECT * FROM dbo.Check_Policies WHERE name = 'Check database settings')
BEGIN
	EXEC master.sys.sp_MSforeachdb @command1 = '
SET QUOTED_IDENTIFIER ON;
USE [?]
IF DB_ID(''?'') > 4
AND EXISTS
(
SELECT D.name
FROM master.sys.databases D
JOIN DBA.dbo.Check_Policies P ON D.name = REPLACE(P.target_query_expression, ''SQLSERVER:\SQL\<ServerName>\DEFAULT\Databases\'', '''')
	AND D.state = 0 AND D.database_id > 4
	AND P.name = ''Check database settings''
	AND (D.delayed_durability < 1 OR D.compatibility_level <> 150 OR D.page_verify_option <> 2 OR D.is_auto_create_stats_incremental_on <> 1 OR D.is_auto_update_stats_async_on <> 1
		  OR D.is_auto_create_stats_on <> 1 OR D.is_auto_update_stats_on <> 1 OR D.is_broker_enabled <> 0)
  )
BEGIN
SET QUOTED_IDENTIFIER OFF;
IF (SELECT value from sys.database_scoped_configurations WHERE name = ''PARAMETER_SNIFFING'') <> 1
	ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
IF (SELECT delayed_durability from sys.databases WHERE name = ''?'') <> 1
	ALTER DATABASE [?] SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT;
IF (SELECT compatibility_level from sys.databases WHERE name = ''?'') <> 150
	ALTER DATABASE [?] SET COMPATIBILITY_LEVEL = 150;
IF (SELECT page_verify_option from sys.databases WHERE name = ''?'') <> 2
	ALTER DATABASE [?] SET PAGE_VERIFY CHECKSUM WITH NO_WAIT;
IF (SELECT is_auto_create_stats_incremental_on from sys.databases WHERE name = ''?'') <> 1
	ALTER DATABASE [?] SET AUTO_CREATE_STATISTICS ON (INCREMENTAL = ON) WITH ROLLBACK IMMEDIATE;
IF (SELECT is_auto_update_stats_async_on from sys.databases WHERE name = ''?'') <> 1
	ALTER DATABASE [?] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;
IF (SELECT is_auto_create_stats_on from sys.databases WHERE name = ''?'') <> 1
	ALTER DATABASE [?] SET AUTO_CREATE_STATISTICS ON;
IF (SELECT is_auto_update_stats_on from sys.databases WHERE name = ''?'') <> 1
	ALTER DATABASE [?] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT;
IF (SELECT is_broker_enabled from sys.databases WHERE name = ''?'') <> 0
	ALTER DATABASE [?] SET DISABLE_BROKER WITH ROLLBACK IMMEDIATE;
END;'
END;
END;
