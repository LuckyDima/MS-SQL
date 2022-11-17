


-- Quick test for memory
-- http://bit.ly/LkT05M
;WITH RingBufferXML
AS(SELECT CAST(Record AS XML) AS RBR FROM sys .dm_os_ring_buffers
   WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
  )
SELECT DISTINCT 'Issues' =
          CASE
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 2 
                    THEN 'Not enoght memory for system'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
                    THEN 'Not enoght virtual memory for system' 
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 0 
                    THEN'Not enoght memory for queries'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 4 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 4
                    THEN 'Not enoght virtual memory for system and queries'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
                    THEN 'Not enoght virtual memory for system and usual memmory for queries'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 2 
                    THEN 'Not enoght physical memory for system and queries'
         END
FROM        RingBufferXML
CROSS APPLY RingBufferXML.RBR.nodes ('Record') Record (XMLRecord)
WHERE       XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') IN (0,2,4) AND
            XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') IN (0,2,4) AND
            XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') +
            XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') > 0
