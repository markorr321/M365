﻿# Connect to Exchange Online
Connect-ExchangeOnline

# Set the domain you want to filter by
$targetDomain = "healthcareitleaders.com"

# Retrieve all mailboxes from Exchange Online
$mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox

# Log the number of mailboxes found
Write-Host "==============================================="
Write-Host "Found $($mailboxes.Count) mailboxes to process."
Write-Host "==============================================="

# Loop through each mailbox
foreach ($mailbox in $mailboxes) {
    # Get the email address of the mailbox owner
    $calendarOwner = $mailbox.PrimarySmtpAddress

    # Check if the email belongs to the target domain
    if ($calendarOwner -like "*@$targetDomain") {
        Write-Host "`n-----------------------------------------------"
        Write-Host "Processing mailbox: $calendarOwner"
        Write-Host "-----------------------------------------------"

        try {
            # Attempt to set the calendar permissions for the user
            Set-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar" -User Default -AccessRights Reviewer

            # Optionally, review the permissions to ensure they've been applied correctly
            $currentPermissions = Get-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar"
            Write-Host "Permissions successfully set for $calendarOwner"
            Write-Host "`n"
        } catch {
            # Store the exception message in a variable
            $errorMessage = $_.Exception.Message

            # Output the error message using concatenation
            Write-Host "`nError setting permissions for " + $calendarOwner + ": " + $errorMessage
            Write-Host "`n"
        }
    } else {
        Write-Host "`nSkipping $calendarOwner, domain does not match $targetDomain"
        Write-Host "`n"
    }
}
