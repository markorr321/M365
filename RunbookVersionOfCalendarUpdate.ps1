Connect-ExchangeOnline -ManagedIdentity -Organization w3-llc.com -ManagedIdentityAccountId 7a519ddd-8ad1-490c-8a36-de7d97ee1bb6

# Set the domain you want to filter by
$targetDomain = "pacleaders.com"

# Retrieve all mailboxes from Exchange Online
$mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox

# Loop through each mailbox
foreach ($mailbox in $mailboxes) {
    # Get the email address of the mailbox owner and store it in a separate variable
    $calendarOwner = $mailbox.PrimarySmtpAddress.ToString()

    # Check if the email belongs to the target domain
    if ($calendarOwner -like "*@$targetDomain") {
        Write-Output "Setting permissions for: $calendarOwner"

        try {
            # Attempt to set the calendar permissions for the user
            $calendarIdentity = $calendarOwner + ":\Calendar"
            Set-MailboxFolderPermission -Identity $calendarIdentity -User Default -AccessRights Reviewer

            # Optionally, review the permissions to ensure they've been applied correctly
            $currentPermissions = Get-MailboxFolderPermission -Identity $calendarIdentity
            Write-Output "Permissions successfully set for $calendarOwner"
        } catch {
            # Capture the error message without interpolation
            $errorMessage = "Error setting permissions for " + $calendarOwner + ": " + $_.Exception.Message
            Write-Output $errorMessage
        }
    } else {
        Write-Output "Skipping $calendarOwner, domain does not match $targetDomain"
    }
}
