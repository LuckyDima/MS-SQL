DECLARE @i INT = 1
DECLARE @j INT = 10
;WITH cte AS 
(
SELECT @i AS i , @j AS j
UNION ALL
SELECT i + @i ,j + @j FROM cte
WHERE cte.i < 10
)
SELECT 
	cte.i ,
    cte.j 
FROM cte 
