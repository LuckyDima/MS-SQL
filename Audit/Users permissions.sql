USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspGetPermissionsOfAllLogins_DBsOnColumns]
AS
SET NOCOUNT ON
;
BEGIN TRY
    IF EXISTS
    (
        SELECT * FROM tempdb.dbo.sysobjects
        WHERE id = object_id(N'[tempdb].dbo.[#permission]')
    )
    DROP TABLE #permission
    ;
    IF EXISTS
    (
        SELECT * FROM tempdb.dbo.sysobjects
        WHERE id = object_id(N'[tempdb].dbo.[#userroles_kk]')
    )
    DROP TABLE #userroles_kk
    ;
    IF EXISTS
    (
        SELECT * FROM tempdb.dbo.sysobjects
        WHERE id = object_id(N'[tempdb].dbo.[#rolemember_kk]')
    )
    DROP TABLE #rolemember_kk
    ;
    IF EXISTS
    (
        SELECT * FROM tempdb.dbo.sysobjects
        WHERE id = object_id(N'[tempdb].dbo.[##db_name]')
    )
    DROP TABLE ##db_name
    ;
    DECLARE
    @db_name VARCHAR(255)
    ,@sql_text VARCHAR(MAX) 
    ;
    SET @sql_text =
    'CREATE TABLE ##db_name
    (
        LoginUserName VARCHAR(MAX)
        ,' 
    ;
    DECLARE cursDBs CURSOR FOR 
        SELECT [name]
        FROM sys.databases
        ORDER BY [name]
    ;
    OPEN cursDBs 
    ;
    FETCH NEXT FROM cursDBs INTO @db_name 
    WHILE @@FETCH_STATUS = 0 
        BEGIN 
                SET @sql_text =
        @sql_text + QUOTENAME(@db_name) + ' VARCHAR(MAX)
        ,' 
                FETCH NEXT FROM cursDBs INTO @db_name 
        END 
    CLOSE cursDBs 
    ;
    SET @sql_text =
        @sql_text + 'IsSysAdminLogin CHAR(1)
        ,IsEmptyRow CHAR(1)
    )' 

    --PRINT @sql_text
    EXEC (@sql_text)
    ;
    DEALLOCATE cursDBs 
    ;
    DECLARE
    @RoleName VARCHAR(255) 
    ,@UserName VARCHAR(255) 
    ;
    CREATE TABLE #permission 
    (
     LoginUserName VARCHAR(255)
     ,databasename VARCHAR(255)
     ,[role] VARCHAR(255)
    ) 
    ;
    DECLARE cursSysSrvPrinName CURSOR FOR 
        SELECT [name]
        FROM sys.server_principals 
        WHERE
        [type] IN ( 'S', 'U', 'G' )
        AND principal_id > 4
        AND [name] NOT LIKE '##%'
		AND [name] NOT IN
		(
'transportuser'
,'ssmoltis'
,'rlobashov'
,'ReplUser'
,'OKTOGO\sqlrepl'
,'OKTOGO\sqlrepl'

		
		)
        ORDER BY [name]
    ;
    OPEN cursSysSrvPrinName
    ;
    FETCH NEXT FROM cursSysSrvPrinName INTO @UserName 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        CREATE TABLE #userroles_kk 
        ( 
             databasename VARCHAR(255)
             ,[role] VARCHAR(255)
        ) 
        ;
        CREATE TABLE #rolemember_kk 
        ( 
             dbrole VARCHAR(255)
             ,membername VARCHAR(255)
             ,membersid VARBINARY(2048)
        ) 
        ;
        DECLARE cursDatabases CURSOR FAST_FORWARD LOCAL FOR
        SELECT [name]
        FROM sys.databases
        ORDER BY [name]
        ;
        OPEN cursDatabases
        ;
        DECLARE 
        @DBN VARCHAR(255)
        ,@sqlText NVARCHAR(4000)
        ;
        FETCH NEXT FROM cursDatabases INTO @DBN
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sqlText =
    N'USE ' + QUOTENAME(@DBN) + ';
    TRUNCATE TABLE #RoleMember_kk 
    INSERT INTO #RoleMember_kk 
    EXEC sp_helprolemember 
    INSERT INTO #UserRoles_kk
    (DatabaseName,[Role])
    SELECT db_name(),dbRole
    FROM #RoleMember_kk
    WHERE MemberName = ''' + @UserName + '''
    '

            --PRINT @sqlText ;
            EXEC sp_executesql @sqlText ;
        FETCH NEXT FROM cursDatabases INTO @DBN
        END
        CLOSE cursDatabases
        ;
        DEALLOCATE cursDatabases
        ;
        INSERT INTO #permission 
        SELECT
        @UserName 'user'
        ,b.name
        ,u.[role]
        FROM
        sys.sysdatabases b
        LEFT JOIN
        #userroles_kk u 
            ON QUOTENAME(u.databasename) = QUOTENAME(b.name)
        ORDER  BY 1 
        ;
        DROP TABLE #userroles_kk
        ; 
        DROP TABLE #rolemember_kk
        ;
        FETCH NEXT FROM cursSysSrvPrinName INTO @UserName 
    END 
    CLOSE cursSysSrvPrinName 
    ;
    DEALLOCATE cursSysSrvPrinName 
    ;
    TRUNCATE TABLE ##db_name 
    ;
    DECLARE
    @d1 VARCHAR(MAX)
    ,@d2 VARCHAR(MAX)
    ,@d3 VARCHAR(MAX)
    ,@ss VARCHAR(MAX)
    ;
    DECLARE cursPermisTable CURSOR FOR
        SELECT * FROM #permission 
        ORDER BY 2 DESC 
    ;
    OPEN cursPermisTable
    ;
    FETCH NEXT FROM cursPermisTable INTO @d1,@d2,@d3
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        IF NOT EXISTS
        (
            SELECT 1 FROM ##db_name WHERE LoginUserName = @d1
        )
        BEGIN 
            SET @ss =
            'INSERT INTO ##db_name(LoginUserName) VALUES (''' + @d1 + ''')' 
            EXEC (@ss) 
            ;
            SET @ss =
            'UPDATE ##db_name SET ' + @d2 + ' = ''' + @d3 + ''' WHERE LoginUserName = ''' + @d1 + '''' 
            EXEC (@ss)
            ;
        END 
        ELSE 
        BEGIN 
            DECLARE
            @var NVARCHAR(MAX)
            ,@ParmDefinition NVARCHAR(MAX)
            ,@var1 NVARCHAR(MAX)
            ;
            SET @var =
            N'SELECT @var1 = ' + QUOTENAME(@d2) + ' FROM ##db_name WHERE LoginUserName = ''' + @d1 + ''''
            ; 
            SET @ParmDefinition =
            N'@var1 NVARCHAR(600) OUTPUT '
            ; 
            EXECUTE Sp_executesql @var,@ParmDefinition,@var1 = @var1 OUTPUT
            ;
            SET @var1 =
            ISNULL(@var1, ' ')
            ;
            SET @var =
            '  UPDATE ##db_name SET ' + @d2 + '=''' + @var1 + ' ' + @d3 + ''' WHERE LoginUserName = ''' + @d1 + '''  '
            ;
            EXEC (@var)
            ;
        END
        FETCH NEXT FROM cursPermisTable INTO @d1,@d2,@d3
    END 
    CLOSE cursPermisTable
    ;
    DEALLOCATE cursPermisTable 
    ;
    UPDATE ##db_name SET
    IsSysAdminLogin = 'Y'
    FROM
    ##db_name TT
    INNER JOIN
    dbo.syslogins SL
        ON TT.LoginUserName = SL.[name]
    WHERE
    SL.sysadmin = 1
    ;
    DECLARE cursDNamesAsColumns CURSOR FAST_FORWARD LOCAL FOR
    SELECT [name]
    FROM tempdb.sys.columns
    WHERE
    OBJECT_ID = OBJECT_ID('tempdb..##db_name')
    AND [name] NOT IN ('LoginUserName','IsEmptyRow')
    ORDER BY [name]
    ;
    OPEN cursDNamesAsColumns
    ;
    DECLARE 
    @ColN VARCHAR(255)
    ,@tSQLText NVARCHAR(4000)
    ;
    FETCH NEXT FROM cursDNamesAsColumns INTO @ColN
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @tSQLText =
N'UPDATE ##db_name SET
IsEmptyRow = ''N''
WHERE IsEmptyRow IS NULL
AND ' + QUOTENAME(@ColN) + ' IS NOT NULL
;
'

        --PRINT @tSQLText ;
        EXEC sp_executesql @tSQLText ;
    FETCH NEXT FROM cursDNamesAsColumns INTO @ColN
    END
    CLOSE cursDNamesAsColumns
    ;
    DEALLOCATE cursDNamesAsColumns
    ;
    UPDATE ##db_name SET
    IsEmptyRow = 'Y'
    WHERE IsEmptyRow IS NULL
    ;
    UPDATE ##db_name SET
    IsSysAdminLogin = 'N'
    FROM
    ##db_name TT
    INNER JOIN
    dbo.syslogins SL
        ON TT.LoginUserName = SL.[name]
    WHERE
    SL.sysadmin = 0
    ;
    SELECT * FROM ##db_name
    ;
    DROP TABLE ##db_name
    ;
    DROP TABLE #permission
    ;
END TRY
BEGIN CATCH
    DECLARE
    @cursDBs_Status INT
    ,@cursSysSrvPrinName_Status INT
    ,@cursDatabases_Status INT
    ,@cursPermisTable_Status INT
    ,@cursDNamesAsColumns_Status INT
    ;
    SELECT
    @cursDBs_Status = CURSOR_STATUS('GLOBAL','cursDBs')
    ,@cursSysSrvPrinName_Status = CURSOR_STATUS('GLOBAL','cursSysSrvPrinName')
    ,@cursDatabases_Status = CURSOR_STATUS('GLOBAL','cursDatabases')
    ,@cursPermisTable_Status = CURSOR_STATUS('GLOBAL','cursPermisTable')
    ,@cursDNamesAsColumns_Status = CURSOR_STATUS('GLOBAL','cursPermisTable')
    ;
    IF @cursDBs_Status > -2
        BEGIN
            CLOSE cursDBs ;
            DEALLOCATE cursDBs ;
        END
    IF @cursSysSrvPrinName_Status > -2
        BEGIN
            CLOSE cursSysSrvPrinName ;
            DEALLOCATE cursSysSrvPrinName ;
        END
    IF @cursDatabases_Status > -2
        BEGIN
            CLOSE cursDatabases ;
            DEALLOCATE cursDatabases ;
        END
    IF @cursPermisTable_Status > -2
        BEGIN
            CLOSE cursPermisTable ;
            DEALLOCATE cursPermisTable ;
        END
    IF @cursDNamesAsColumns_Status > -2
        BEGIN
            CLOSE cursDNamesAsColumns ;
            DEALLOCATE cursDNamesAsColumns ;
        END
    SELECT ErrorNum = ERROR_NUMBER(),ErrorMsg = ERROR_MESSAGE() ;
END CATCH

GO


