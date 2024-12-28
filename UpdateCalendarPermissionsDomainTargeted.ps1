# Connect to Exchange Online
Connect-ExchangeOnline

# Set the domain you want to filter by
$targetDomain = "pacleaders.com"

# Retrieve all mailboxes from Exchange Online
$mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox

# Loop through each mailbox
foreach ($mailbox in $mailboxes) {
    # Get the email address of the mailbox owner
    $calendarOwner = $mailbox.PrimarySmtpAddress

    # Check if the email belongs to the target domain
    if ($calendarOwner -like "*@$targetDomain") {
        Write-Host "Setting permissions for: $calendarOwner"

        try {
            # Attempt to set the calendar permissions for the user
            Set-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar" -User Default -AccessRights Reviewer

            # Optionally, review the permissions to ensure they've been applied correctly
            $currentPermissions = Get-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar"
            Write-Host "Permissions successfully set for $calendarOwner"
        } catch {
            Write-Host "Error setting permissions for $calendarOwner: $_"
        }
    } else {
        Write-Host "Skipping $calendarOwner, domain does not match $targetDomain"
    }
}



