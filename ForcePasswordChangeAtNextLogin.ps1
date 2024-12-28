# Import Microsoft Graph Module
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Define the password profile
$PasswordProfile = @{
    ForceChangePasswordNextSignIn = $true
}

# Update the user's password profile
try {
    Update-MgUser -UserId "bob.ross@healthcareitleaders.com" -PasswordProfile $PasswordProfile
    Write-Host "Password change at next login enforced successfully." -ForegroundColor Green
} catch {
    Write-Host "Error forcing password change: $_" -ForegroundColor Red
}


