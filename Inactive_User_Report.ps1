<#
.SYNOPSIS
    This script retrieves inactive internal users in Microsoft Entra ID (Azure AD) based on sign-in activity.

.DESCRIPTION
    - Connects to Microsoft Graph API and retrieves only internal users who have not signed in for the past 60 days.
    - Excludes external users.
    - Ensures only accounts with sign-in allowed (`AccountEnabled -eq $true`) are included.
    - Retrieves assigned licenses and lists them.
    - Displays progress and total user count while processing.
    - Exports the results to a CSV file named "InactiveUsersReport.csv".

.REQUIREMENTS
    - Microsoft Graph PowerShell module (`Microsoft.Graph.Authentication`).
    - Permissions: `User.Read.All`, `AuditLog.Read.All`, `Directory.Read.All`.
    - Reports Reader or higher role in Entra ID.

.OUTPUT
    - CSV file containing DisplayName, UserPrincipalName, LastSignInDate, and assigned licenses.

#>

# Connect to Microsoft Graph (ensure the user has required permissions)
Connect-MgGraph -NoWelcome -Scopes "User.Read.All", "AuditLog.Read.All", "Directory.Read.All"

# Define parameters
$DaysOfInactivity = 60  # Set inactivity threshold to 60 days
$OutputFile = "InactiveUsersReport.csv"
$CurrentDate = Get-Date
$InactivityDate = $CurrentDate.AddDays(-$DaysOfInactivity)

# Retrieve users from Microsoft Graph with filters
Write-Host "Retrieving inactive internal users (not signed in for 60 days) from Microsoft Graph..." -ForegroundColor Cyan
$Users = @()
$UserCounter = 0

Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, SignInActivity, AccountEnabled, UserType | ForEach-Object {
    # Ensure the user is internal, sign-in is allowed, and last sign-in is older than 60 days (or never signed in)
    if ($_.UserType -eq "Member" -and $_.AccountEnabled -eq $true -and ($_.SignInActivity.LastSignInDateTime -eq $null -or $_.SignInActivity.LastSignInDateTime -lt $InactivityDate)) {
        $Users += $_
        $UserCounter++
        Write-Host "`rUsers retrieved so far: $UserCounter" -NoNewline -ForegroundColor Yellow
    }
}

$TotalUsers = $Users.Count
Write-Host "`nTotal inactive internal users retrieved: $TotalUsers" -ForegroundColor Green

# Prepare output
$InactiveUsers = @()
$ProcessedUsers = 0
foreach ($User in $Users) {
    $ProcessedUsers++
    Write-Progress -Activity "Processing Inactive Users" -Status "Processing $ProcessedUsers of $TotalUsers" -PercentComplete (($ProcessedUsers / $TotalUsers) * 100)
    
    $LastSignInDate = $User.SignInActivity.LastSignInDateTime

    # Get license info per user
    try {
        $UserLicenses = Get-MgUserLicenseDetail -UserId $User.Id -ErrorAction Stop
        $LicenseNames = if ($UserLicenses) { $UserLicenses.SkuPartNumber -join ", " } else { "No License" }
    } catch {
        $LicenseNames = "Error Retrieving License"
    }
    
    # Build report entry
    $InactiveUsers += [PSCustomObject]@{
        DisplayName      = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        LastSignInDate   = if ($LastSignInDate) { $LastSignInDate } else { "Never Signed In" }
        LicenseAssigned  = $LicenseNames
    }
}

# Export to CSV
Write-Host "Exporting results to CSV..." -ForegroundColor Cyan
$InactiveUsers | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "Report generated: $OutputFile" -ForegroundColor Green
