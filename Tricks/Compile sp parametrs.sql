USE [msdb]
GO
/****** Object:  UserDefinedFunction [dbo].[setoptions]    Script Date: 16/10/27 16:05:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Function to translate the set_options attribute in sys.dm_plan_exec_attributes.
-- Written by Erland Sommarskog, 2011-01-02.
ALTER FUNCTION [dbo].[setoptions] (@setopts int) RETURNS TABLE AS
RETURN
WITH
  L0      AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1      AS(SELECT 1 AS c FROM L0 AS A, L0 AS B),
  L2      AS(SELECT 1 AS c FROM L1 AS A, L1 AS B),
  L3      AS(SELECT 1 AS c FROM L2 AS A, L0 AS B),
  PowsOf2 AS(SELECT power(convert(bigint, 2),
                       ROW_NUMBER() OVER(ORDER BY c) - 1) AS p2
             FROM L3)
SELECT CASE p2
          WHEN       1 THEN 'ANSI_PADDING'
          WHEN       2 THEN 'Parallel Plan'
          WHEN       4 THEN 'FORCEPLAN'
          WHEN       8 THEN 'CONCAT_NULL_YIELDS_NULL'
          WHEN      16 THEN 'ANSI_WARNINGS'
          WHEN      32 THEN 'ANSI_NULLS'
          WHEN      64 THEN 'QUOTED_IDENTFIER'
          WHEN     128 THEN 'ANSI_NULL_DFLT_ON'
          WHEN     256 THEN 'ANSI_NULL_DFLT_OFF'
          WHEN     512 THEN 'NoBrowseTable'
          WHEN    1024 THEN 'TriggerOneRow'
          WHEN    2048 THEN 'ResyncQuery'
          WHEN    4096 THEN 'ARITHABORT'
          WHEN    8192 THEN 'NUMERIC_ROUNDABORT'
          WHEN   16384 THEN 'DATEFIRST'
          WHEN   32768 THEN 'DATEFORMAT'
          WHEN   65536 THEN 'LanguageID'
          WHEN  131072 THEN 'Force parameterization'
		  WHEN	262144 THEN 'ROWCOUNT'
          ELSE 'Unknown, bit ' + str(p2, 10)
       END AS Set_option
FROM   PowsOf2
WHERE  p2 & @setopts <> 0




WITH cte AS 
(
SELECT TOP 10 
cp.cacheobjtype
,cp.objtype
,cp.plan_handle
,t.text
,q.query_plan
,cp.usecounts
,cp.size_in_bytes
,cp.bucketid,refcounts
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) t
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) q
WHERE t.text LIKE '%ProcessSearchUpdateQueue%'
	AND t.dbid = DB_ID('HotelInventory')
	AND t.objectid =2087014516
	ORDER BY cp.usecounts DESC
	)
	--SELECT * FROM sys.dm_exec_plan_attributes (cte.plan_handle)
	SELECT * FROM cte
	CROSS APPLY sys.dm_exec_plan_attributes (cte.plan_handle)
