SET NOCOUNT ON;

IF EXISTS (SELECT TOP (1) 1 FROM sys.views (NOLOCK) WHERE name = 'GetRandomNumber' and type = 'v')
DROP VIEW GetRandomNumber
GO
CREATE VIEW GetRandomNumber AS SELECT TOP (1) 1.0 + FLOOR(1000 * RAND(CONVERT(VARBINARY, NEWID()))) AS num
GO
DECLARE @var nvarchar(max) = ''

;WITH cte1 AS
(
SELECT v1.num num1 ,v2.num num2 , 1 AS rvn FROM GetRandomNumber v1 ,GetRandomNumber v2
UNION ALL
SELECT v1.num,v2.num,rvn+1 
FROM cte1,GetRandomNumber v1 ,GetRandomNumber v2 WHERE rvn <10
)
SELECT @var = @var + CAST(num1 AS varchar(5)) + ' ' + CAST(num2 AS varchar(5)) + 
CASE WHEN rvn < 10 THEN  ',' ELSE '' END 
FROM cte1

DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('LINESTRING ('+  @var + ')', 0);  
SELECT @g
