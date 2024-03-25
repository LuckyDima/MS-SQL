CREATE OR ALTER PROCEDURE [policy].[FixDbOwner]
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS(SELECT * FROM dbo.Check_Policies WHERE name = 'DB owner is sa')
BEGIN
	WHILE EXISTS (SELECT * FROM master.sys.databases (NOLOCK) WHERE SUSER_SNAME(owner_sid) <> 'sa' AND state = 0)
	BEGIN
		DECLARE @DbName sysname = (SELECT TOP (1) name FROM master.sys.databases (NOLOCK) WHERE SUSER_SNAME(owner_sid) <> 'sa' AND state = 0);
		DECLARE @Sql NVARCHAR(MAX) = 'USE ' + QUOTENAME(@DbName) + ' ALTER AUTHORIZATION ON DATABASE::' + QUOTENAME(@DbName) + ' TO [sa]';
		EXEC sys.sp_executesql @stmt = @Sql;
	END;
END;
END;
