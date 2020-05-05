;WITH cte(val) AS
(
SELECT 1 AS val
UNION ALL
SELECT cte.val + 1 FROM [cte] cte WHERE [cte].[val] < 100
)
,cte2 AS
(
SELECT AVG([cte].[val]) AS avgval FROM [cte] 
),
cte3 AS
(
SELECT val-(SELECT [cte].[avgval] FROM [cte2] cte) AS rvn, val FROM  [cte]
)
SELECT val FROM cte3 s1 where s1.rvn >= 0 
UNION ALL
SELECT val FROM cte3 s2 where s2.rvn < 0
