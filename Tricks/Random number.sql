SELECT TOP (1) 1.0 + FLOOR(5 * RAND(CONVERT(VARBINARY, NEWID()))) 


SELECT ABS(CAST(CAST(NEWID() AS VARBINARY) AS INT)) AS [RandomNumber]


CAST(RAND(CHECKSUM(NEWID())) * 10 AS INT)