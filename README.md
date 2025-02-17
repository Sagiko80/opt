$files = @(
    "C:\Path\To\File1.xlsx",
    "C:\Path\To\File2.xlsx",
    "C:\Path\To\File3.xlsx"
)

$allExist = $true

foreach ($file in $files) {
    Write-Output "Checking: $file"  
    if (!(Test-Path -Path "$file")) {
        Write-Output "File not found: $file"
        $allExist = $false
        break
    }
}

if ($allExist) {
    Write-Output "All files found. Triggering SQL Server job."

    # Define SQL Server details
    $sqlInstance = "YourSQLServerInstance"  # Replace with your actual SQL Server instance name
    $jobName = "YourTargetJob"  # Replace with the actual job name

    # Execute the SQL job
    try {
        Invoke-Sqlcmd -ServerInstance $sqlInstance -Query "EXEC msdb.dbo.sp_start_job @job_name = N'$jobName'"
        Write-Output "Job '$jobName' started successfully."
    } catch {
        Write-Output "Error starting SQL Server job: $_"
    }
} else {
    Write-Output "Some files are missing. Job not triggered."
}