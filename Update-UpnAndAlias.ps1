#Step 1: Connect to Microsoft Graph

Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.AccessAsUser.All"

#Step 2: Change the UserPrincipalName (UPN)

Update-MgUser -UserId "bgammie@cre-usa.com" -UserPrincipalName "bgammie@avantiresidential.com"

#Step 3: Add the Old Email as a Proxy Address (Alias)

# Get updated user
$user = Get-MgUser -UserId "bgammie@avantiresidential.com"

# Append the old email as a lowercase alias (secondary SMTP)
$updatedProxies = $user.ProxyAddresses + "smtp:bgammie@cre-usa.com"

# Update the proxyAddresses list
Update-MgUser -UserId "bgammie@avantiresidential.com" -ProxyAddresses $updatedProxies


## Check proxy addresses
(Get-MgUser -UserId "bgammie@avantiresidential.com").ProxyAddresses

## You should see something like:

## SMTP:bgammie@avantiresidential.com
## smtp:bgammie@cre-usa.com


