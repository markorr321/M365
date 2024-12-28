# Set execution policy to bypass
Set-ExecutionPolicy Bypass -Scope Process -Force

# Connect to Azure AD
Connect-AzureAD

# Import CSV file
$CSVrecords = Import-Csv C:\Users\mark.orr\Downloads\titleupdate.csv -Delimiter "," 

# Arrays to track skipped and failed users
$SkippedUsers = @()
$FailedUsers = @()

# Loop through each record in the CSV
foreach ($CSVrecord in $CSVrecords) {
    $upn = $CSVrecord.UserPrincipalName
    
    # Use -Filter to get the user directly, more efficient than Where-Object
    try {
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$upn'"
    } catch {
        Write-Warning "Failed to retrieve user: $upn"
        $SkippedUsers += $upn
        continue
    }
    
    if ($user) {
        try {
            # Prepare parameters for update
            $updateParams = @{}
            
            if ($CSVrecord.jobTitle) {
                $updateParams["JobTitle"] = $CSVrecord.jobTitle
            }
            
            if ($CSVrecord.mobile) {
                $updateParams["Mobile"] = $CSVrecord.mobile
            }

            # If there are fields to update, proceed
            if ($updateParams.Count -gt 0) {
                Set-AzureADUser -ObjectId $user.ObjectId @updateParams
                Write-Output "Successfully updated user: $upn"
            } else {
                Write-Warning "No updates for user: $upn"
            }
        } catch {
            $FailedUsers += $upn
            Write-Warning "$upn user found, but FAILED to update."
        }
    } else {
        Write-Warning "$upn not found, skipped"
        $SkippedUsers += $upn
    }
}

# Output skipped and failed users
if ($SkippedUsers.Count -gt 0) {
    Write-Output "The following users were skipped:"
    $SkippedUsers | ForEach-Object { Write-Output $_ }
}

if ($FailedUsers.Count -gt 0) {
    Write-Output "The following users failed to update:"
    $FailedUsers | ForEach-Object { Write-Output $_ }
}
