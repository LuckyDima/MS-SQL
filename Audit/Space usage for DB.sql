exec sp_spaceused
DBCC UPDATEUSAGE('<dbname>')
exec sp_msforeachdb N'use [?] EXEC sp_spaceused @updateusage = ''TRUE''' 