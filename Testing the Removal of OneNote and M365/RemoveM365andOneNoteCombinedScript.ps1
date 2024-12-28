Set-ExecutionPolicy Unrestricted -Force

# Function to uninstall applications by name
function Uninstall-ApplicationsByName {
    param (
        [string]$AppName,
        [string]$ActivityName
    )
    
    # Start the timer
    $StartTime = Get-Date

    # Retrieve uninstall strings for the specified application
    $UninstallStrings = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where {$_.DisplayName -like "*$AppName*"} | Select-Object -ExpandProperty UninstallString)

    # Check if any uninstall strings are found
    if (-not $UninstallStrings) {
        Write-Host "No $AppName installations found." -ForegroundColor Yellow
        return
    }

    # Initialize progress variables
    $totalCount = $UninstallStrings.Count
    $currentCount = 0

    # Iterate through each uninstall string and execute the uninstall
    ForEach ($UninstallString in $UninstallStrings) {
        $currentCount++
        $progressPercent = [math]::Round(($currentCount / $totalCount) * 100, 2)

        $UninstallEXE = ($UninstallString -split '"')[1]
        $UninstallArg = ($UninstallString -split '"')[2] + " DisplayLevel=False"

        # Display progress bar
        Write-Progress -Activity $ActivityName -Status "Processing $currentCount of $totalCount" -PercentComplete $progressPercent

        # Start the uninstall process
        Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
    }

    # Stop the timer and calculate elapsed time
    $EndTime = Get-Date
    $ElapsedTime = $EndTime - $StartTime

    # Display completion message with elapsed time
    Write-Host "$ActivityName completed. Total time taken: $($ElapsedTime.ToString())" -ForegroundColor Green
}

# Step 1: Uninstall Microsoft 365
Uninstall-ApplicationsByName -AppName "Microsoft 365" -ActivityName "Uninstalling Microsoft 365"

# Step 2: Uninstall OneNote
Uninstall-ApplicationsByName -AppName "OneNote" -ActivityName "Uninstalling OneNote"
