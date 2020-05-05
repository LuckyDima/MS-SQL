dbcc show_statistics

https://msdn.microsoft.com/ru-ru/library/ms174384%28v=sql.120%29.aspx?f=255&MSPPError=-2147217396


В следующем примере показываются статистические данные, отображаемые для индекса AK_Address_rowguid ,таблица Person.Address до данных HISTOGRAM.

DBCC SHOW_STATISTICS ("Person.Address", AK_Address_rowguid) WITH HISTOGRAM;
GO
