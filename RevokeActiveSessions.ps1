# Import Microsoft Graph Module
Import-Module Microsoft.Graph -ErrorAction Stop
Import-Module Microsoft.Graph.Users.Actions -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.AccessAsUser.All"

# Prompt for the User's UPN
$userPrincipalName = Read-Host "Enter the user's UPN (email address)"

# Revoke all active sessions
Write-Host "Revoking all active sessions for the user..." -ForegroundColor Yellow
try {
    Revoke-MgUserSignInSession -UserId $userPrincipalName -ErrorAction Stop
    Write-Host "All active sessions have been revoked successfully for $userPrincipalName." -ForegroundColor Green
} catch {
    Write-Host "Error revoking active sessions: $_" -ForegroundColor Red
}


