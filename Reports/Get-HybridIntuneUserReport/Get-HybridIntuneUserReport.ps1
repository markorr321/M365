# Description:
# This PowerShell script connects to Microsoft Graph and retrieves a list of Hybrid Azure AD Joined devices 
# that are managed by Microsoft Intune. It performs the following tasks:
# 
# 1. Connects to Microsoft Graph using the necessary permissions.
# 2. Retrieves all devices from Entra ID.
# 3. Filters the devices to find those that are Hybrid Azure AD Joined and managed by Intune.
# 4. Retrieves all devices currently in Intune.
# 5. Compares the Hybrid Azure AD Joined devices with those still present in Intune.
# 6. Gathers additional details such as:
#    - Last logged-in user
#    - Last log-on time
#    - Primary user
#    - Last check-in time in Intune
# 7. Displays the final list in the console.
# 8. Exports the results to a CSV file for further analysis.
#
# Output:
# - Console output showing the count of Hybrid Azure AD Joined devices managed by Intune.
# - A formatted table displaying device details.
# - A CSV file containing the collected data is saved at:
#   "C:\Powershell\Hybrid Managed Intune Devices\HybridIntuneUserReport.csv"
#
# Requirements:
# - Microsoft Graph PowerShell SDK (Connect-MgGraph)
# - Appropriate permissions: "Device.Read.All", "DeviceManagementManagedDevices.Read.All", "User.Read.All", "AuditLog.Read.All"
# - Execution Policy allowing PowerShell scripts to run.
#
# Author: [Your Name]
# Last Modified: [Date]
# ------------------------------------------------------------------------------------------

# Connect to Microsoft Graph
Connect-MgGraph -NoWelcome -Scopes "Device.Read.All", "DeviceManagementManagedDevices.Read.All", "User.Read.All", "AuditLog.Read.All"

# Retrieve all devices from Entra ID
$devices = Get-MgDevice -All

# Filter for Hybrid Azure AD Joined devices managed by Intune
$hybridIntuneDevices = $devices | Where-Object { 
    ($_.TrustType -eq "ServerAd" -or $_.DeviceTrustType -eq "ServerAd") -and
    $_.ManagementType -eq "MDM"
}

Write-Host "Total Hybrid Azure AD Joined Devices Managed by Intune (From Entra ID): $($hybridIntuneDevices.Count)" -ForegroundColor Green

# Retrieve all devices currently in Intune
$intuneDevices = Get-MgDeviceManagementManagedDevice -All

# Compare device lists using DisplayName instead of ID
$stillInIntune = $hybridIntuneDevices | Where-Object { $_.DisplayName -in $intuneDevices.DeviceName }

Write-Host "Total Hybrid Azure AD Joined Devices Still in Intune: $($stillInIntune.Count)" -ForegroundColor Cyan

# Retrieve last logged-in user, primary user, and last check-in time
$results = @()
$totalDevices = $stillInIntune.Count
$counter = 0

foreach ($device in $stillInIntune) {
    $counter++
    $progressPercent = ($counter / $totalDevices) * 100

    # Show progress
    Write-Progress -Activity "Retrieving device data..." -Status "Processing $counter of $totalDevices - $($device.DisplayName)" -PercentComplete $progressPercent

    # Retrieve the corresponding Intune device record
    $intuneDevice = $intuneDevices | Where-Object { $_.DeviceName -eq $device.DisplayName }
    
    # Initialize variables
    $lastLoggedInUser = "No User Found"
    $lastLogOnTime = "N/A"
    $primaryUser = "No Primary User"

    if ($intuneDevice) {
        # Get Managed Device details using Microsoft Graph API
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($intuneDevice.Id)"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET

        # Check if usersLoggedOn contains data (Last Logged-in User)
        if ($response.usersLoggedOn -ne $null -and $response.usersLoggedOn.Count -gt 0) {
            # Get the most recent logged-in user
            $lastUser = $response.usersLoggedOn | Sort-Object lastLogOnDateTime -Descending | Select-Object -First 1
            $userDetails = Get-MgUser -UserId $lastUser.userId -ErrorAction SilentlyContinue
            $lastLoggedInUser = $userDetails.UserPrincipalName
            $lastLogOnTime = $lastUser.lastLogOnDateTime
        }

        # Retrieve the Primary User from Intune
        if ($intuneDevice.UserPrincipalName) {
            $primaryUser = $intuneDevice.UserPrincipalName
        }
    }

    # Store results
    $results += [PSCustomObject]@{
        DeviceName        = $device.DisplayName
        DeviceId          = $device.Id
        TrustType         = $device.TrustType
        ManagementType    = $device.ManagementType
        LastLoggedInUser  = $lastLoggedInUser
        LastLogOnTime     = $lastLogOnTime
        PrimaryUser       = $primaryUser
        LastCheckIn       = $intuneDevice.LastSyncDateTime
    }
}

# Clear progress bar
Write-Progress -Activity "Retrieving device data..." -Completed

# Display results in a console table
Write-Host "`nFinal List of Hybrid Azure AD Joined Devices with Last Logged-in User, Primary User, and Check-in Time:" -ForegroundColor Yellow
$results | Format-Table DeviceName, LastLoggedInUser, LastLogOnTime, PrimaryUser, LastCheckIn -AutoSize

# Export results to CSV
$csvPath = "C:\Powershell\Hybrid Managed Intune Devices\HybridIntuneUserReport.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "`nResults exported to: $csvPath" -ForegroundColor Green
