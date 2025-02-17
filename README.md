$files = @(
    "C:\Path\To\File1.xlsx",
    "C:\Path\To\File2.xlsx",
    "C:\Path\To\File3.xlsx"
)

$allExist = $true

foreach ($file in $files) {
    Write-Output "Checking: $file"  # Debugging line
    if (!(Test-Path "$file")) {
        Write-Output "File not found: $file"  # Debugging line
        $allExist = $false
        break
    }
}

if ($allExist) {
    Write-Output "All files found. Triggering SQL Job."
    $sqlInstance = "YourSQLServerInstance" 
    $jobName = "YourTargetJob"

    $sql = "EXEC msdb.dbo.sp_start_job @job_name = '$jobName'"
    Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $sql
} else {
    Write-Output "Some files are missing. Job not triggered."
}