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
    COALESCE(
        (SELECT TOP 1 em.message 
         FROM SSISDB.internal.event_messages em 
         WHERE em.operation_id = e.execution_id 
         AND em.event_name IN ('OnError', 'OnTaskFailed') 
         ORDER BY em.event_message_id DESC), 
        'No error message found'
    ) AS SSISErrorMessage
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id AND h.step_id = s.step_id
LEFT JOIN SSISDB.internal.executions e ON CAST(h.instance_id AS BIGINT) = e.execution_id  -- Match SSIS execution
WHERE h.run_status = 0 -- Only failed steps
AND h.run_date >= CONVERT(INT, FORMAT(DATEADD(DAY, -3, GETDATE()), 'yyyyMMdd'))
AND s.command LIKE '%dtexec%' -- Ensure step executes an SSIS package
ORDER BY ErrorTime DESC;