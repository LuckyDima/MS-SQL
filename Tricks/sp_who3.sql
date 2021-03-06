CREATE PROCEDURE [dbo].[sp_who3]
@SPID INT = NULL,
@DBName VARCHAR(255) = NULL,
@running BIT = NULL,
@blocked BIT = NULL,
@eventinfo VARCHAR(100) = NULL
AS

SET NOCOUNT ON

DECLARE @iSPID int

CREATE TABLE #spwho (
 SPID int NOT NULL
, Status varchar (255) NOT NULL
, Login varchar (255) NOT NULL
, HostName varchar (255) NOT NULL
, BlkBy varchar(10) NOT NULL
, DBName varchar (255) null
, Command varchar (255) NOT NULL
, CPUTime int NOT NULL
, DiskIO int NOT NULL
, LastBatch varchar (255) NOT NULL
, ProgramName varchar (255) null
, SPID2 int NOT NULL
, REQUESTID int NOT NULL
)

CREATE TABLE #dbcc (
SPID int,
EventType varchar(255),
Paramters int,
EventInfo varchar(8000)
)

INSERT #spwho
EXEC sp_who2

DECLARE buf CURSOR FAST_FORWARD FOR
SELECT SPID FROM #spwho

OPEN buf

FETCH NEXT FROM buf
INTO @iSPID

WHILE @@FETCH_STATUS = 0
BEGIN

DECLARE @s_spid VARCHAR(10)
SET @s_spid = CAST(@iSPID AS varchar(10))

DECLARE @dbcctab TABLE (
EventType varchar(255),
Paramters int,
EventInfo varchar(8000)
)

INSERT @dbcctab
EXEC ('dbcc inputbuffer(' + @s_spid + ') WITH NO_INFOMSGS')

INSERT #dbcc
SELECT @iSPID, * FROM @dbcctab

DELETE FROM @dbcctab

FETCH NEXT FROM buf
INTO @iSPID

END

CLOSE buf
DEALLOCATE buf

SET NOCOUNT OFF

SELECT
s.SPID,
d.EventInfo,
s.Status,
s.Login,
s.HostName,
s.BlkBy,
s.DBName,
s.Command,
s.CPUTime,
s.DiskIO,
s.LastBatch,
s.ProgramName,
s.REQUESTID
FROM
#spwho s

LEFT JOIN #dbcc d ON
s.SPID = d.SPID
WHERE
(@SPID IS NULL OR s.SPID = @SPID)
AND (@blocked IS NULL OR (@blocked = 1 AND LTRIM(RTRIM(s.BlkBy)) != '.') OR (@blocked = 0 AND LTRIM(RTRIM(s.BlkBy)) = '.'))
AND (@running IS NULL OR (@running = 1 AND s.Status != 'sleeping') OR (@running = 0 AND s.Status = 'sleeping'))
AND (@DBName IS NULL OR s.DBName = @DBName)
AND (@eventinfo IS NULL OR d.EventInfo LIKE @eventinfo)
ORDER BY
LastBatch DESC
