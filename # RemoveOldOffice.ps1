# Target Office version to retain
$targetOfficeVersion = [version]"16.0.18129.20030"

# Log file path
$logFile = "C:\Windows\Temp\OfficeUninstallLog.txt"
function Log-Message {
    param ([string]$message)
    Add-Content -Path $logFile -Value "$(Get-Date): $message"
}

Log-Message "Starting Office detection and removal script."

# Function to parse version strings into [version] objects
function Parse-Version($versionString) {
    try {
        return [version]$versionString
    } catch {
        return $null
    }
}

# Query traditional MSI Office installations from registry
$uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$installedPrograms = Get-ChildItem -Path $uninstallKey | ForEach-Object {
    $programName = $_.GetValue("DisplayName")
    $programVersion = $_.GetValue("DisplayVersion")
    $uninstallString = $_.GetValue("UninstallString")
    
    if ($programName -and ($programName -match "Microsoft Office" -or $programName -match "Microsoft 365")) {
        [PSCustomObject]@{
            Name = $programName
            Version = Parse-Version $programVersion
            UninstallString = $uninstallString
        }
    }
} | Where-Object { $_ }

# Query Click-to-Run Office installations
$clickToRunKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
if (Test-Path $clickToRunKey) {
    $clickToRunVersion = Get-ItemProperty -Path $clickToRunKey -Name "VersionToReport" -ErrorAction SilentlyContinue
    if ($clickToRunVersion) {
        $installedPrograms += [PSCustomObject]@{
            Name = "Microsoft Office (Click-to-Run)"
            Version = Parse-Version $clickToRunVersion.VersionToReport
            UninstallString = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" + 
                              " /update user displaylevel=false forceappshutdown=true"
        }
    }
}

if ($installedPrograms) {
    Log-Message "Installed Office programs detected:"
    $installedPrograms | ForEach-Object {
        Log-Message "Name: $($_.Name), Version: $($_.Version)"
    }

    # Filter programs older than the target version
    $programsToRemove = $installedPrograms | Where-Object {
        $_.Version -and $_.Version -lt $targetOfficeVersion
    }

    if ($programsToRemove) {
        foreach ($program in $programsToRemove) {
            try {
                Log-Message "Uninstalling $($program.Name)..."
                if ($program.UninstallString) {
                    Start-Process "cmd.exe" -ArgumentList "/c $($program.UninstallString)" -Wait -NoNewWindow
                    Log-Message "$($program.Name) has been removed successfully."
                } else {
                    Log-Message "Uninstall command not found for $($program.Name)."
                }
            } catch {
                Log-Message "Failed to remove $($program.Name): $_"
            }
        }
    } else {
        Log-Message "No older versions of Office detected. No action required."
    }
} else {
    Log-Message "No installed versions of Microsoft Office detected."
}

Log-Message "Script execution complete."
