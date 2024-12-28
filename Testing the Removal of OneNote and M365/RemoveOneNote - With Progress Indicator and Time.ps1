Set-ExecutionPolicy Unrestricted -Force

# Start the timer
$StartTime = Get-Date

# Retrieve uninstall strings for OneNote
$OneNoteUninstallStrings = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where {$_.DisplayName -like "*OneNote*"} | Select-Object -ExpandProperty UninstallString)

# Check if any uninstall strings are found
if (-not $OneNoteUninstallStrings) {
    Write-Host "No OneNote installations found." -ForegroundColor Yellow
    return
}

# Initialize progress variables
$totalCount = $OneNoteUninstallStrings.Count
$currentCount = 0

# Iterate through each uninstall string and execute the uninstall
ForEach ($UninstallString in $OneNoteUninstallStrings) {
    $currentCount++
    $progressPercent = [math]::Round(($currentCount / $totalCount) * 100, 2)

    $UninstallEXE = ($UninstallString -split '"')[1]
    $UninstallArg = ($UninstallString -split '"')[2] + " DisplayLevel=False"

    # Display progress bar
    Write-Progress -Activity "Uninstalling OneNote" -Status "Processing $currentCount of $totalCount" -PercentComplete $progressPercent

    # Start the uninstall process
    Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
}

# Stop the timer and calculate elapsed time
$EndTime = Get-Date
$ElapsedTime = $EndTime - $StartTime

# Display completion message with elapsed time
Write-Host "OneNote uninstallation completed. Total time taken: $($ElapsedTime.ToString())" -ForegroundColor Green
