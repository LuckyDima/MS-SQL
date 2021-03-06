  SELECT CAST ('['+ OBJECT_NAME(id) + '].[' + name + ']' AS nvarchar(261)) AS [������]
        ,CONVERT (char(11), STATS_DATE(id, indid),13)			  AS [�����c���� ��:]
        ,CASE
           WHEN indid > 1 
           THEN CAST ((8 * CAST (used AS decimal(9,0)))/1000 AS decimal(9,2))
           WHEN indid = 1 AND OBJECTPROPERTY(id, 'IsView') = 1
           THEN CAST ((8 * CAST (used AS decimal(9,0)))/1000 AS decimal(9,2))
           ELSE NULL	
         END							  AS [��� (��)]
    FROM sysindexes
   WHERE OBJECTPROPERTY(id,       'IsSystemTable'   ) = 0 
     AND INDEXPROPERTY (id, name, 'IsAutoStatistics') = 0
     AND INDEXPROPERTY (id, name, 'IsHypothetical'  ) = 0
     AND INDEXPROPERTY (id, name, 'IsStatistics'    ) = 0
     AND INDEXPROPERTY (id, name, 'IsFulltextKey'   ) = 0
     AND (indid between 2 and 250 OR (indid = 1 AND OBJECTPROPERTY(id, 'IsView') = 1))
     AND (STATS_DATE(id, indid) IS NULL OR STATS_DATE(id, indid) < DATEADD(m, -1, GETDATE()))
ORDER BY CONVERT (char(6), STATS_DATE(id, indid),112), [��� (��)]