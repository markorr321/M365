# Import required modules 
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.AccessAsUser.All"

# Prompt for domain
$domainName = Read-Host "healthcareitleaders.com"

# --- Step 1: Get All Users in the Domain ---
Write-Host "Retrieving all users in the domain $domainName..." -ForegroundColor Yellow
try {
    # Get all users with the specified domain
    $users = Get-MgUser -Filter "endsWith(userPrincipalName, '@$domainName')" -All
    if ($users.Count -eq 0) {
        Write-Host "No users found in the domain $domainName." -ForegroundColor Red
        return
    }
    Write-Host "Retrieved $($users.Count) users from the domain." -ForegroundColor Green
} catch {
    Write-Host "Error retrieving users: $_" -ForegroundColor Red
    return
}

# Loop through each user
foreach ($user in $users) {
    $userPrincipalName = $user.UserPrincipalName
    Write-Host "Processing user: $userPrincipalName" -ForegroundColor Cyan

    # --- Step 2: Force Password Change at Next Login ---
    Write-Host "Forcing password reset for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        # Define the password profile
        $PasswordProfile = @{
            ForceChangePasswordNextSignIn = $true
        }
        # Update the user's password profile
        Update-MgUser -UserId $userPrincipalName -PasswordProfile $PasswordProfile
        Write-Host "Password change at next login enforced successfully for $userPrincipalName." -ForegroundColor Green
    } catch {
        Write-Host "Error forcing password change for $userPrincipalName: $_" -ForegroundColor Red
    }

    # --- Step 3: Revoke MFA Sessions ---
    Write-Host "Revoking MFA sessions for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        # Retrieve all authentication methods for the user
        $authMethods = Get-MgUserAuthenticationMethod -UserId $userPrincipalName

        # Loop through each method and revoke applicable ones
        foreach ($method in $authMethods) {
            if ($method.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod") {
                Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $userPrincipalName -MicrosoftAuthenticatorAuthenticationMethodId $method.Id
                Write-Host "Revoked Microsoft Authenticator method: $($method.Id)" -ForegroundColor Green
            } elseif ($method.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.phoneAuthenticationMethod") {
                Remove-MgUserAuthenticationPhoneMethod -UserId $userPrincipalName -PhoneAuthenticationMethodId $method.Id
                Write-Host "Revoked Phone authentication method: $($method.Id)" -ForegroundColor Green
            } elseif ($method.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.softwareOathAuthenticationMethod") {
                Remove-MgUserAuthenticationSoftwareOathMethod -UserId $userPrincipalName -SoftwareOathAuthenticationMethodId $method.Id
                Write-Host "Revoked Software OATH token: $($method.Id)" -ForegroundColor Green
            }
        }
        Write-Host "MFA sessions revoked successfully for $userPrincipalName." -ForegroundColor Green
    } catch {
        Write-Host "Error revoking MFA sessions for $userPrincipalName: $_" -ForegroundColor Red
    }

    # --- Step 4: Revoke Active Sessions ---
    Write-Host "Revoking all active sessions for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        Revoke-MgUserSignInSession -UserId $userPrincipalName
        Write-Host "All active sessions have been revoked successfully for $userPrincipalName." -ForegroundColor Green
    } catch {
        Write-Host "Error revoking active sessions for $userPrincipalName: $_" -ForegroundColor Red
    }
}

Write-Host "All actions completed for all users in the domain $domainName." -ForegroundColor Cyan
