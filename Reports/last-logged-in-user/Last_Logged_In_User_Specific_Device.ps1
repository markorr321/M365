# Connect to Microsoft Graph (if not already connected) with NoWelcome parameter
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "User.Read.All", "AuditLog.Read.All" -NoWelcome

# Prompt user for the device name
$deviceName = Read-Host "Enter the device name"

# Get the Managed Device ID from Device Name
$device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" | Select-Object -ExpandProperty Id

# Check if a device was found
if ($device) {
    # Define the Graph API Endpoint for the Managed Device
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$device"

    # Invoke the Graph API Request
    $response = Invoke-MgGraphRequest -Uri $uri -Method GET

    # Check if usersLoggedOn contains data
    if ($response.usersLoggedOn -ne $null -and $response.usersLoggedOn.Count -gt 0) {
        # Get the last logged-in user (latest logon time)
        $lastUser = $response.usersLoggedOn | Sort-Object lastLogOnDateTime -Descending | Select-Object -First 1

        # Get User Details from Azure AD
        $userDetails = Get-MgUser -UserId $lastUser.userId -ErrorAction SilentlyContinue

        # Get Last Sign-In Info from Entra ID for accuracy
        $signInLogs = Get-MgAuditLogSignIn -Filter "userId eq '$($lastUser.userId)'" -Top 1 -Sort "createdDateTime DESC" -ErrorAction SilentlyContinue

        # Convert Sign-in Time to Local Time
        $lastSignInLocalTime = if ($signInLogs) { 
            [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]$signInLogs.CreatedDateTime, "UTC", [System.TimeZoneInfo]::Local.Id)
        } else {
            "No Recent Sign-ins Found"
        }

        # Store the formatted data
        $result = [PSCustomObject]@{
            DeviceName       = $deviceName
            DisplayName      = $userDetails.DisplayName
            "Email Address"  = $userDetails.UserPrincipalName
            LastLogOnDateTime = $lastSignInLocalTime  # Now pulling from Entra ID for better accuracy
        }

        # Display result in a table
        $result | Format-Table -AutoSize
    } else {
        Write-Host "No users logged on for device '$deviceName'." -ForegroundColor Yellow
    }
} else {
    Write-Host "Device '$deviceName' not found in Intune." -ForegroundColor Red
}
