# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName "<your-admin-account>@<domain>.com"

# Specify the resource mailbox to convert
$Mailbox = "resource-mailbox@domain.com"

# Convert the mailbox to a shared mailbox
Set-Mailbox -Identity $Mailbox -Type Shared

# Confirm the change
$MailboxDetails = Get-Mailbox -Identity $Mailbox
Write-Output "Mailbox Type for $($MailboxDetails.PrimarySmtpAddress): $($MailboxDetails.RecipientTypeDetails)"

# Disconnect from Exchange Online
Disconnect-ExchangeOnline
