# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Create the GUI Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "PIM Role Activation"
$form.Size = New-Object System.Drawing.Size(400, 350)
$form.StartPosition = "CenterScreen"

# Create Label for Role Selection
$roleLabel = New-Object System.Windows.Forms.Label
$roleLabel.Text = "Select a Role:"
$roleLabel.Location = New-Object System.Drawing.Point(20, 20)
$roleLabel.AutoSize = $true
$form.Controls.Add($roleLabel)

# Create Dropdown for Roles
$roleDropdown = New-Object System.Windows.Forms.ComboBox
$roleDropdown.Location = New-Object System.Drawing.Point(20, 45)
$roleDropdown.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($roleDropdown)

# Create Label for Duration Input
$durationLabel = New-Object System.Windows.Forms.Label
$durationLabel.Text = "Enter Duration (e.g., 1H, 30M, 2H30M):"
$durationLabel.Location = New-Object System.Drawing.Point(20, 80)
$durationLabel.AutoSize = $true
$form.Controls.Add($durationLabel)

# Create TextBox for Duration
$durationInput = New-Object System.Windows.Forms.TextBox
$durationInput.Location = New-Object System.Drawing.Point(20, 105)
$durationInput.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($durationInput)

# Create Label for Justification
$justificationLabel = New-Object System.Windows.Forms.Label
$justificationLabel.Text = "Enter Justification:"
$justificationLabel.Location = New-Object System.Drawing.Point(20, 140)
$justificationLabel.AutoSize = $true
$form.Controls.Add($justificationLabel)

# Create TextBox for Justification
$justificationInput = New-Object System.Windows.Forms.TextBox
$justificationInput.Location = New-Object System.Drawing.Point(20, 165)
$justificationInput.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($justificationInput)

# Create Submit Button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Activate Role"
$submitButton.Location = New-Object System.Drawing.Point(130, 210)
$submitButton.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($submitButton)

# Create Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Connecting to Microsoft Graph..."
$statusLabel.ForeColor = "Blue"
$statusLabel.Location = New-Object System.Drawing.Point(20, 250)
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

# Connect to Microsoft Graph with -NoWelcome
try {
    Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
    $context = Get-MgContext
    $currentUser = (Get-MgUser -UserId $context.Account).Id

    # Fetch available roles
    $myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$currentUser'"
    $validRoles = $myRoles | Where-Object { $_.RoleDefinition -and $_.RoleDefinition.DisplayName }

    # Populate Dropdown with Roles
    foreach ($role in $validRoles) {
        $roleDropdown.Items.Add($role.RoleDefinition.DisplayName)
    }

    # Update status label
    $statusLabel.Text = "Connected! Select a role to activate."
    $statusLabel.ForeColor = "Green"
} catch {
    $statusLabel.Text = "Error: Could not connect to Microsoft Graph."
    $statusLabel.ForeColor = "Red"
    return
}

# Button Click Event - Activate Role
$submitButton.Add_Click({
    try {
        $selectedRoleName = $roleDropdown.SelectedItem
        $duration = $durationInput.Text.Trim()
        $justification = $justificationInput.Text.Trim()

        if (-not $selectedRoleName -or -not $duration -or -not $justification) {
            $statusLabel.Text = "All fields are required!"
            $statusLabel.ForeColor = "Red"
            return
        }

        # Convert duration to ISO 8601 Format
        if ($duration -match '^(\d+)H(\d+M)?$') {
            $duration = "PT$($matches[1])H$($matches[2])"
        } elseif ($duration -match '^(\d+)M$') {
            $duration = "PT$($matches[1])M"
        } elseif ($duration -match '^(\d+)H$') {
            $duration = "PT$($matches[1])H"
        } else {
            $statusLabel.Text = "Invalid duration format! Use '1H', '30M', or '2H30M'."
            $statusLabel.ForeColor = "Red"
            return
        }

        # Convert to human-readable format
        $hours = $null
        $minutes = $null

        if ($duration -match '(\d+)H') {
            $hours = "$($matches[1]) Hour"
            if ([int]$matches[1] -ne 1) { $hours += "s" }
        }

        if ($duration -match '(\d+)M') {
            $minutes = "$($matches[1]) Minute"
            if ([int]$matches[1] -ne 1) { $minutes += "s" }
        }

        $readableDuration = ($hours, $minutes) -ne "" -join " "

        # Get selected role object
        $selectedRole = $validRoles | Where-Object { $_.RoleDefinition.DisplayName -eq $selectedRoleName }
        $directoryScopeId = if ($selectedRole.DirectoryScopeId -eq $null -or $selectedRole.DirectoryScopeId -eq "") { "/" } else { $selectedRole.DirectoryScopeId }

        # Prepare activation request
        $params = @{
            Action = "selfActivate"
            PrincipalId = $selectedRole.PrincipalId
            RoleDefinitionId = $selectedRole.RoleDefinitionId
            DirectoryScopeId = $directoryScopeId
            Justification = $justification
            ScheduleInfo = @{
                StartDateTime = Get-Date
                Expiration = @{
                    Type = "AfterDuration"
                    Duration = $duration
                }
            }
        }

        # Send request and suppress output
        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params | Out-Null

        # Update status label
        $statusLabel.Text = "Role '$selectedRoleName' activated for $readableDuration."
        $statusLabel.ForeColor = "Green"
    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $statusLabel.ForeColor = "Red"
    }
})

# Show the GUI
$form.ShowDialog()