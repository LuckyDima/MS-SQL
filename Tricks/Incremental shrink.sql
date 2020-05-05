USE [db]
GO
-- Shrink_DB_File.sql
declare @sql varchar(8000)
declare @name sysname
declare @sizeMB int
declare @UsedMB int
declare @FreeMB int
declare @ShrinkMB int
-- Desired free space in MB after shrink
set @FreeMB = 1000
-- Increment to shrink file by in MB
set @ShrinkMB = 100
-- Name of Database file to shrink
set @name = 'logical_name'
-- Get current file size in MB
select @sizeMB = size/128. from sysfiles where name = @name
-- Get current space used in MB
select @UsedMB = fileproperty( @name,'SpaceUsed')/128.
select [StartFileSize] = @sizeMB, [StartUsedSpace] = @UsedMB, [File] = @name
-- Loop until file at desired size
while  @sizeMB > @UsedMB+@FreeMB+@ShrinkMB
 	begin
 	set @sql =
 	'dbcc shrinkfile ( ' + @name + ', '+convert(varchar(20),@sizeMB-@ShrinkMB)+' ) '
 	print 'Start ' + @sql
 	exec ( @sql )

 	print 'Done ' + @sql
 	-- Get current file size in MB
 	select @sizeMB = size/128. from sysfiles where name = @name
 
 	-- Get current space used in MB
 	select @UsedMB = fileproperty( @name,'SpaceUsed')/128.
 	end
select [EndFileSize] = @sizeMB, [EndUsedSpace] = @UsedMB, [File] = @name
