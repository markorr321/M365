# Import Microsoft Graph Module
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.ReadWrite.All"

# Prompt for User UPN or Object ID
$userPrincipalName = Read-Host "Enter the user's UPN or Object ID"

# Retrieve the User Object
Write-Host "Retrieving user details..." -ForegroundColor Yellow
try {
    $user = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'" -ErrorAction Stop
    if ($null -eq $user) {
        Write-Host "User not found. Ensure the UPN is correct." -ForegroundColor Red
        exit
    }
    Write-Host "User found: $($user.DisplayName) - $($user.Id)" -ForegroundColor Green
} catch {
    Write-Host "Error: User not found or invalid permissions. $_" -ForegroundColor Red
    exit
}

# Retrieve All Authentication Methods for the User
Write-Host "Retrieving authentication methods..." -ForegroundColor Yellow
try {
    $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction Stop
    if ($authMethods.Count -eq 0) {
        Write-Host "No authentication methods found for the user." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "Error: Unable to retrieve authentication methods. $_" -ForegroundColor Red
    exit
}

# Loop Through and Remove All Methods
Write-Host "Removing all authentication methods..." -ForegroundColor Yellow
foreach ($method in $authMethods) {
    try {
        # Identify the type of method based on @odata.type
        $methodType = $method.AdditionalProperties["@odata.type"]

        # Remove Microsoft Authenticator
        if ($methodType -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod") {
            Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $user.Id -MicrosoftAuthenticatorAuthenticationMethodId $method.Id
            Write-Host "Removed Microsoft Authenticator method: $($method.Id)" -ForegroundColor Green
        }
        # Remove Phone Authentication Method
        elseif ($methodType -eq "#microsoft.graph.phoneAuthenticationMethod") {
            Remove-MgUserAuthenticationPhoneMethod -UserId $user.Id -PhoneAuthenticationMethodId $method.Id
            Write-Host "Removed Phone authentication method: $($method.Id)" -ForegroundColor Green
        }
        # Remove Software OATH Tokens
        elseif ($methodType -eq "#microsoft.graph.softwareOathAuthenticationMethod") {
            Remove-MgUserAuthenticationSoftwareOathMethod -UserId $user.Id -SoftwareOathAuthenticationMethodId $method.Id
            Write-Host "Removed Software OATH token: $($method.Id)" -ForegroundColor Green
        }
        # Remove FIDO2 Security Keys
        elseif ($methodType -eq "#microsoft.graph.fido2AuthenticationMethod") {
            Remove-MgUserAuthenticationFido2Method -UserId $user.Id -Fido2AuthenticationMethodId $method.Id
            Write-Host "Removed FIDO2 authentication method: $($method.Id)" -ForegroundColor Green
        }
        # Remove Temporary Access Pass
        elseif ($methodType -eq "#microsoft.graph.temporaryAccessPassAuthenticationMethod") {
            Remove-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.Id -TemporaryAccessPassAuthenticationMethodId $method.Id
            Write-Host "Removed Temporary Access Pass authentication method: $($method.Id)" -ForegroundColor Green
        }
        # Skip Password Authentication Method (cannot be removed)
        elseif ($methodType -eq "#microsoft.graph.passwordAuthenticationMethod") {
            Write-Host "Password method cannot be removed." -ForegroundColor Yellow
        }
        # Handle Unknown or Unsupported Methods
        else {
            Write-Host "Unsupported or unknown method type: $methodType" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Error removing method ($($method.Id)): $_" -ForegroundColor Red
    }
}

Write-Host "Completed processing all authentication methods for the user." -ForegroundColor Green
