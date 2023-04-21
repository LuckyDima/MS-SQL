SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[RestoreDB]	 (
	@db_name NVARCHAR(MAX) = NULL, 
	@db_name_prefix NVARCHAR(MAX) = '',
	@db_name_posfix NVARCHAR(MAX) = '',
	@db_name_new NVARCHAR(MAX) = NULL ,
	@force_replace BIT = 0,
	@get_sync_status BIT = 0,
	@environment NVARCHAR(MAX) = 'dev', /*dev, devrds*/
	@debug BIT = 0
	)
AS 
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

	DROP TABLE IF EXISTS #DBs, #cte

	CREATE TABLE #cte 
	(
	DBName NVARCHAR(256) NULL,
	LogicalName NVARCHAR(256) NULL,
	TypeofFile NVARCHAR(24) NULL,
	Path NVARCHAR(MAX) NULL,
	Rank INT NOT NULL
	)

	IF @db_name IS NULL AND @get_sync_status = 0
	BEGIN 
		PRINT 'The list of databases is empty.'
		RETURN;
	END;
	IF @db_name_new IS NOT NULL AND @db_name LIKE '%,%'
	BEGIN 
		PRINT 'The parameter @db_name_new doesn''t support a list of databases. Please use an one db name instead of multiple dbs.'
		RETURN; 
	END;

	DECLARE @s3_bucket_link sysname = (SELECT name FROM sys.credentials WHERE credential_identity = 'S3 Access Key' AND name LIKE '%pos-dev%' AND @environment = 'devrds');
	DECLARE @sql NVARCHAR(MAX) = '';

	IF @environment IS NULL OR @environment NOT IN ('dev', 'devrds')
	BEGIN
		PRINT 'The variable @environment must be set. Use "dev" or "devrds" value.'
		RETURN;
    END;

	IF @environment = 'devrds' AND @s3_bucket_link IS NULL
	BEGIN
		PRINT 'For current environment ' + @environment+ ' S3 bucket link is empty.'
		RETURN;
	END;
	
	IF @environment = 'devrds'
	BEGIN TRY 
		;WITH cte AS 
		(
			SELECT DISTINCT value AS DBName
			FROM STRING_SPLIT(REPLACE(@db_name,' ',''),',')
		)
		INSERT INTO #cte
		SELECT 
			cte.DBName
			, f.name LogicalName
			, f.type_desc TypeofFile
			, CAST(IIF(f.type_desc= 'LOG', SERVERPROPERTY('InstanceDefaultLogPath') , SERVERPROPERTY('InstanceDefaultDataPath')) AS NVARCHAR(MAX)) Path
			, DENSE_RANK() OVER (ORDER BY cte.DBName ASC) Rank
		FROM cte
		LEFT JOIN [pos].master.sys.databases d ON d.name = cte.DBName 
		LEFT JOIN [pos].master.sys.master_files f ON d.database_id = f.database_id 
	END TRY 
	BEGIN CATCH
		PRINT 'The linked server pos is unreacheble.'
	END CATCH;
  

	IF @environment = 'dev'
	BEGIN TRY 
		;WITH cte AS 
		(
			SELECT DISTINCT value AS DBName
			FROM STRING_SPLIT(REPLACE(@db_name,' ',''),',')
		)
		INSERT INTO #cte

		SELECT 
			cte.DBName
			, ff.name LogicalName
			, ff.type_desc TypeofFile
			, CAST(IIF(ff.type_desc = 'LOG', SERVERPROPERTY('InstanceDefaultLogPath') , SERVERPROPERTY('InstanceDefaultDataPath')) AS NVARCHAR(MAX)) Path
			, DENSE_RANK() OVER (ORDER BY cte.DBName ASC) Rank
		FROM cte
		LEFT JOIN [dev].master.sys.databases dd ON dd.name = cte.DBName
		LEFT JOIN [dev].master.sys.master_files ff ON dd.database_id = ff.database_id
    END TRY
	BEGIN CATCH
		PRINT 'The linked server dev is unreacheble.'
	END CATCH;

	SELECT 
		c.DBName,
		c.TypeofFile,
		c.Rank,
		c.Path,
		c.LogicalName,
		IIF(c.TypeofFile = 'LOG','.ldf',IIF(ROW_NUMBER() OVER (PARTITION BY c.DBName ORDER BY c.Rank ASC) = 1, '.mdf','.ndf')) Extension	
	INTO #DBs
	FROM #cte c;
	
	IF @get_sync_status = 1
	BEGIN

		IF @db_name IS NULL 
		BEGIN 
			PRINT 'The @db_name value is empty.'
			RETURN;
		END;

		IF NOT EXISTS (SELECT * FROM master.sys.databases WHERE name = @db_name)
		BEGIN 
			PRINT 'The database ' + @db_name + ' doesn''t exist.'
			RETURN;
		END;

		IF (SELECT name FROM master.sys.databases WHERE state_desc = 'online' AND name = @db_name) IS NULL
		BEGIN 
			DECLARE @message NVARCHAR(MAX) = ''
			
			SELECT @message = 'The database ' + @db_name + ' has status is ' + ISNULL(state_desc,'unknown') FROM master.sys.databases WHERE name = @db_name
			PRINT @message
			RETURN;
		END;
		
		SELECT @sql = 'SELECT u.name FROM master.sys.sql_logins l JOIN [' + 
		ISNULL(@db_name_prefix,'')  + IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, REPLACE(d.DBName,'_','-')),d.DBName) + ISNULL(@db_name_posfix,'')
		+ '].sys.sysusers u ON u.name = l.name WHERE l.name LIKE ''%kubernetes-user''' 
		FROM #DBs d;

		IF @debug = 1
			PRINT @sql;
		ELSE 
			EXEC sp_executesql @sql;

		RETURN;
 	END

	IF @force_replace = 0
		DELETE d 
		FROM #DBs d 
		JOIN master.sys.databases m ON 
		(ISNULL(@db_name_prefix,'')  + IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, REPLACE(d.DBName,'_','-')),d.DBName) + ISNULL(@db_name_posfix,'')) = m.name;

	IF (SELECT @@ROWCOUNT) > 0
		PRINT 'Database '+ @db_name_new + ' alredy exists. For replace use @force_replace = 1'


	DECLARE @MaxCounter INT = (SELECT MAX(Rank) FROM #DBs);
	DECLARE @CurrentCounter INT = (SELECT MIN(Rank) FROM #DBs);

	WHILE @CurrentCounter <= @MaxCounter
	BEGIN 
		SELECT @sql = @sql + 
		', MOVE N''' + d.LogicalName + ''' TO N''' + d.Path + ISNULL(@db_name_prefix,'') 
		+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, IIF(@db_name_posfix IS NULL AND @db_name_new IS NULL,'', d.LogicalName)),d.LogicalName) 
		+ ISNULL(@db_name_posfix,'') + IIF(d.TypeofFile='FILESTREAM','', d.Extension) 
		+ '''' FROM #DBs d WHERE @CurrentCounter = d.Rank;

		IF @environment = 'devrds'
		BEGIN 
	
			
			SELECT TOP (1) @sql = 'RESTORE DATABASE [' + @db_name_prefix 
			+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, d.DBName),d.DBName) + @db_name_posfix 
			+ '] FROM URL = N'''+@s3_bucket_link+'/'+ d.DBName + '_latest.bak''' 
			+ ' WITH FILE = 1' + @sql + ', NOUNLOAD, REPLACE;' 
			FROM #DBs d WHERE @CurrentCounter = d.Rank 
	
			SELECT TOP (1) @sql = 'IF EXISTS (SELECT * FROM sys.databases WHERE name = ''' 
			+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, d.DBName),d.DBName) + ISNULL(@db_name_posfix,'') + ''')' + CHAR(13) +
			'ALTER DATABASE [' + IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, d.DBName),d.DBName) + ISNULL(@db_name_posfix,'') 
			+ '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(13) + @sql
			FROM #DBs d WHERE @CurrentCounter = d.Rank 
			ORDER BY d.Rank;

		END;

		IF @environment = 'dev'
		BEGIN 
			DECLARE @full_backup_path NVARCHAR(MAX) = NULL, @diff_backup_path NVARCHAR(MAX) = NULL;

			;WITH cte AS
			(
			SELECT ROW_NUMBER() OVER (PARTITION BY bs.database_name, bs.type ORDER BY bs.backup_finish_date DESC) rvn
			,  bs.server_name, bs.database_name, bs.type, bmf.physical_device_name, bs.backup_finish_date
			FROM 
			   dev.msdb.dbo.backupmediafamily bmf
			   JOIN dev.msdb.dbo.backupset bs ON bmf.media_set_id = bs.media_set_id 
			   WHERE bs.database_name = @db_name AND bs.server_name = (SELECT * FROM OPENQUERY([DEV], 'SELECT @@SERVERNAME'))
			)
			, cte2 AS 
			(
			SELECT ROW_NUMBER() OVER (ORDER BY cte.backup_finish_date DESC) rvn,
				   cte.server_name,
				   cte.database_name,
				   cte.type,
				   cte.physical_device_name,
				   cte.backup_finish_date FROM cte WHERE cte.rvn = 1
			)
			SELECT 
				@full_backup_path = 
				IIF(cte2.type = 'D', cte2.physical_device_name, @full_backup_path),
				@diff_backup_path = 
				IIF(cte2.type = 'I' AND @full_backup_path IS NOT NULL, cte2.physical_device_name, NULL)
			FROM cte2
			ORDER BY cte2.rvn DESC 

			IF @full_backup_path IS NOT NULL
			BEGIN 
							
				DECLARE @sql_full NVARCHAR(MAX) = ''
				SELECT TOP (1) @sql_full = 'RESTORE DATABASE [' + ISNULL(@db_name_prefix,'') 
				+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, REPLACE(d.DBName,'_','-')),d.DBName) + ISNULL(@db_name_posfix,'') 
				+ '] FROM URL = N''' + @full_backup_path + '''' 
				+ ' WITH FILE = 1' + @sql + ', ' + IIF (@diff_backup_path IS NULL, '','NORECOVERY, ') + 'NOUNLOAD, REPLACE;' 
				FROM #DBs d WHERE @CurrentCounter = d.Rank 
				ORDER BY d.Rank;

				SELECT TOP (1) @sql_full = 'IF EXISTS (SELECT * FROM sys.databases WHERE name = ''' 
				+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, d.DBName),d.DBName) + ISNULL(@db_name_posfix,'') + ''')' + CHAR(13) +
				'ALTER DATABASE [' + IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, d.DBName),d.DBName) + ISNULL(@db_name_posfix,'') 
				+ '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(13) + @sql_full
				FROM #DBs d WHERE @CurrentCounter = d.Rank 
				ORDER BY d.Rank;
			END;

			IF @diff_backup_path IS NOT NULL
			BEGIN 
				DECLARE @sql_diff NVARCHAR(MAX) = ''
				SELECT TOP (1) @sql_diff = 'RESTORE DATABASE [' + ISNULL(@db_name_prefix,'') 
				+ IIF(@db_name_posfix IS NOT NULL,IIF(@db_name_new IS NOT NULL,@db_name_new, REPLACE(d.DBName,'_','-')),d.DBName) + ISNULL(@db_name_posfix,'') 
				+ '] FROM URL = N''' + @diff_backup_path + '''' 
				+ ' WITH FILE = 1' + @sql + ', NOUNLOAD;' 
				FROM #DBs d WHERE @CurrentCounter = d.Rank 
				ORDER BY d.Rank;
			END;

			IF @debug = 1
				BEGIN 
					PRINT @sql_full + CHAR(13);
					PRINT @sql_diff + CHAR(13);
				END;
			ELSE
				BEGIN
					IF @full_backup_path IS NULL
						PRINT 'Coulnd''t find backup file path for dev source.';
					IF @sql_full IS NULL
						PRINT 'Wrong script generation for dev source.';
					EXEC sp_executesql @sql_full;
					EXEC sp_executesql @sql_diff;
                END;

		END;
		IF @environment = 'devrds'
			BEGIN 
				IF @debug = 1 
           			PRINT @sql + CHAR(13);
				ELSE 
					BEGIN 
						IF @sql IS NULL 
						PRINT 'Wrong script generation for devrds source.';
						EXEC sp_executesql @sql;
					END;
			END;

		IF @debug = 0
			EXEC msdb.dbo.sp_start_job @job_name = 'DBA: Create user flant in each db';

		SELECT @CurrentCounter += 1, @sql = '';
	END 
END

GO


