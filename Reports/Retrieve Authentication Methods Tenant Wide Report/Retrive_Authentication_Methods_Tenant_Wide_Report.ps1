# Connect to Microsoft Graph if not already connected
$connection = Get-MgUser -Top 1 -ErrorAction SilentlyContinue
if (-not $connection) {
    Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All", "Directory.Read.All"
}

# Retrieve all users in the tenant
Write-Output "Retrieving all users in the tenant..."
$users = Get-MgUser -All -Select DisplayName, UserPrincipalName, Id
$totalUsers = $users.Count

if ($totalUsers -eq 0) {
    Write-Output "No users found in the tenant."
    exit
}

Write-Output "Found $totalUsers users in the tenant. Processing authentication methods..."

# Define a mapping of known authentication method IDs to friendly names
$authMethodMap = @{
    "28c10230-6103-485e-b985-444c60001490" = "Password Authentication"
    "3179e48a-750b-4051-897c-87b9720928f7" = "Microsoft Authenticator App"
    "830ce3d0-a979-43e0-a8b9-05579b8592b8" = "Phone (SMS/Call)"
    "f8a15ff1-830e-4c6d-99f1-123eac201a01" = "Email Authentication"
    "dEDRZgU34DUdmAUUeQxo782xC71-dH-pdFPs44SFx3c1" = "FIDO2 Security Key"
    "3ddfcfc8-9383-446f-83cc-3ab9be4be18f" = "Email Authentication"  # FIXED: Correctly maps emailMethods-ID
}

# Define report file path
$reportFilePath = "Authentication_Methods_Report_Tenant.csv"

# Ensure the CSV file is created fresh without duplicate headers
if (Test-Path $reportFilePath) {
    Remove-Item $reportFilePath -Force
}

# Initialize the CSV file with headers
[PSCustomObject]@{
    UserDisplayName   = "UserDisplayName"
    UserPrincipalName = "UserPrincipalName"
    MethodName        = "MethodName"
} | Export-Csv -Path $reportFilePath -NoTypeInformation -Force

$userIndex = 0  # Track progress

# Iterate through each user
foreach ($user in $users) {
    $userIndex++
    Write-Progress -Activity "Processing Users" -Status "Processing $($user.DisplayName) ($userIndex of $totalUsers)" -PercentComplete (($userIndex / $totalUsers) * 100)

    $authMethods = $null

    # Retrieve authentication methods for the user
    try {
        $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction Stop
    } catch {
        Write-Output ("Failed to retrieve auth methods for {0}. Error: {1}" -f $user.UserPrincipalName, $_) | Out-File "error_log.txt" -Append
    }

    # Fetch Software OATH Token (TOTP) separately
    try {
        $softwareOathTokens = Get-MgUserAuthenticationSoftwareOathMethod -UserId $user.Id -ErrorAction SilentlyContinue
        if ($softwareOathTokens) {
            foreach ($oath in $softwareOathTokens) {
                $authMethodMap[$oath.Id] = "Software OATH Token (TOTP)"
            }
        }
    } catch {
        Write-Output ("Failed to retrieve Software OATH for {0}. Error: {1}" -f $user.UserPrincipalName, $_) | Out-File "error_log.txt" -Append
    }

    # Process authentication methods
    if ($authMethods.Count -gt 0) {
        foreach ($method in $authMethods) {
            $methodId = $method.Id
            $odataType = $method.AdditionalProperties['@odata.type']
            $methodName = $authMethodMap[$methodId]

            # Identify authentication methods dynamically
            if ($odataType -match "windowsHelloForBusiness") {
                $methodName = "Windows Hello for Business"
            }
            elseif ($odataType -match "passwordlessMicrosoftAuthenticator") {
                $methodName = "Passwordless Microsoft Authenticator"
            }
            elseif ($odataType -match "temporaryAccessPass") {
                $methodName = "Temporary Access Pass (TAP)"
            }
            elseif ($odataType -match "authenticatorLite") {
                $methodName = "Authenticator Lite (Outlook MFA)"
            }
            elseif ($odataType -match "phoneAuthenticationMethod") {
                $methodName = "Phone Authentication (SMS or Call)"
            }
            elseif ($odataType -match "microsoftAuthenticatorAuthenticationMethod") {
                $methodName = "Microsoft Authenticator App"
            }
            elseif (-not $methodName) {
                $methodName = "Unknown Method (ID: $methodId)"
            }

            # Remove device type from Microsoft Authenticator App entries
            if ($methodName -match "Microsoft Authenticator") {
                $methodName = "Microsoft Authenticator App"
            }

            # Write each record to the CSV as they are processed
            [PSCustomObject]@{
                UserDisplayName   = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                MethodName        = $methodName
            } | Export-Csv -Path $reportFilePath -NoTypeInformation -Append
        }
    } else {
        # Log users with no authentication methods
        [PSCustomObject]@{
            UserDisplayName   = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            MethodName        = "No Authentication Methods Found"
        } | Export-Csv -Path $reportFilePath -NoTypeInformation -Append
    }

    # Prevent Graph API Throttling
    if ($userIndex % 100 -eq 0) { Start-Sleep -Seconds 10 }
}

Write-Progress -Activity "Processing Users" -Status "Completed" -Completed
Write-Output "Report saved successfully!"
