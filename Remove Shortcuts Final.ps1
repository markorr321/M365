# Get the Desktop paths for the user and public 
$UserDesktopPath = [Environment]::GetFolderPath("Desktop")
$PublicDesktopPath = Join-Path -Path $env:Public -ChildPath "Desktop"

# Define an array of shortcut filenames to delete
$ShortcutsToDelete = @("Acrobat Reader.lnk", "Google Chrome.lnk", "Microsoft Edge.lnk")

# Function to delete shortcuts from a specified path
function Delete-Shortcuts {
    param (
        [string]$DesktopPath,
        [string]$LogFile
    )
    
    foreach ($Shortcut in $ShortcutsToDelete) {
        $ShortcutFile = Join-Path -Path $DesktopPath -ChildPath $Shortcut

        # Check if the shortcut exists
        if (Test-Path -Path $ShortcutFile) {
            # Remove shortcut
            Remove-Item -Path $ShortcutFile -ErrorAction SilentlyContinue

            # Log and confirm removal to the user
            if (-not (Test-Path -Path $ShortcutFile)) {
                $Message = "Shortcut '$Shortcut' successfully deleted from '$DesktopPath'."
                Write-Output $Message
                Add-Content -Path $LogFile -Value $Message
            } else {
                $Message = "Failed to delete the shortcut '$Shortcut' from '$DesktopPath'."
                Write-Output $Message
                Add-Content -Path $LogFile -Value $Message
            }
        } else {
            $Message = "Shortcut '$Shortcut' not found in '$DesktopPath'."
            Write-Output $Message
            Add-Content -Path $LogFile -Value $Message
        }
    }
}

# Create "Remove Shortcuts" folder and log file at the root of C:
$FolderPath = "C:\Remove Shortcuts"
$LogFilePath = Join-Path -Path $FolderPath -ChildPath "ShortcutsRemoved.text"

if (-not (Test-Path -Path $FolderPath)) {
    New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $LogFilePath)) {
    New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
}

# Delete shortcuts from user's Desktop and log results
Delete-Shortcuts -DesktopPath $UserDesktopPath -LogFile $LogFilePath

# Delete shortcuts from Public Desktop and log results
Delete-Shortcuts -DesktopPath $PublicDesktopPath -LogFile $LogFilePath

Write-Output "Shortcut removal process completed. Logs can be found in '$LogFilePath'."
