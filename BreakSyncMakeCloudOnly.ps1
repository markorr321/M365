#Connect to MSolService
Connect-MsolService

#Check to see if you are in passwordhash or passthrough
(Get-MsolCompanyInformation).PasswordSynchronizationEnabled


#Check the directory SycStatus
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled

#Disable the directory Sync
Set-MsolDirSyncEnabled -EnableDirSync $false

#Verify the directory sync is disabled. This can also be checked in the GUI using the Azure AD Connect Tool.
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled

#Convert a synced user to a cloud only user.
Set-MsolUser -UserPrincipalName mark.orr@healthcareitleaders.com -ImmutableId "$null"

#Convert all users to cloud only users. 

#Create CSV with the following header and rows:

UserPrincipalName
user1@domain.com
user2@domain.com
user3@domain.com

# Import users from CSV file
$users = Import-Csv -Path "C:\path\to\users.csv"

# Loop through each user in the CSV and update ImmutableId
foreach ($user in $users) {
    # Set the ImmutableId to null for each user
    try {
        Set-MsolUser -UserPrincipalName $user.UserPrincipalName -ImmutableId "$null"
        Write-Host "Successfully updated user: $($user.UserPrincipalName)"
    }
    catch {
        Write-Host "Failed to update user: $($user.UserPrincipalName). Error: $($_.Exception.Message)"
    }
}

Disconnect

[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
















