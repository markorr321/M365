# Connect to Exchange Online
Connect-ExchangeOnline

# Import the list of users from CSV
$csvPath = "C:\Users\mark.orr\Downloads\calendartest.csv"
$users = Import-Csv -Path $csvPath

# If there is only one row, ensure it is treated as an array
if ($users -isnot [System.Array]) {
    $users = @($users)
}

# Output all column names from the CSV to verify the structure
Write-Host "CSV Column Names: $($users[0].PSObject.Properties.Name -join ', ')"

# Loop through each user in the CSV and log the data
foreach ($user in $users) {
    # Output the current row to inspect the structure
    Write-Host "Processing CSV Row: $($user | Out-String)"

    # Explicitly cast the EmailAddress field to a string and check for null/empty values
    $calendarOwner = [string]$user.EmailAddress

    if ([string]::IsNullOrWhiteSpace($calendarOwner)) {
        Write-Host "Error: No valid EmailAddress found for this entry! Row data: $($user | Out-String)"
        continue
    }

    # Trim any extra spaces from the email address
    $calendarOwner = $calendarOwner.Trim()

    Write-Host "Setting permissions for: $calendarOwner"

    try {
        # Attempt to set the calendar permissions for the user
        Set-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar" -User Default -AccessRights Reviewer

        # Optionally, review the permissions to ensure they've been applied correctly
        $currentPermissions = Get-MailboxFolderPermission -Identity "$($calendarOwner):\Calendar"
        Write-Host "Permissions for $($calendarOwner):"
        $currentPermissions | Format-Table -AutoSize
    } catch {
        Write-Host "Error applying permissions for $($calendarOwner): $($_)"
    }
}

