SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @StringToSearchFor Varchar(255)

Set @StringToSearchFor = '%<ColumnsWithNoStatistics>%'

SELECT  st.text

      ,cp.cacheobjtype

      ,cp.objtype

      ,DB_NAME(st.dbid) AS [DatabaseName]

      ,cp.usecounts

      ,qp.query_plan

FROM sys.dm_exec_cached_plans cp

      CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st

      CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp

WHERE CAST(qp.query_plan AS NVARCHAR(MAX))LIKE @StringToSearchFor
AND DB_NAME(st.dbid) is not null

ORDER BY cp.usecounts DESC

--����������: ����� �������� �������� @Stringtosearchfor �� :

--    '%<ColumnsWithNoStatistics>%' ����� ������ ���������� � �������� ��� ���������;
--    '%<MissingIndexes>%' ����� ������ ���������� � ����������� ��������;
--    '%<TableScan>%' ����� ������ ����� ������� ���� �������������. 
----SET SHOWPLAN_XML OFF
-- ����� ���� ��� ��������� ���������� ��������� �������������� ���������:
--EXEC sp_recompile N'[dbo].[Index_Analizator]';
--GO

      