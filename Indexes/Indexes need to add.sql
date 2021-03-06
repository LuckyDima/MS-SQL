--------------------------------------------------------------------------------------------

-- �������� ����������� �������� ��� ������ �� SQL Server 2005, 2008

-- 

-- ������ ����������� ����������, ��������� �������� ��� ������ �� ������������� �������� � ����� ������ �

-- ���������� ������� �������, ������� ����� ���������� ������������ ��������� ������������������. 

SET NOCOUNT ON

DECLARE @dbid int

IF (object_id('tempdb..##IndexAdvantage') IS NOT NULL) DROP TABLE ##IndexAdvantage

CREATE TABLE ##IndexAdvantage ([������������ �������] float, [���� ������] varchar(64), [Transact SQL ��� ��� �������� �������] varchar(512), 

[����� ����������] int, [���������� �������� ������] int, [���������� �������� ���������] int,

[������� ��������� ] int, [������� ������� ��������] int );

DECLARE DBases CURSOR FOR

SELECT database_id FROM sys.master_files -- �������� ������ ID ��� ������

WHERE state = 0 AND -- ONLINE

has_dbaccess(db_name(database_id)) = 1 -- Only look at databases to which we have access

GROUP BY database_id

OPEN DBases

FETCH NEXT FROM DBases

INTO @dbid

WHILE @@FETCH_STATUS = 0

BEGIN -- ��������� ��� ������ ���� ������ --------------------------------------------------

INSERT INTO ##IndexAdvantage

SELECT [������������ �������] = user_seeks * avg_total_user_cost * (avg_user_impact * 0.01),

      [���� ������] = DB_NAME(mid.database_id),

      [Transact SQL ��� ��� �������� �������] = 'CREATE INDEX [IX_' + OBJECT_NAME(mid.object_id,@dbid) + '_' + 

      CAST(mid.index_handle AS nvarchar) + '] ON ' + 

      mid.statement + ' (' + ISNULL(mid.equality_columns,'') + 

      (CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', ' 

ELSE '' END) + 

      (CASE WHEN mid.inequality_columns IS NOT NULL THEN + mid.inequality_columns ELSE '' END) + ')' + 

      (CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')' 

ELSE '' END) +      ';', 

      [����� ����������] = migs.unique_compiles,

      [���������� �������� ������] = migs.user_seeks,

      [���������� �������� ���������] = migs.user_scans,

      [������� ��������� ] = CAST(migs.avg_total_user_cost AS int),

      [������� ������� ��������] = CAST(migs.avg_user_impact AS int)

FROM  sys.dm_db_missing_index_groups mig

JOIN  sys.dm_db_missing_index_group_stats migs 

ON    migs.group_handle = mig.index_group_handle

JOIN  sys.dm_db_missing_index_details mid 

ON    mig.index_handle = mid.index_handle

AND   mid.database_id = @dbid

    FETCH NEXT FROM DBases

    INTO @dbid

END ----------------------------------------------------------------------------------------

CLOSE DBases

DEALLOCATE DBases

GO

SELECT * FROM ##IndexAdvantage ORDER BY 1 DESC

-- �������� ''������������ �������'' ���� 5000 � ������������ �������� ��������, ��� ������� ����������� ����������� �������� ���� ��������.

-- ���� �� �������� ��������� 10000, ��� ������ ��������, ��� ������ ����� ���������� ������������ ��������� ������������������ ��� �������� ������.

--------------------------------------------------------------------------------------------

-- ���������� email � ������������ ������� ������

IF (object_id('tempdb..##IndexAdvantage2') IS NOT NULL) DROP TABLE ##IndexAdvantage2

SELECT * INTO ##IndexAdvantage2 FROM ##IndexAdvantage WHERE [������������ �������] >= 5000 ORDER BY 1 DESC

IF ((SELECT COUNT(*) FROM ##IndexAdvantage2) >= 1) BEGIN

DECLARE @subject_str varchar(255),

@message_str varchar(1024),

@separator_str varchar(1),

@email varchar(128)

SET @separator_str=CHAR(9) -- ������ ���������

SET @email = 'email_address@webzavod.ru'

-- ���������� ����� ���������

SET @subject_str = 'SQL Server '+@@SERVERNAME+': ����������� ������� ������� � ���� ������.'

SET @message_str = '������ '+@@SERVERNAME + '. �������� ������������� ������� ������� � ���� ������!

�� �������� - ������� � ����� ������������ ��������.

�������� "������������ �������" ���� 5000 � ������������ �������� ��������, ��� ������� ����������� ����������� �������� ���� ��������.

���� �� �������� ��������� 10000, ��� ������ ��������, ��� ������ ����� ���������� ������������ ��������� ������������������ ��� �������� ������.

������������ ���������������� �������������, ������� ������� ��� �������� ���������� �� ������������� ��������, �� �������� ������� ��������� �� ��������� ���� ����, ������� ����� ������������� ��������������� ������������� � ������ � ������������ ����� ������������ ������ ��������, �� ��� ����� ���� ����� ���������� �� ��������� ������ �������.'

-- ���������� email

EXEC msdb.dbo.sp_send_dbmail

@recipients = @email,

@query = 'SELECT * FROM ##IndexAdvantage2',

@subject = @subject_str,

@body = @message_str,

@attach_query_result_as_file = 1,

@query_result_separator = @separator_str,

@query_result_width = 7000

END

-- ������� ��������� �������

IF (object_id('tempdb..##IndexAdvantage') IS NOT NULL) DROP TABLE ##IndexAdvantage

IF (object_id('tempdb..##IndexAdvantage2') IS NOT NULL) DROP TABLE ##IndexAdvantage2
--------------------------------------------------------------------------------------------  