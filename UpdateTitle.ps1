# Import Azure AD module (if not already imported)
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Function to update user's title and mobile phone number in Azure AD
function Update-UserInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,   # The UPN (email address) of the user to update

        [Parameter(Mandatory=$false)]
        [string]$Title,               # New job title

        [Parameter(Mandatory=$false)]
        [string]$MobilePhone          # New mobile phone number
    )

    # Get the user object by UPN
    try {
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
        
        if ($user) {
            # Create an object for the updated attributes
            $userUpdateParams = @{}

            if ($Title) {
                $userUpdateParams['JobTitle'] = $Title
            }

            if ($MobilePhone) {
                $userUpdateParams['Mobile'] = $MobilePhone
            }

            # Update the user in Azure AD
            if ($userUpdateParams.Count -gt 0) {
                Set-AzureADUser -ObjectId $user.ObjectId -JobTitle $Title -Mobile $MobilePhone
                Write-Host "Successfully updated the user $UserPrincipalName."
            }
            else {
                Write-Host "No updates were made for $UserPrincipalName."
            }
        }
        else {
            Write-Host "User $UserPrincipalName not found."
        }
    }
    catch {
        Write-Host "Failed to update user $UserPrincipalName: $($_.Exception.Message)"
    }
}

# Path to the CSV file
$csvPath = "C:\Users\mark.orr\Downloads\titleupdate.csv"

# Import the CSV
$users = Import-Csv -Path $csvPath

# Loop through each user in the CSV and update their info
foreach ($user in $users) {
    $UserPrincipalName = $user.UserPrincipalName
    $NewTitle = $user.Title
    $NewMobilePhone = $user.MobilePhone

    # Call the function to update each user
    Update-UserInfo -UserPrincipalName $UserPrincipalName -Title $NewTitle -MobilePhone $NewMobilePhone
}

