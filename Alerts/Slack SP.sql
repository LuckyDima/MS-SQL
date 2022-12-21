
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROC [dbo].[spx_make_api_request]
(
    @RType VARCHAR(MAX),
    @AuthHeader VARCHAR(MAX),
    @RPayLoad VARCHAR(MAX),
    @URL VARCHAR(MAX),
    @OutStatus VARCHAR(MAX) OUTPUT,
    @OutResponse VARCHAR(MAX) OUTPUT
)
AS
DECLARE @contentType NVARCHAR(64);
DECLARE @postData NVARCHAR(2000);
DECLARE @responseText NVARCHAR(2000);
DECLARE @responseXML NVARCHAR(2000);
DECLARE @ret INT;
DECLARE @status NVARCHAR(32);
DECLARE @statusText NVARCHAR(32);
DECLARE @token INT;
SET @contentType = N'application/json';
-- Open the connection.
EXEC @ret = sp_OACreate 'MSXML2.ServerXMLHTTP', @token OUT;
IF @ret <> 0
    RAISERROR('Unable to open HTTP connection.', 10, 1);
-- Send the request.
EXEC @ret = sp_OAMethod @token, 'open', NULL, @RType, @URL, 'false';
EXEC @ret = sp_OAMethod @token,
                        'setRequestHeader',
                        NULL,
                        'Authentication',
                        @authHeader;
EXEC @ret = sp_OAMethod @token,
                        'setRequestHeader',
                        NULL,
                        'Content-type',
                        'application/json';
SET @RPayLoad =
(
    SELECT CASE WHEN @RTYPE = 'Get' THEN NULL ELSE @RPayLoad END
);
EXEC @ret = sp_OAMethod @token, 'send', NULL, @RPayLoad; -- IF YOUR POSTING, CHANGE THE LAST NULL TO @postData
-- Handle the response.
EXEC @ret = sp_OAGetProperty @token, 'status', @status OUT;
EXEC @ret = sp_OAGetProperty @token, 'statusText', @statusText OUT;
EXEC @ret = sp_OAGetProperty @token, 'responseText', @responseText OUT;
-- Show the response.
PRINT 'Status: ' + @status + ' (' + @statusText + ')';
PRINT 'Response text: ' + @responseText;
SET @OutStatus = 'Status: ' + @status + ' (' + @statusText + ')';
SET @OutResponse = 'Response text: ' + @responseText;
-- Close the connection.
EXEC @ret = sp_OADestroy @token;
IF @ret <> 0
    RAISERROR('Unable to close HTTP connection.', 10, 1);
