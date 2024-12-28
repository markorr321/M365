Connect-MgGraph -Scopes "User.Invite.All"


# Import the CSV file
$csvPath = "C:\Powershell\ExternalUsers.csv"
$users = Import-Csv -Path $csvPath

# Define the redirect URL (change to a valid URL for your organization)
$redirectUrl = "https://myorganization.com/welcome"

# Loop through each user and send an invitation
foreach ($user in $users) {
    $invitation = New-MgInvitation -InvitedUserEmailAddress $user.Email `
        -InvitedUserDisplayName "$($user.FirstName) $($user.LastName)" `
        -SendInvitationMessage:$true `
        -InviteRedirectUrl $redirectUrl `
        -InvitedUserMessageInfo @{CustomizedMessageBody = "You are invited to join our organization. Please accept the invitation to get started."}

    Write-Host "Invitation sent to $($user.Email) with status $($invitation.Status)"
}
