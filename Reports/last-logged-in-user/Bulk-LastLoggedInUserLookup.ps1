# Ensure required modules are imported
$requiredModules = @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Reports',
    'Microsoft.Graph.DeviceManagement'
)
foreach ($mod in $requiredModules) {
    if (-not (Get-Module -Name $mod)) {
        Import-Module $mod -Force -ErrorAction Stop
    }
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "User.Read.All", "AuditLog.Read.All" -NoWelcome

# Define and validate input CSV file path
$inputFile = "C:\Users\MarkOrr\Downloads\Device_List.csv"
if (-not (Test-Path $inputFile)) {
    Write-Error "❌ Input file not found: $inputFile"
    exit
}

# Import device list from CSV (expects column "DeviceName")
$devices = Import-Csv $inputFile

# Create a list to hold results
$results = @()

# Loop through devices with progress
$i = 0
$total = $devices.Count
foreach ($entry in $devices) {
    $i++
    Write-Progress -Activity "Getting last logged-in user" `
                   -Status ("{0} of {1}: {2}" -f $i, $total, $entry.DeviceName) `
                   -PercentComplete (($i / $total) * 100)

    $deviceName = $entry.DeviceName
    $deviceId = (Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" -ErrorAction SilentlyContinue).Id

    if ($deviceId) {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET

        if ($response.usersLoggedOn -ne $null -and $response.usersLoggedOn.Count -gt 0) {
            $lastUser = $response.usersLoggedOn | Sort-Object lastLogOnDateTime -Descending | Select-Object -First 1
            $userDetails = Get-MgUser -UserId $lastUser.userId -ErrorAction SilentlyContinue
            $signInLogs = Get-MgAuditLogSignIn -Filter "userId eq '$($lastUser.userId)'" -Top 1 -Sort "createdDateTime DESC" -ErrorAction SilentlyContinue

            $lastSignInLocalTime = if ($signInLogs) {
                [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]$signInLogs.CreatedDateTime, "UTC", [System.TimeZoneInfo]::Local.Id)
            } else {
                "No Recent Sign-ins Found"
            }

            $record = [PSCustomObject]@{
                DeviceName        = $deviceName
                DisplayName       = $userDetails.DisplayName
                "Email Address"   = $userDetails.UserPrincipalName
                LastLogOnDateTime = $lastSignInLocalTime
            }

            Write-Host "✔️  $deviceName | $($userDetails.DisplayName) | $($userDetails.UserPrincipalName) | $lastSignInLocalTime" -ForegroundColor Red
            $results += $record
        } else {
            $record = [PSCustomObject]@{
                DeviceName        = $deviceName
                DisplayName       = ""
                "Email Address"   = ""
                LastLogOnDateTime = "No users logged on"
            }

            Write-Host "⚠️  $deviceName | No users logged on" -ForegroundColor Red
            $results += $record
        }
    } else {
        $record = [PSCustomObject]@{
            DeviceName        = $deviceName
            DisplayName       = ""
            "Email Address"   = ""
            LastLogOnDateTime = "Device not found"
        }

        Write-Host "❌ $deviceName | Device not found" -ForegroundColor Red
        $results += $record
    }

    # Optional: Pause to reduce throttling risk
    Start-Sleep -Milliseconds 300
}

# Output to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "C:\Powershell\LastLoggedInResults_$timestamp.csv"
$results | Export-Csv $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "`n✅ Finished! Results exported to:`n$outputFile" -ForegroundColor Green
