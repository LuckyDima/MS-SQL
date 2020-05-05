UPDATE <updatetable>
SET 
 col1 = b.col1
,col2 = a.col2
FROM <updatetable> a 
INNER JOIN <tablename> b ON a.id = b.id
AND b.col1 IS NOT NULL
AND b.id = a.id