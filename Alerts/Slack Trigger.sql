
CREATE OR ALTER TRIGGER [dbo].[ErrorAlertToSlackChannel] 
ON [dbo].[CommandLog]
AFTER UPDATE 
AS 
DECLARE @ErrorNumber INT = (SELECT ISNULL(ErrorNumber,50001) FROM INSERTED)
IF @ErrorNumber <> 0
BEGIN
	DECLARE 
		@OutStatus VARCHAR(MAX),
		@OutResponse VARCHAR(MAX),
		@Error VARCHAR(MAX), 
		@DBName VARCHAR(MAX),
		@CommandType VARCHAR(MAX);

	SELECT 
		@CommandType = ISNULL(CommandType,'N/A'),
		@DBName = ISNULL(DatabaseName,'N/A') 
	FROM INSERTED;
	
	SET @Error = '{"text":" DBName: ' + @DBName + CHAR(10) + 'Error number: ' + CAST(@ErrorNumber AS VARCHAR(8)) + CHAR(10) + 'Command: ' + @CommandType + '"}' 
	IF @Error IS NOT NULL
	EXEC dbo.spx_make_api_request 'POST','',@Error,'https://hooks.slack.com/services/<blablabla>'
	,@OutStatus OUTPUT,@OutResponse OUTPUT 
	--SELECT @OutStatus RersposeStatus, @OutResponse RersposeCode 
END
GO

ALTER TABLE [dbo].[CommandLog] ENABLE TRIGGER [ErrorAlertToSlackChannel]
GO


