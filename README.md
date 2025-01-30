SELECT 
    j.name AS JobName,
    h.step_name,
    CONVERT(DATETIME, 
        CAST(h.run_date AS CHAR(8)) + ' ' + 
        STUFF(STUFF(RIGHT('000000' + CAST(h.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
    ) AS RunDateTime,
    h.run_status,
    ISNULL(h.message, 'No error details found') AS ErrorMessage
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0  -- Only failed runs
ORDER BY RunDateTime DESC;