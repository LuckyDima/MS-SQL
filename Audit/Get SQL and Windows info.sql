CREATE PROC [dbo].[get_system_info]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DROP TABLE IF EXISTS #Bios,
                         #Patches;
    CREATE TABLE #Bios
    (
        [BiosVersion] NVARCHAR(265)
    );
    CREATE TABLE #Patches
    (
        [PatchesVersion] NVARCHAR(265)
    );
    INSERT INTO [#Bios]
    EXEC master..[xp_cmdshell] 'systeminfo /FO "LIST" | findstr /C:"BIOS"';
    INSERT INTO #Patches
    EXEC master..[xp_cmdshell] 'systeminfo /FO "LIST" | findstr /C:"KB"';

    DECLARE @bios NVARCHAR(256) = N'',
            @kb NVARCHAR(MAX) = N'';
    SELECT @bios = @bios + TRIM(REPLACE([BiosVersion], 'BIOS Version:', ''))
    FROM [#Bios]
    WHERE [BiosVersion] IS NOT NULL;
    SELECT @kb = @kb + RIGHT(TRIM([PatchesVersion]), 9) + N'; '
    FROM [#Patches]
    WHERE [PatchesVersion] IS NOT NULL;

    SELECT GETDATE() AS DateCollection,
           SERVERPROPERTY('MachineName') AS ComputerName,
           SERVERPROPERTY('ServerName') AS InstanceName,
           SERVERPROPERTY('Edition') AS Edition,
           SERVERPROPERTY('ProductVersion') AS ProductVersion,
           SERVERPROPERTY('ProductLevel') AS ProductLevel,
           SERVERPROPERTY('ProductUpdateReference') AS ProductUpdateReference,
           SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel,
           SERVERPROPERTY('HadrManagerStatus') AS HadrManagerStatus,
           SERVERPROPERTY('IsAdvancedAnalyticsInstalled') AS IsAdvancedAnalyticsInstalled,
           SERVERPROPERTY('IsBigDataCluster') AS IsBigDataCluster,
           SERVERPROPERTY('IsClustered') AS IsClustered,
           SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled,
           SERVERPROPERTY('IsHadrEnabled') AS IsHadrEnabled,
           [i].[host_platform] HostPlatform,
           [i].[host_distribution] HostVersion,
           [i].[host_release] HostRelease,
           [i].[host_sku],
           [l].[alias],
           TRIM(@bios) AS BiosVersion,
           TRIM(@kb) AS WindowsUpdates
    FROM master.sys.[dm_os_host_info] i
        JOIN master.sys.[syslanguages] l
            ON i.[os_language_version] = [l].[lcid];
END;
GO
