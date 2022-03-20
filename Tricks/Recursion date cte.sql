DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME;
SELECT @FromDate = '20170101', @ToDate = '20170121';
WITH Days(D) AS
(
 SELECT @FromDate WHERE @FromDate <= @ToDate
 UNION ALL
 SELECT DATEADD(DAY,1,D) FROM Days WHERE D < @ToDate
)
SELECT D FROM Days ORDER BY D
OPTION (MAXRECURSION 0);



;with cte as
(
select 1 n
union all
select n + 1 from cte where n < 20
)
,cte2 as
(
select n * cast(rand() as decimal(2,1)) rnd from cte
)
select 
count(rnd) cnt, min(rnd) min, max(rnd) max
from cte2 
group by (iif(cte2.rnd<=2,0,iif(cte2.rnd >2 and cte2.rnd <=5,1,2)))
