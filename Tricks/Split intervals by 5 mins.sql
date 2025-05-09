SELECT * --datepart(hour, dt) as Date ,COUNT(*) as Cnt
FROM [InfoFlowServicesLog].[dbo].[RequestLog] (NOLOCK) 
WHERE ProjectID=5983 AND dt BETWEEN '2013-05-26' AND '2013-05-27'
--GROUP BY  datepart(hour, dt) ORDER BY DATEPART(hour, dt) DESC


SELECT  convert(smalldatetime,ROUND(cast(dt as float) * (24/.25),0)/(24/.25)) AS RoundedTime
,COUNT(*) as Cnt
FROM [InfoFlowServicesLog].[dbo].[RequestLog] (NOLOCK) 
WHERE ProjectID=5983 AND dt BETWEEN '2013-05-26' AND '2013-05-27'
GROUP BY convert(smalldatetime,ROUND(cast(dt as float) * (24/.25),0)/(24/.25))
order by 1