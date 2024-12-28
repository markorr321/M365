Connect-ExchangeOnline

# Specify the resource mailbox to configure
$Mailbox = "oracle@healthcareitleaders.com"

# Configure the resource mailbox to allow double booking
Set-CalendarProcessing -Identity $Mailbox -AllowConflicts $true

# Confirm the change
$CalendarSettings = Get-CalendarProcessing -Identity $Mailbox

# Display the AllowConflicts property explicitly
if ($CalendarSettings -ne $null) {
    Write-Output "AllowConflicts setting for mailbox ${Mailbox}: $($CalendarSettings.AllowConflicts)"
} else {
    Write-Output "Could not retrieve settings for mailbox ${Mailbox}. Please check the mailbox identity."
}


