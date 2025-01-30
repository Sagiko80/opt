SELECT 
    j.name AS JobName,
    h.step_name,
    CONVERT(DATETIME, 
        CAST(h.run_date AS CHAR(8)) + ' ' + 
        STUFF(STUFF(RIGHT('000000' + CAST(h.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
    ) AS RunDateTime,
    h.run_status,
    ISNULL(js.last_run_outcome, -1) AS LastRunOutcome,
    ISNULL(js.last_run_date, 0) AS LastRunDate,
    ISNULL(js.last_run_time, 0) AS LastRunTime,
    ISNULL(js.output_message, 'No error details found') AS ErrorMessage
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js 
    ON h.job_id = js.job_id AND h.step_id = js.step_id
WHERE h.run_status = 0  -- Only failed runs
ORDER BY RunDateTime DESC;