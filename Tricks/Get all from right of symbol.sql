declare @var varchar(100)
set @var = 'www.mmm.nb.ru'
select RIGHT(@var, charindex('.', reverse(@var)) - 1)
