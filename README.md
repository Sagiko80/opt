SELECT 
    o.execution_id,
    o.package_name,
    o.start_time,
    o.end_time,
    om.message_source_name,
    om.message
FROM SSISDB.internal.operations o
JOIN SSISDB.internal.operation_messages om 
    ON o.execution_id = om.operation_id
WHERE om.message_type = 4  -- סוג 4 מציין שגיאה
ORDER BY o.start_time DESC;