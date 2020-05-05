set concat_null_yields_null on 

declare 
@collist varchar(max),
@srch_sql varchar(max),
@schemaName varchar(128),
@tableName varchar(128)

declare curs cursor local static forward_only for 
select distinct c.TABLE_SCHEMA, c.TABLE_NAME 
from INFORMATION_SCHEMA.[COLUMNS] c 
where c.DATA_TYPE in('char', 'varchar', 'nvarchar', 'text') 
and c.CHARACTER_MAXIMUM_LENGTH >=4
and objectproperty(object_id(c.TABLE_SCHEMA + '.'+ c.TABLE_NAME), 'IsUserTable ') = 1 
order by 1, 2 
open curs
while 1=1
begin 

fetch next from curs into @schemaName, @tableName 
if @@FETCH_STATUS <> 0 break 
-- Данную строку можно раскомментарить, если хочется видеть, в какой таблице идет поиск в данный момент 
-- raiserror(';%s.%s', 10, 1, @schemaName, @tableName) with nowait
select
@collist = null
 
select
@collist = isnull(@collist + ' 
or ', '') +'upper(convert(varchar(8000), ' + c.COLUMN_NAME + ')) like ''%test%''' -- Тут указываем, что и как ищем 
from INFORMATION_SCHEMA.[COLUMNS] c
where c.TABLE_SCHEMA = @schemaName
and c.TABLE_NAME = @tableName 
and c.DATA_TYPE in('char', 'varchar', 'nvarchar', 'text') 
and c.CHARACTER_MAXIMUM_LENGTH >=6
set @srch_sql = 'if exists(select * from '+@schemaName+'.'+@tableName+' with(nolock) where '+@collist+')
raiserror('''+@schemaName+'.'+@tableName+' - found!'', 10, 1) with nowait'
 --PRINT @srch_sql
exec(@srch_sql) 
end




---------------------------------------------------------------------------
--Для трех патернов:
--------------------------------------------------------------------------
SET CONCAT_NULL_YIELDS_NULL ON;
SET NOCOUNT ON;

DECLARE @collist         VARCHAR(MAX),
        @srch_sql        VARCHAR(MAX),
        @schemaName      VARCHAR(128),
        @tableName       VARCHAR(128),
		@dbname			 NVARCHAR(128),
        @FirstPatern     NVARCHAR(MAX) = 'test', -- Тут указываем, что и как ищем (первое вхождение)
        @SecondaryPatern NVARCHAR(MAX) = 'aaa', -- второе вхождение
        @ThirdPatern     NVARCHAR(MAX); -- третье вхождение


DECLARE curs CURSOR LOCAL STATIC FORWARD_ONLY FOR
SELECT DISTINCT c.TABLE_SCHEMA,
       c.TABLE_NAME
  FROM INFORMATION_SCHEMA.[COLUMNS] c
 WHERE c.DATA_TYPE IN ( 'char', 'varchar', 'nvarchar', 'text' )
   AND c.CHARACTER_MAXIMUM_LENGTH                                                     >= 4
   AND OBJECTPROPERTY(OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), 'IsUserTable ') = 1
 ORDER BY 1,
          2;
OPEN curs;
WHILE 1 = 1
BEGIN

    FETCH NEXT FROM curs
     INTO @schemaName,
          @tableName;
    IF @@FETCH_STATUS <> 0
        BREAK;
    -- Данную строку можно раскомментарить, если хочется видеть, в какой таблице идет поиск в данный момент 
    -- raiserror(';%s.%s', 10, 1, @schemaName, @tableName) with nowait
    SELECT @collist = NULL;

    SELECT @collist = 
	ISNULL(@collist + ' OR ', '') 
	+ '(CONVERT(NVARCHAR(MAX), ' + c.COLUMN_NAME + ')) LIKE ''%'+@FirstPatern+'%'''
	+ CASE 
		WHEN @SecondaryPatern IS NOT NULL 
		THEN ' AND '+ '(CONVERT(NVARCHAR(MAX), ' + c.COLUMN_NAME + ')) LIKE ''%'+@SecondaryPatern+'%'''
	  ELSE '' END
	+ CASE 
		WHEN @ThirdPatern IS NOT NULL 
		THEN ' AND '+ '(CONVERT(NVARCHAR(MAX), ' + c.COLUMN_NAME + ')) LIKE ''%'+@ThirdPatern+'%'''
	   ELSE '' END
	 FROM INFORMATION_SCHEMA.[COLUMNS] c
     WHERE c.TABLE_SCHEMA             = @schemaName
       AND c.TABLE_NAME               = @tableName
       AND c.DATA_TYPE IN ( 'char', 'varchar', 'nvarchar', 'text' )
       AND c.CHARACTER_MAXIMUM_LENGTH >= 6;
	SELECT @dbname = DB_NAME()
    SET @srch_sql
        = 'IF EXISTS(SELECT TOP 1 1 FROM ' + @schemaName + '.' + @tableName + ' WITH (NOLOCK) WHERE ' + @collist
          + ')
raiserror(''['  + @dbname + '].['  + @schemaName + '].[' + @tableName + '] - Congratulations, your line is found!'', 10, 1) with nowait';
   -- PRINT @srch_sql;
    EXEC (@srch_sql);
END;
