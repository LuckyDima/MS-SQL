DECLARE @v1 sql_variant;  
SET @v1 = 1;  
SELECT @v1;  
SELECT SQL_VARIANT_PROPERTY(@v1, 'BaseType'); 
