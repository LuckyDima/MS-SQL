

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
--      Author:	Md. Marufuzzaman.
-- Create date: 
-- Description:	Get the content from files. 
-- =============================================
-- EXEC [dbo].[spGetText] @Path = 'C:\MyTextFile.txt'

CREATE PROCEDURE [dbo].[spGetText] 
(
	@Path	VARCHAR(500)
)
AS
BEGIN
 
DECLARE @Command VARCHAR(255)
SELECT @Path = ISNULL(@Path,'C:\Windows\System32\license.rtf') 
PRINT 'Path: ' + @Path
 
CREATE TABLE #Xml(dataRow VARCHAR(MAX))
	IF @Path IS NOT NULL AND LEN(@Path) > 10
		BEGIN
			SELECT @Command = 'type ' + @Path
			INSERT INTO [dbo].[#Xml] 
					EXEC master.dbo.xp_cmdshell @Command
		END
	IF @@ROWCOUNT <> 0
		BEGIN
			SELECT * FROM [dbo].[#Xml]
		END
			
DROP TABLE #Xml
 
END
GO
