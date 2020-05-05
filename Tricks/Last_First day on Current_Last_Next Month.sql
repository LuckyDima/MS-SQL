DECLARE @TestDate DATETIME
SET @TestDate = '2017-01-01'

SELECT
'The beginning of time'	= CONVERT(DATETIME,0),
'Tomorrow'	= @TestDate + 1,
'Months since time began plus one'	= DATEDIFF(m,0,@TestDate)+1, 
'First Day of Next Month with Months int'	= DATEADD(m,(DATEDIFF(m,0,@TestDate)+1),0)

SELECT
'First Day of Next Month'	= DATEADD(mm, DATEDIFF(m,0,@TestDate)+1,0),
'Last Day of This Month'	= DATEADD(mm, DATEDIFF(m,0,@TestDate)+1,0)-1,
'First Day of Last Month'	= DATEADD(mm, DATEDIFF(m,0,@TestDate)-1,0),
'Last Day of Last Month'	= DATEADD(mm, DATEDIFF(m,0,@TestDate),0)-1,
'Last Day of Next Month'	= DATEADD(mm, DATEDIFF(m,0,@TestDate)+2,0)-1
SELECT
'First Day of Next Month'	= CONVERT(DATETIME,EOMONTH(@TestDate))+1,
'Last Day of This Month'	= CONVERT(DATETIME,EOMONTH(@TestDate)),
'First Day of Last Month'	= CONVERT(DATETIME,EOMONTH(@TestDate,-2))+1,
'First Day of This Month'	= CONVERT(DATETIME,EOMONTH(@TestDate,-1))+1,
'Last Day of Last Month'	= CONVERT(DATETIME,EOMONTH(@TestDate,-1)),
'Last Day of Next Month'	= CONVERT(DATETIME,EOMONTH(@TestDate,1))
