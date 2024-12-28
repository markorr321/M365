# Connect to Exchange Online

Connect-ExchangeOnline 

# Specify the target mailbox (calendar owner)
$calendarOwner = "antonio.westley@healthcareitleaders.com"

# Set calendar permissions to allow everyone to view all events
Set-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar" -User Default -AccessRights Reviewer

# Optionally, review the permissions to ensure they've been applied correctly
Get-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar"

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
