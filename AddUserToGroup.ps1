# Install the Microsoft Graph module if not installed
#Install-Module Microsoft.Graph -Scope CurrentUser

# Import the module
#Import-Module Microsoft.Graph

#ConnectMgGraph
Connect-MgGraph

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework

# Create a new window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Add User to Group" Height="200" Width="400">
    <Grid>
        <Label Content="User UPN:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,10,0,0"/>
        <TextBox Name="UserUPN" HorizontalAlignment="Left" VerticalAlignment="Top" Width="300" Margin="100,10,0,0"/>
        
        <Label Content="Group Name:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,50,0,0"/>
        <TextBox Name="GroupName" HorizontalAlignment="Left" VerticalAlignment="Top" Width="300" Margin="100,50,0,0"/>
        
        <Button Content="Submit" Name="SubmitButton" HorizontalAlignment="Left" VerticalAlignment="Top" Width="80" Margin="100,100,0,0"/>
        <Button Content="Cancel" Name="CancelButton" HorizontalAlignment="Left" VerticalAlignment="Top" Width="80" Margin="200,100,0,0"/>
    </Grid>
</Window>
"@

# Load the XAML into a new WPF window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Get the UI elements from the XAML
$UserUPN = $Window.FindName("UserUPN")
$GroupName = $Window.FindName("GroupName")
$SubmitButton = $Window.FindName("SubmitButton")
$CancelButton = $Window.FindName("CancelButton")

# Define actions for buttons
$SubmitButton.Add_Click({
    # Retrieve input values
    $userUPNValue = $UserUPN.Text
    $groupNameValue = $GroupName.Text
    
    # Close the window
    $Window.Close()

    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

    # Retrieve the user and group IDs
    $userId = (Get-MgUser -UserId $userUPNValue).Id
    $groupId = (Get-MgGroup -Filter "displayName eq '$groupNameValue'").Id

    # Add the user to the group using New-MgGroupMember
    New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId

    # Verify the user has been added to the group
    $members = Get-MgGroupMember -GroupId $groupId
    $members | Where-Object { $_.Id -eq $userId }

    # Output success message
    Write-Host "User $userUPNValue has been successfully added to the group $groupNameValue."
})

$CancelButton.Add_Click({
    # Close the window without doing anything
    $Window.Close()
})

# Show the window as a dialog
$Window.ShowDialog() | Out-Null
