Set-ExecutionPolicy Unrestricted -Force

# Function to uninstall applications by name
function Uninstall-ApplicationsByName {
    param (
        [string]$AppName,
        [string]$ActivityName
    )

    # Retrieve uninstall strings for the specified application
    $UninstallStrings = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where {$_.DisplayName -like "*$AppName*"} | Select-Object -ExpandProperty UninstallString)

    # Check if any uninstall strings are found
    if (-not $UninstallStrings) {
        Write-Host "No $AppName installations found." -ForegroundColor Yellow
        return
    }

    # Iterate through each uninstall string and execute the uninstall
    ForEach ($UninstallString in $UninstallStrings) {
        $UninstallEXE = ($UninstallString -split '"')[1]
        $UninstallArg = ($UninstallString -split '"')[2] + " DisplayLevel=False"

        # Start the uninstall process
        Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
    }

    # Display completion message
    Write-Host "$ActivityName completed." -ForegroundColor Green
}

# Step 1: Uninstall Microsoft 365
Uninstall-ApplicationsByName -AppName "Microsoft 365" -ActivityName "Uninstalling Microsoft 365"

# Step 2: Uninstall OneNote
Uninstall-ApplicationsByName -AppName "OneNote" -ActivityName "Uninstalling OneNote"
