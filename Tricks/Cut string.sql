DECLARE @row NVARCHAR(MAX) = N'Фамилия Имя Отчество'
DECLARE @separate CHAR(1) = ' '
SELECT SUBSTRING(@row, CHARINDEX(@separate, @row) + 1, LEN(@row) - CHARINDEX(@separate, @row) - CHARINDEX(@separate, REVERSE(@row)))
