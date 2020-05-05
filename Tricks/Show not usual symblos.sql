
DECLARE @nstring NVARCHAR(100)
SET @nstring =(select Phone from [DB].[dbo].[CallCenterTicketProfile] (nolock) WHERE ticketid= 934138 )
 
DECLARE @position INT
SET @position = 1
   
DECLARE @CharList TABLE (
  Position INT,
  UnicodeChar NVARCHAR(1),
  UnicodeValue INT
)
 
WHILE @position <= DATALENGTH(@nstring)
  BEGIN
  INSERT @CharList
  SELECT @position as Position 
    ,CONVERT(nchar(1),SUBSTRING(@nstring, @position, 1)) as UnicodeChar
    ,UNICODE(SUBSTRING(@nstring, @position, 1)) as UnicodeValue
  SET @position = @position + 1
  END
