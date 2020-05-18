
DROP TABLE IF EXISTS #TestTable

CREATE TABLE #TestTable
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	Name NVARCHAR(40),
	UpdateByApp1Date DATETIME,
	UpdateByApp2Date DATETIME,
	UpdateByApp3Date DATETIME

)

INSERT INTO #TestTable(Name, UpdateByApp1Date, UpdateByApp2Date, UpdateByApp3Date )
VALUES('ABC', '2015-08-05','2015-08-04', '2015-08-06'),
	  ('NewCopmany', '2014-07-05','2012-12-09', '2015-08-14'),
	  ('MyCompany', '2015-03-05','2015-01-14', '2015-07-26')
	  
SELECT * FROM #TestTable


SELECT 
   ID, 
   (SELECT MAX(LastUpdateDate)
      FROM (VALUES (UpdateByApp1Date),(UpdateByApp2Date),(UpdateByApp3Date)) AS UpdateDate(LastUpdateDate)) 
   AS LastUpdateDate
FROM #TestTable