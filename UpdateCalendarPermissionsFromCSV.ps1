# Connect to Exchange Online
Connect-ExchangeOnline

# Import the list of users from CSV
$users = Import-Csv -Path "C:\Users\mark.orr\Downloads\calendartest.csv"

# Loop through each user in the CSV and set calendar permissions
foreach ($user in $users) {
    $calendarOwner = $user.EmailAddress
    Write-Host "Setting permissions for: $calendarOwner"

    # Set calendar permissions to allow everyone to view all events
    Set-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar" -User Default -AccessRights Reviewer

    # Optionally, review the permissions to ensure they've been applied correctly
    $currentPermissions = Get-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar"
    Write-Host "Permissions for $($calendarOwner):"
    $currentPermissions | Format-Table -AutoSize
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
