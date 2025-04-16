# Connect to Entra
Connect-Entra

# Path to the CSV file
$csvPath = "C:\Powershell\Updated_Entra_ID_PS_Update_Company_Name\UpdateCompanyName.csv"

# Import the CSV file
$userUpdates = Import-Csv -Path $csvPath

# 1. Create an empty array for logs
$updateLogs = @()

foreach ($user in $userUpdates) {
    try {
        # Fetch user details
        $aadUser = Get-EntraUser -Filter "UserPrincipalName eq '$($user.UserPrincipalName)'"

        if ($aadUser) {
            # Update Title if provided
            if ($user.PSObject.Properties.Name -contains "Title" -and $user.Title) {
                Set-EntraUser -ObjectId $aadUser.ObjectId -JobTitle $user.Title
                Write-Host "Updated Title for $($user.UserPrincipalName) to $($user.Title)"

                # Log record
                $updateLogs += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Field             = 'Title'
                    NewValue          = $user.Title
                    Timestamp         = Get-Date
                    Status            = 'Updated'
                }
            }

            # Update Company Name if provided
            if ($user.PSObject.Properties.Name -contains "CompanyName" -and $user.CompanyName) {
                Set-EntraUser -ObjectId $aadUser.ObjectId -CompanyName $user.CompanyName
                Write-Host "Updated Company Name for $($user.UserPrincipalName) to $($user.CompanyName)"

                # Log record
                $updateLogs += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Field             = 'CompanyName'
                    NewValue          = $user.CompanyName
                    Timestamp         = Get-Date
                    Status            = 'Updated'
                }
            }

            # Update Mobile Number if provided
            if ($user.PSObject.Properties.Name -contains "MobileNumber" -and $user.MobileNumber) {
                Set-EntraUser -ObjectId $aadUser.ObjectId -Mobile $user.MobileNumber
                Write-Host "Updated Mobile Number for $($user.UserPrincipalName) to $($user.MobileNumber)"

                # Log record
                $updateLogs += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Field             = 'MobileNumber'
                    NewValue          = $user.MobileNumber
                    Timestamp         = Get-Date
                    Status            = 'Updated'
                }
            }

            # Update Manager if provided
            if ($user.PSObject.Properties.Name -contains "ManagerUPN" -and $user.ManagerUPN) {
                $manager = Get-EntraUser -Filter "UserPrincipalName eq '$($user.ManagerUPN)'"
                if ($manager) {
                    Set-EntraUserManager -ObjectId $aadUser.ObjectId -RefObjectId $manager.ObjectId
                    Write-Host "Updated Manager for $($user.UserPrincipalName) to $($user.ManagerUPN)"

                    # Log record
                    $updateLogs += [PSCustomObject]@{
                        UserPrincipalName = $user.UserPrincipalName
                        Field             = 'Manager'
                        NewValue          = $user.ManagerUPN
                        Timestamp         = Get-Date
                        Status            = 'Updated'
                    }
                } else {
                    Write-Warning "Manager $($user.ManagerUPN) not found for $($user.UserPrincipalName)."

                    # Log record
                    $updateLogs += [PSCustomObject]@{
                        UserPrincipalName = $user.UserPrincipalName
                        Field             = 'Manager'
                        NewValue          = $user.ManagerUPN
                        Timestamp         = Get-Date
                        Status            = 'ManagerNotFound'
                    }
                }
            }

            # Update Work Number if provided
            if ($user.PSObject.Properties.Name -contains "WorkNumber" -and $user.WorkNumber) {
                Set-EntraUser -ObjectId $aadUser.ObjectId -TelephoneNumber $user.WorkNumber
                Write-Host "Updated Work Number for $($user.UserPrincipalName) to $($user.WorkNumber)"

                # Log record
                $updateLogs += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Field             = 'WorkNumber'
                    NewValue          = $user.WorkNumber
                    Timestamp         = Get-Date
                    Status            = 'Updated'
                }
            }

            # Update Department if provided
            if ($user.PSObject.Properties.Name -contains "Department" -and $user.Department) {
                Set-EntraUser -ObjectId $aadUser.ObjectId -Department $user.Department
                Write-Host "Updated Department for $($user.UserPrincipalName) to $($user.Department)"

                # Log record
                $updateLogs += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    Field             = 'Department'
                    NewValue          = $user.Department
                    Timestamp         = Get-Date
                    Status            = 'Updated'
                }
            }
        } else {
            Write-Warning "User $($user.UserPrincipalName) not found in Entra ID."

            # Log record
            $updateLogs += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                Field             = 'N/A'
                NewValue          = ''
                Timestamp         = Get-Date
                Status            = 'UserNotFound'
            }
        }
    }
    catch {
        Write-Error "An error occurred while updating $($user.UserPrincipalName): $_"

        # Log record
        $updateLogs += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Field             = 'N/A'
            NewValue          = ''
            Timestamp         = Get-Date
            Status            = 'Error'
            ErrorMessage      = $_.Exception.Message
        }
    }
}

# 2. Export the logs to a CSV
$logPath = "C:\Powershell\Updated_Entra_ID_PS_Update_Company_Name\UpdateLog2.csv"
$updateLogs | Export-Csv -Path $logPath -NoTypeInformation

# Disconnect from Entra
Disconnect-Entra

Write-Host "All updates complete. A log has been saved to: $logPath"
