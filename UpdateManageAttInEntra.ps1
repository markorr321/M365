# Connect to Azure AD
Connect-AzureAD

# Import CSV file
$users = Import-Csv -Path "C:\Powershell\UpdateManagerTest.csv"

# Create an array to store update results
$updatedUsers = @()

# Initialize a counter for progress indication
$totalUsers = $users.Count
$currentCount = 0

# Loop through each record in the CSV
foreach ($user in $users) {
    $userPrincipalName = $user."UserPrincipalName"
    $managerPrincipalName = $user."ManagerUserPrincipalName"
    $currentCount++

    # Display progress percentage
    $progress = [math]::Round(($currentCount / $totalUsers) * 100, 2)
    Write-Progress -Activity "Updating Managers" -Status "$progress% Complete" -PercentComplete $progress

    try {
        # Get the Manager Object ID
        $manager = Get-AzureADUser -ObjectId $managerPrincipalName

        # Update Manager field for the User
        Set-AzureADUserManager -ObjectId $userPrincipalName -RefObjectId $manager.ObjectId

        Write-Output "Successfully updated manager for $userPrincipalName to $managerPrincipalName"

        # Record successful update
        $updatedUsers += [PSCustomObject]@{
            UserPrincipalName = $userPrincipalName
            ManagerUserPrincipalName = $managerPrincipalName
            Status = "Success"
        }
    }
    catch {
        Write-Output "Failed to update manager for $userPrincipalName: $_"

        # Record failure
        $updatedUsers += [PSCustomObject]@{
            UserPrincipalName = $userPrincipalName
            ManagerUserPrincipalName = $managerPrincipalName
            Status = "Failed"
        }
    }
}

# Export results to CSV
$updatedUsers | Export-Csv -Path "C:\Powershell\Updated_Manager_Log.csv" -NoTypeInformation -Encoding UTF8

