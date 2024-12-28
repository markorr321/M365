# Import required modules 
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.AccessAsUser.All"


# Prompt for domain
$domainName = Read-Host "Enter the domain (e.g., example.com)"

# Log file path
$logFile = "C:\Logs\UserActions_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"
Write-Host "Logging results to $logFile" -ForegroundColor Cyan
Start-Transcript -Path $logFile -Append

# --- Step 1: Get All Users and Filter Locally ---
Write-Host "Retrieving all users..." -ForegroundColor Yellow
try {
    $allUsers = Get-MgUser -All
    $users = $allUsers | Where-Object { $_.UserPrincipalName -like "*@$domainName" }
    if ($users.Count -eq 0) {
        Write-Host "No users found in the domain $domainName." -ForegroundColor Red
        Stop-Transcript
        return
    }
    Write-Host "Retrieved $($users.Count) users from the domain." -ForegroundColor Green
} catch {
    Write-Host ("Error retrieving users: {0}" -f $Error[0].Exception.Message) -ForegroundColor Red
    Stop-Transcript
    return
}

# --- Step 2: Process Each User ---
foreach ($user in $users) {
    $userPrincipalName = $user.UserPrincipalName
    Write-Host "Processing user: $userPrincipalName" -ForegroundColor Cyan

    # Force Password Reset
    Write-Host "Forcing password reset for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        $PasswordProfile = @{
            ForceChangePasswordNextSignIn = $true
            ForceChangePasswordNextSignInWithMfa = $false # Optional, set as needed
        }
        # Apply the password profile update
        Update-MgUser -UserId $userPrincipalName -PasswordProfile $PasswordProfile

        # Verify if the password reset is enforced
        $userDetails = Get-MgUser -UserId $userPrincipalName -Property PasswordPolicies
        if ($userDetails.PasswordPolicies -match "DisablePasswordExpiration") {
            Write-Host "Password change enforced successfully for $userPrincipalName." -ForegroundColor Green
        } else {
            Write-Host "Password change not enforced; policies might override the request." -ForegroundColor Red
        }
    } catch {
        Write-Host ("Error enforcing password reset for {0}: {1}" -f $userPrincipalName, $Error[0].Exception.Message) -ForegroundColor Red
    }

    # Revoke MFA Authentication Methods
    Write-Host "Revoking MFA sessions for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        $authMethods = Get-MgUserAuthenticationMethod -UserId $userPrincipalName
        foreach ($method in $authMethods) {
            $methodType = $method.AdditionalProperties["@odata.type"]
            if ($methodType -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod") {
                Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $userPrincipalName -MicrosoftAuthenticatorAuthenticationMethodId $method.Id
                Write-Host "Removed Microsoft Authenticator for $userPrincipalName." -ForegroundColor Green
            } elseif ($methodType -eq "#microsoft.graph.softwareOathAuthenticationMethod") {
                Remove-MgUserAuthenticationSoftwareOathMethod -UserId $userPrincipalName -SoftwareOathAuthenticationMethodId $method.Id
                Write-Host "Removed Software OATH Token for $userPrincipalName." -ForegroundColor Green
            } elseif ($methodType -eq "#microsoft.graph.phoneAuthenticationMethod") {
                Remove-MgUserAuthenticationPhoneMethod -UserId $userPrincipalName -PhoneAuthenticationMethodId $method.Id
                Write-Host "Removed Phone Authentication for $userPrincipalName." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host ("Error revoking MFA methods for {0}: {1}" -f $userPrincipalName, $Error[0].Exception.Message) -ForegroundColor Red
    }

    # Revoke Sign-In Sessions
    Write-Host "Revoking all active sessions for the user $userPrincipalName..." -ForegroundColor Yellow
    try {
        Revoke-MgUserSignInSession -UserId $userPrincipalName
        Write-Host "Revoked all active sessions for $userPrincipalName." -ForegroundColor Green
    } catch {
        Write-Host ("Error revoking sessions for {0}: {1}" -f $userPrincipalName, $Error[0].Exception.Message) -ForegroundColor Red
    }
}

Write-Host "All actions completed for all users in the domain $domainName." -ForegroundColor Cyan
Stop-Transcript

