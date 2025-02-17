$files = @(
    "C:\Path\To\File1.xlsx",
    "C:\Path\To\File2.xlsx",
    "C:\Path\To\File3.xlsx"
)

$allExist = $true

foreach ($file in $files) {
    if (!(Test-Path $file)) {
        $allExist = $false
        break
    }
}

if ($allExist) {
    # Trigger SQL Server Job
    $sqlInstance = "YourSQLServerInstance" 
    $jobName = "YourTargetJob"

    $sql = "EXEC msdb.dbo.sp_start_job @job_name = '$jobName'"
    Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $sql
}