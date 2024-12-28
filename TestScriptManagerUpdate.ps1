# Connect to Azure AD
Connect-AzureAD

# Import CSV file
$users = Import-Csv -Path "C:\Powershell\Corrected_UpdateManagerTest.csv"

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
        # Verify that managerPrincipalName is not empty
        if ([string]::IsNullOrEmpty($managerPrincipalName)) {
            Write-Output "ManagerUserPrincipalName is empty for user $($userPrincipalName)"
            
            # Record failure due to missing managerPrincipalName
            $updatedUsers += [PSCustomObject]@{
                UserPrincipalName = $userPrincipalName
                ManagerUserPrincipalName = $managerPrincipalName
                Status = "Manager Name Missing"
            }
            continue
        }

        # Get the Manager Object ID
        $manager = Get-AzureADUser -ObjectId $managerPrincipalName -ErrorAction SilentlyContinue

        # Check if manager was found
        if ($manager -ne $null) {
            # Update Manager field for the User
            Set-AzureADUserManager -ObjectId $userPrincipalName -RefObjectId $manager.ObjectId

            Write-Output "Successfully updated manager for $($userPrincipalName) to $($managerPrincipalName)"

            # Record successful update
            $updatedUsers += [PSCustomObject]@{
                UserPrincipalName = $userPrincipalName
                ManagerUserPrincipalName = $managerPrincipalName
                Status = "Success"
            }
        }
        else {
            Write-Output "Manager $($managerPrincipalName) not found in Azure AD for user $($userPrincipalName)"
            
            # Record failure due to manager not found
            $updatedUsers += [PSCustomObject]@{
                UserPrincipalName = $userPrincipalName
                ManagerUserPrincipalName = $managerPrincipalName
                Status = "Manager Not Found"
            }
        }
    }
    catch {
        Write-Output "Failed to update manager for $($userPrincipalName): $($_)"

        # Record failure due to other errors
        $updatedUsers += [PSCustomObject]@{
            UserPrincipalName = $userPrincipalName
            ManagerUserPrincipalName = $managerPrincipalName
            Status = "Failed"
        }
    }
}

# Export results to CSV
$updatedUsers | Export-Csv -Path "C:\Powershell\Updated_Manager_Log.csv" -NoTypeInformation -Encoding UTF8

# Disconnect from Azure AD
Disconnect-AzureAD
