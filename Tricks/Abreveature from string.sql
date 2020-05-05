--Аббревиатура из строки
ALTER FUNCTION dbo.Abbreviate ( @InputString NVARCHAR(MAX) ) 
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Index INT
    DECLARE @OutputString NVARCHAR(MAX)

    SET @InputString = LTRIM(@InputString)
    SET @OutputString = UPPER(LEFT(@InputString, 1))
    SET @Index = CHARINDEX(' ', @InputString) + 1

    WHILE @Index > 1 
    BEGIN
        SET @OutputString = @OutputString + UPPER(SUBSTRING(@InputString, @Index, 1)) 
        SET @Index = CHARINDEX(' ', @InputString, @Index) + 1
    END
    RETURN @OutputString
END
GO

-- To Run it:

SELECT dbo.Abbreviate (N'тут должны БЫТь большие буКвы от ПервЫх СЛов')
