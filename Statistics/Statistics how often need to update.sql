SELECT

ssi.id

, object_name(ssi.id) AS tblName

, stats_date(ssi.id,ssi.indid) as StatsDate

, ssi.indid

, ssi.rowcnt

, ssi.rowmodctr

, cast(ssi.rowmodctr as decimal)/cast(ssi.rowcnt as decimal) as ChangedRowsRatio

, ss.no_recompute AS IsAutoUpdateOff

FROM sys.sysindexes ssi left join sys.stats ss

ON ssi.name = ss.name

WHERE ssi.id > 100

AND indid > 0

AND ssi.rowcnt > 500

AND (ssi.rowmodctr/ssi.rowcnt) > 0.15 -- enter a relevant number

ORDER BY 3 