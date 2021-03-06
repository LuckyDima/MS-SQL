--------------------------------------------------------------------------------
--
-- Script by Dmitry Natenzon
--
-- Some parts of code & description are copyrighted (c) by Microsoft.
--
-- SQL Server 2000. Repairs orphaned DB users (SQL Server Authentication)
-- by restoring the links to the SQL Server Logins of the same names.
-- If a corresponding SQL Server Login is missing, it will be created first
-- (with empty password).
--
-- sysadmin permissions required.
--
-- Examine the result to confirm that the correct links are in fact made.
--
--------------------------------------------------------------------------------
--
-- The SELECT statement beloiw was copied from the sp_change_users_login code,
-- 'Report' section. I could not use sp_change_users_login call directly because
-- of the following error:
--
-- Server: Msg 15289, Level 16, State 1, Procedure sp_change_users_login, Line 27
-- Terminating this procedure. Cannot have an open transaction when this is run.
--
-- Server: Nachr.-Nr. 15289, Schweregrad 16, Status 1, Prozedur sp_change_users_login, Zeile 27
-- Diese Prozedur wird beendet. Wenn sie ausgefuhrt wird, darf keine Transaktion geoffnet sein.
--
-- The error was caused by the following statement:
--
-- INSERT INTO #orphaned EXEC sp_change_users_login 'Report'
--
-- Calling just EXEC sp_change_users_login 'Report' without INSERT was nevertheless successful.
--
--------------------------------------------------------------------------------

   DECLARE @user SYSNAME, @cnt INT
   SET @cnt = 0

   DECLARE cr CURSOR LOCAL FOR
      SELECT [name] FROM sysusers
      WHERE ([issqluser] = 1) AND ([sid] IS NOT NULL) AND ([sid] <> 0x0) AND (SUSER_SNAME([sid]) IS NULL)
      ORDER BY [name] ASC
   OPEN cr
   FETCH NEXT FROM cr INTO @user
   WHILE @@FETCH_STATUS = 0
   BEGIN
      PRINT ''
      PRINT 'DB USER ''' + @user + '''..........'

      IF EXISTS(SELECT 0 FROM master.dbo.syslogins WHERE [name] = @user) PRINT ' - SQL Server Login already exists.'
      ELSE
      BEGIN
         EXEC sp_addlogin @loginame = @user, @passwd = ''
         PRINT ' - SQL Server Login created.'
      END

      EXEC sp_change_users_login 'Auto_Fix', @user
      PRINT ' - Link db-user <--> sql-server-login fixed.'

      SET @cnt = @cnt + 1

      FETCH NEXT FROM cr INTO @user
   END
   CLOSE cr
   DEALLOCATE cr

   PRINT ''
   PRINT CAST(@cnt AS NVARCHAR(50)) + ' DB user(s) fixed. Please examine the result to confirm that the correct links are in fact made.'
GO

--------------------------------------------------------------------------------
-- eof
