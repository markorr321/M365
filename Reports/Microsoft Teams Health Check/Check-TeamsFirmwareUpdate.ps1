# Function to clean and format the device name
function Get-CleanDisplayName {
    param ($rawName)
    
    if ($rawName -match "(.+)_Android|(.+)_AOSP") {
        $cleanName = $matches[1] -replace "_", " "  # Replace underscores with spaces
        return (Get-Culture).TextInfo.ToTitleCase($cleanName.ToLower()) # Capitalize words
    }
    return $rawName  # If no match, return original name
}

# Connect to Microsoft Graph without the welcome message
Connect-MgGraph -Scopes "TeamworkDevice.Read.All", "DeviceManagementManagedDevices.Read.All" -NoWelcome

# Get all Teams devices (including Serial Number and Manufacturer)
$teamsDevices = Get-MgBetaTeamworkDevice | Select-Object Id, 
    @{Name="SerialNumber"; Expression={$_.HardwareDetail.SerialNumber}}, 
    @{Name="Model"; Expression={$_.HardwareDetail.Model}}, 
    @{Name="Manufacturer"; Expression={$_.HardwareDetail.Manufacturer}}, 
    DeviceType, HealthStatus

# Get all Intune devices (including Serial Number and OS Version)
$intuneDevices = Get-MgDeviceManagementManagedDevice | Select-Object Id, DeviceName, SerialNumber, OSVersion

# Check if devices were found
if ($teamsDevices.Count -eq 0) {
    Write-Host "No Teams devices found."
    exit
}

# Loop through each device and extract its properties
foreach ($device in $teamsDevices) {
    $deviceId = $device.Id
    $serialNumber = $device.SerialNumber

    # Try to match based on Serial Number
    $deviceName = ($intuneDevices | Where-Object { $_.SerialNumber -eq $serialNumber }).DeviceName
    if (-not $deviceName) { $deviceName = "Unknown Device" }
    
    # Clean up the device name
    $cleanDeviceName = Get-CleanDisplayName -rawName $deviceName

    # Try to get Software Version and Software Freshness from SoftwareUpdateHealth
    try {
        $deviceHealth = Get-MgBetaTeamworkDeviceHealth -TeamworkDeviceId $deviceId
        $updateHealth = $deviceHealth.SoftwareUpdateHealth

        # Extract Software Versions
        $deviceSoftwareVersion = $updateHealth.FirmwareSoftwareUpdateStatus.CurrentVersion
        if (-not $deviceSoftwareVersion) { 
            $deviceSoftwareVersion = $updateHealth.OperatingSystemSoftwareUpdateStatus.CurrentVersion 
        }
        if (-not $deviceSoftwareVersion) { 
            $deviceSoftwareVersion = $updateHealth.TeamsClientSoftwareUpdateStatus.CurrentVersion 
        }

        # Extract Software Freshness
        $softwareFreshness = $updateHealth.FirmwareSoftwareUpdateStatus.SoftwareFreshness
        if (-not $softwareFreshness) { 
            $softwareFreshness = $updateHealth.OperatingSystemSoftwareUpdateStatus.SoftwareFreshness 
        }
        if (-not $softwareFreshness) { 
            $softwareFreshness = $updateHealth.TeamsClientSoftwareUpdateStatus.SoftwareFreshness 
        }

        # Determine update status based on Software Freshness
        if ($softwareFreshness -eq "latest") {
            $softwareUpdateStatus = "Up to Date"
        } elseif ($softwareFreshness -ne $null) {
            $softwareUpdateStatus = "Update Available"
        } else {
            $softwareUpdateStatus = "Unknown"
        }
    }
    catch {
        $deviceSoftwareVersion = "Unknown Version"
        $softwareUpdateStatus = "Unknown"
    }

    # Retrieve hardware details
    $deviceModel = if ($device.Model) { $device.Model } else { "Unknown Model" }
    $deviceManufacturer = if ($device.Manufacturer) { $device.Manufacturer } else { "Unknown Manufacturer" }
    $deviceType = if ($device.DeviceType) { $device.DeviceType } else { "Unknown Type" }
    $deviceHealthStatus = if ($device.HealthStatus) { $device.HealthStatus } else { "Unknown Health Status" }

    # Retrieve update status
    $updateStatus = Get-MgBetaTeamworkDeviceOperation -TeamworkDeviceId $deviceId | Where-Object { $_.Type -eq "softwareUpdate" }

    Write-Host "--------------------------------------"
    Write-Host "Device: $cleanDeviceName ($deviceId)"
    Write-Host "Model: $deviceModel"
    Write-Host "Manufacturer: $deviceManufacturer"
    Write-Host "Software Version: $deviceSoftwareVersion"
    Write-Host "Software Update Status: $softwareUpdateStatus"
    Write-Host "Device Type: $deviceType"
    Write-Host "Health Status: $deviceHealthStatus"

    if ($updateStatus) {
        Write-Host "Status: $($updateStatus.Status)"
        Write-Host "Scheduled Time: $($updateStatus.CreatedDateTime)"
    } else {
        Write-Host "No firmware update scheduled."
    }
}
