
SET NOCOUNT ON;
DECLARE @LinkName NVARCHAR (128), @retval INT
IF (SELECT COUNT (srvname) FROM sys.sysservers WHERE srvname <> @@SERVERNAME) = 0 RETURN

DECLARE srvname INSENSITIVE CURSOR FOR 
		(SELECT srvname FROM sys.sysservers WHERE srvname <> @@SERVERNAME) FOR READ ONLY
OPEN srvname
	FETCH NEXT FROM srvname INTO @LinkName
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		EXEC @retval = sys.sp_testlinkedserver @LinkName
	END TRY
	
	BEGIN CATCH
		IF @LinkName IS NULL RETURN
		SET @retval = SIGN(@@ERROR)
		IF @retval <> 0 
		RAISERROR ('Unable to connect to server. This operation will be tried later!', 16, 2 )
	END CATCH
	FETCH NEXT FROM srvname INTO @LinkName
	
END	
	
	CLOSE srvname
	DEALLOCATE srvname