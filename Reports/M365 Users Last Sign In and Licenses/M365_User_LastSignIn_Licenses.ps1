Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All"

# Import CSV (Assumes CSV has a column 'UserPrincipalName')
$users = Import-Csv "C:\Users\MarkOrr\Downloads\sample_m365_users.csv"

# Create an empty array to store results
$results = @()
$totalUsers = $users.Count
$counter = 0

foreach ($user in $users) {
    $counter++
    $progressPercent = ($counter / $totalUsers) * 100
    Write-Progress -Activity "Processing Users" -Status "Checking $($user.UserPrincipalName)" -PercentComplete $progressPercent

    $upn = $user.UserPrincipalName
    Write-Host "Checking user: $upn"  # Debugging output

    # Get User ObjectId first
    try {
        $userObject = Get-MgUser -Filter "UserPrincipalName eq '$upn'" -Property Id, SignInActivity -ErrorAction Stop
        $objectId = $userObject.Id
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host ("Error retrieving ObjectId for " + $upn + ": " + $errorMsg)
        $objectId = $null
    }

    # Get the most recent sign-in
    if ($objectId) {
        try {
            $lastSignIn = if ($userObject.SignInActivity.LastSignInDateTime) { 
                $userObject.SignInActivity.LastSignInDateTime 
            } else { "No Sign-in Data" }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host ("Error retrieving sign-in for " + $upn + ": " + $errorMsg)
            $lastSignIn = "Error retrieving data"
        }
    } else {
        $lastSignIn = "User Not Found"
    }

    # Get license information (Corrected)
    if ($objectId) {
        try {
            $licenses = Get-MgUserLicenseDetail -UserId $objectId | Select-Object -ExpandProperty SkuPartNumber
            
            # Convert license list to a comma-separated string
            $licenseNames = if ($licenses) { $licenses -join ", " } else { "No License Assigned" }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host ("Error retrieving license for " + $upn + ": " + $errorMsg)
            $licenseNames = "Error retrieving data"
        }
    } else {
        $licenseNames = "User Not Found"
    }

    # Store results
    $results += [PSCustomObject]@{
        UserPrincipalName = $upn
        LastSignIn = $lastSignIn
        LicenseType = $licenseNames
    }
}

# Export results to CSV
$results | Export-Csv "C:\Powershell\LastSignInAndLicenses.csv" -NoTypeInformation

# Clear progress indicator
Write-Progress -Activity "Processing Users" -Completed

# Display Results
$results | Format-Table -AutoSize

Write-Host "Script completed! Results saved to C:\Powershell\LastSignInAndLicenses.csv"
