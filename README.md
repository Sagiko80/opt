SELECT 
    j.name AS JobName, 
    s.step_name AS StepName,
    s.command AS SSISPackagePath,
    h.run_date, 
    h.run_time, 
    h.run_duration, 
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
LEFT JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id AND s.step_id = h.step_id
WHERE s.subsystem = 'SSIS';