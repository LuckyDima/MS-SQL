CREATE OR ALTER PROCEDURE dbo.CheckIFI
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	EXEC sys.sp_configure 'show advanced options', 1;
	RECONFIGURE;

	EXEC sys.sp_configure 'xp_cmdshell', 1;
	RECONFIGURE;

	DROP TABLE IF EXISTS #priv;
	CREATE TABLE #priv (output NVARCHAR(4000));
	INSERT INTO #priv
	EXEC sys.xp_cmdshell 'whoami /priv';

	IF EXISTS (SELECT * FROM #priv WHERE output LIKE '%SeManageVolumePrivilege%')
		SELECT 'Instant File Initialization enable';
	ELSE
		SELECT 'Instant File Initialization disable or unknown';

	EXEC sys.sp_configure 'xp_cmdshell', 0;
	RECONFIGURE;

	EXEC sys.sp_configure 'show advanced options', 0;
	RECONFIGURE;
END;
