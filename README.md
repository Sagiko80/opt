SELECT 
    j.name AS JobName,
    h.step_id AS StepID,
    h.step_name AS StepName,
    CONVERT(DATETIME, 
        CONCAT(LEFT(h.run_date, 4), '-', SUBSTRING(h.run_date, 5, 2), '-', RIGHT(h.run_date, 2), ' ', 
               LEFT(FORMAT(h.run_time, '000000'), 2), ':', 
               SUBSTRING(FORMAT(h.run_time, '000000'), 3, 2), ':', 
               RIGHT(FORMAT(h.run_time, '000000'), 2))) AS ErrorTime,
    e.package_name AS SSISPackage,
    em.message AS SSISErrorMessage
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
LEFT JOIN SSISDB.internal.executions e ON j.name = e.job_name
LEFT JOIN SSISDB.internal.event_messages em ON e.execution_id = em.operation_id AND em.event_name = 'OnError'
WHERE h.run_status = 0 -- רק כשלונות
AND h.run_date >= CONVERT(INT, FORMAT(DATEADD(DAY, -3, GETDATE()), 'yyyyMMdd'))
ORDER BY ErrorTime DESC;
