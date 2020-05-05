select @@SERVERNAME
go
sp_dropserver '<servername>'
go
sp_addserver '<servername>', 'local'
go
select @@SERVERNAME
go