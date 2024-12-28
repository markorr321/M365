# Import Microsoft Graph Module
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "UserAuthenticationMethod.ReadWrite.All"

# Prompt for User UPN or Object ID
$userPrincipalName = Read-Host "Enter the user's UPN (email address)"

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
    Write-Host "Error retrieving user: $_" -ForegroundColor Red
    exit
}

# Retrieve Microsoft Authenticator Methods
Write-Host "Retrieving Microsoft Authenticator methods..." -ForegroundColor Yellow
try {
    $authMethods = Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $user.Id -ErrorAction Stop

    # Check if any methods were retrieved
    if ($authMethods.Count -eq 0) {
        Write-Host "No Microsoft Authenticator methods found for the user." -ForegroundColor Red
        exit
    }

    # Display the methods and extract the first one
    Write-Host "Available Microsoft Authenticator methods:" -ForegroundColor Green
    $authMethods | Format-Table Id
    $microsoftAuthenticatorAuthenticationMethodId = $authMethods[0].Id

    # Verify the retrieved ID
    if ([string]::IsNullOrEmpty($microsoftAuthenticatorAuthenticationMethodId)) {
        Write-Host "No valid Microsoft Authenticator method ID found." -ForegroundColor Red
        exit
    }

    Write-Host "Microsoft Authenticator Method ID: $microsoftAuthenticatorAuthenticationMethodId" -ForegroundColor Green
} catch {
    Write-Host "Error retrieving authentication methods: $_" -ForegroundColor Red
    exit
}

# Remove Microsoft Authenticator Method
Write-Host "Removing Microsoft Authenticator method..." -ForegroundColor Yellow
try {
    Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $user.Id -MicrosoftAuthenticatorAuthenticationMethodId $microsoftAuthenticatorAuthenticationMethodId -ErrorAction Stop
    Write-Host "Microsoft Authenticator method removed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error removing Microsoft Authenticator method: $_" -ForegroundColor Red
}
