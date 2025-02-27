# Description:
# This PowerShell script connects to Microsoft Graph and retrieves a list of active users 
# who have assigned licenses but do not have Microsoft Authenticator configured.
#
# The script performs the following steps:
# 
# 1. **Connects to Microsoft Graph** if not already connected, using the required scopes.
# 2. **Retrieves all active users** with assigned licenses from the tenant.
# 3. **Checks each user's authentication methods** to determine if Microsoft Authenticator is configured.
# 4. **Filters users who do not have Microsoft Authenticator** and adds them to a report.
# 5. **Exports the results to a CSV file** for further review.
#
# Output:
# - Console messages indicating the number of users processed and whether they have Microsoft Authenticator.
# - A CSV file listing users without Microsoft Authenticator saved as:
#   "ActiveUsers_Without_Authenticator.csv" in the script's directory.
#
# Requirements:
# - Microsoft Graph PowerShell SDK (`Connect-MgGraph` module).
# - Appropriate permissions: "User.Read.All", "UserAuthenticationMethod.Read.All", "Directory.Read.All".
# - Execution Policy set to allow running PowerShell scripts.
#
# Limitations:
# - If running in a large tenant, performance may be impacted due to API rate limits.
# - Users must have sufficient privileges to retrieve authentication method details.
#
# Author: [Your Name]
# Last Modified: [Date]
# ------------------------------------------------------------------------------------------

# Connect to Microsoft Graph if not already connected
$connection = Get-MgUser -Top 1 -ErrorAction SilentlyContinue
if (-not $connection) {
    Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All", "Directory.Read.All"
}

# Retrieve all active users with assigned licenses
Write-Output "Retrieving active users with licenses..."
$users = Get-MgUser -All -Select DisplayName, UserPrincipalName, Id, AccountEnabled, AssignedLicenses | Where-Object {
    $_.AccountEnabled -eq $true -and $_.AssignedLicenses.Count -gt 0
}

$totalUsers = $users.Count
if ($totalUsers -eq 0) {
    Write-Output "No active users with licenses found."
    exit
}

Write-Output "Found $totalUsers active users with licenses. Processing authentication methods..."

# Define Microsoft Authenticator identifiers
$authenticatorMethodId = "3179e48a-750b-4051-897c-87b9720928f7"

# Filter users without Microsoft Authenticator
$usersWithoutAuthenticator = @()
foreach ($user in $users) {
    $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id
    
    if ($authMethods) {
        # Extract @odata.type from AdditionalProperties properly
        $methodTypes = @($authMethods | ForEach-Object { $_.AdditionalProperties["@odata.type"] })
        Write-Output "Checking user: $($user.DisplayName) - Auth Methods: $($methodTypes -join ', ')"
        
        # Normalize @odata.type values to clean strings
        $methodTypesCleaned = ($methodTypes -join " ").ToLower()
        
        # Check if Microsoft Authenticator is present
        if ($methodTypesCleaned -match "microsoftauthenticator" -or $authMethods.Id -contains $authenticatorMethodId) {
            Write-Output "User $($user.DisplayName) HAS Microsoft Authenticator. Skipping."
        } else {
            Write-Output "User $($user.DisplayName) does NOT have Microsoft Authenticator. Adding to report."
            $usersWithoutAuthenticator += $user
        }
    } else {
        Write-Output "No authentication methods found for user: $($user.DisplayName). Adding to report."
        $usersWithoutAuthenticator += $user
    }
}

$totalFilteredUsers = $usersWithoutAuthenticator.Count
Write-Output "Found $totalFilteredUsers users who do NOT have Microsoft Authenticator."

# Determine export path
$exportDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$csvPath = "$exportDir\ActiveUsers_Without_Authenticator.csv"

# Export results to CSV
$usersWithoutAuthenticator | Select-Object DisplayName, UserPrincipalName | Export-Csv -Path $csvPath -NoTypeInformation
Write-Output "Results exported to $csvPath"
