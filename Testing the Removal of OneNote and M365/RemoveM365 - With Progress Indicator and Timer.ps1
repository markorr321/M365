Set-ExecutionPolicy Unrestricted -Force

# Start the timer
$StartTime = Get-Date

# Retrieve uninstall strings for Microsoft 365
$OfficeUninstallStrings = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where {$_.DisplayName -like "*Microsoft 365*"} | Select-Object -ExpandProperty UninstallString)

# Check if any uninstall strings are found
if (-not $OfficeUninstallStrings) {
    Write-Host "No Microsoft 365 installations found." -ForegroundColor Yellow
    return
}

# Initialize progress variables
$totalCount = $OfficeUninstallStrings.Count
$currentCount = 0

# Iterate through each uninstall string and execute the uninstall
ForEach ($UninstallString in $OfficeUninstallStrings) {
    $currentCount++
    $progressPercent = [math]::Round(($currentCount / $totalCount) * 100, 2)

    $UninstallEXE = ($UninstallString -split '"')[1]
    $UninstallArg = ($UninstallString -split '"')[2] + " DisplayLevel=False"

    # Display progress bar
    Write-Progress -Activity "Uninstalling Microsoft 365" -Status "Processing $currentCount of $totalCount" -PercentComplete $progressPercent

    # Start the uninstall process
    Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
}

# Stop the timer and calculate elapsed time
$EndTime = Get-Date
$ElapsedTime = $EndTime - $StartTime

# Display completion message with elapsed time
Write-Host "Uninstallation completed. Total time taken: $($ElapsedTime.ToString())" -ForegroundColor Green
